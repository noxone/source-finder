//
//  MapLoader.swift
//  source-finder
//
//  Created by Olaf Neumann on 20.04.23.
//

import Foundation
import OSLog
import System
import CollectionConcurrencyKit
import SwiftSoup
import SourceMapper

extension URL {
    var isDirectory: Bool { (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false }
}

extension Logger {
    init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }
}

class MapLoader {
    private let logger = Logger(category: "MapLoader")
    static let shared = MapLoader()
    
    private init() {}
    
    private func httpHead(url: URL) async throws -> URLInfo {
        logger.trace(" HTTP action -> HEAD: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await URLSession.shared.data(for: request)
        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
            logger.trace("  head response status code: \(statusCode)")
        }
        return URLInfo(url: url, httpResponseCode: (response as? HTTPURLResponse)?.statusCode, mimeType: response.mimeType)
    }
    
    private func httpGet(url: URL) async throws -> URLContent {
        logger.trace(" HTTP action -> GET: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
            logger.trace("  get response status code: \(statusCode)")
        }
        return URLContent(url: url, data: data, response: response)
    }
    
    func loadContent(urls: [URL]) async throws -> [MapData] {
        return try await urls.concurrentFlatMap { try await self.loadContent(url: $0) }
    }

    func loadContent(url: URL) async throws -> [MapData] {
        logger.info("URL: \(url.absoluteString)")
        if url.isFileURL && url.isDirectory {
            logger.info("  URL denotes directory. Exiting with loading.")
            return []
        }
        
        let info = try await httpHead(url: url)
        guard info.isSuccess else {
            logger.info("  resource not available")
            return []
        }
        logger.info("  mime type: \(info.mimeType ?? "-none-")")
        
        switch info.mimeType {
        case nil, "text/plain", "application/json":
            let content = try await httpGet(url: info.url)
            if let mapData = loadMapData(from: content) {
                logger.info("  Loaded SourceMap!")
                return [mapData]
            } else {
                logger.info("  Cannot load source map from: \(info.url.absoluteString) of type \(String(describing: info.mimeType))")
                return []
            }
        case "text/html":
            let content = try await httpGet(url: info.url)
            return try await parseTextHtml(from: content)
        case "text/xml":
            let content = try await httpGet(url: info.url)
            let decoder = PropertyListDecoder()
            if let webloc = try? decoder.decode(Webloc.self, from: content.data), let url = URL(string: webloc.URL) {
                return try await loadContent(url: url)
            } else {
                logger.error("XML is no Plist.")
                return []
            }
        case "application/javascript":
            // if JS, then look for map file...
            return try await loadContent(url: info.url.appendingPathExtension("map"))
        default:
            logger.error("Cannot load resource of type \(String(describing: info.mimeType)) from \(info.url.absoluteString).")
            return []
        }
    }
    
    private func loadMapData(from content: URLContent) -> MapData? {
        guard let map = try? SourceMap(data: content.data) else {
            return nil
        }
        
        return MapData(url: content.url, shortName: content.url.filename, map: map)
    }
    
    private func parseTextHtml(from content: URLContent) async throws -> [MapData] {
        guard let html = String(data: content.data, encoding: content.response.encoding) else {
            throw MapLoaderError.stringDecodingFailed
        }
        let document  = try SwiftSoup.parse(html, content.url.absoluteString)
        
        let scriptElements = try document.select("script[src]")
        let urls = try scriptElements.map { try $0.absUrl("src") }
            .compactMap { URL(string: $0) }
        
        return try await loadContent(urls: urls)
    }
}

fileprivate struct URLInfo {
    let url: URL
    let httpResponseCode: Int?
    let mimeType: String?
    
    var isSuccess: Bool {
        get { httpResponseCode == nil || (httpResponseCode! >= 200 && httpResponseCode! < 300) }
    }
}

fileprivate struct URLContent {
    let url: URL
    let data: Data
    let response: URLResponse
    
    var mimeType: String? {
        get { response.mimeType?.lowercased() }
    }
    
    var httpResponseCode: Int? {
        get { (response as? HTTPURLResponse)?.statusCode }
    }
}

struct Webloc: Decodable {
    private enum CodingKeys: String, CodingKey {
        case URL
    }

    let URL: String
}

enum MapLoaderError : Error {
    case stringDecodingFailed
    // old
    /*case urlConstructionFailed
    case invalidUrl(url: URL)
    case parsingException(exception: Exception)
    case invalidDocumentStructure
    case unexpectedException(error: Error)
    case implementationMissing
    case cancelled*/
}

fileprivate extension URLResponse {
    var encoding: String.Encoding {
        var usedEncoding = String.Encoding.utf8 // Some fallback value
        if let encodingName = self.textEncodingName {
            let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingName as CFString))
            if encoding != UInt(kCFStringEncodingInvalidId) {
                usedEncoding = String.Encoding(rawValue: encoding)
            }
        }
        return usedEncoding
    }
}

fileprivate extension URL {
    var filename: String {
        get {
            standardizedFileURL.lastPathComponent
        }
    }
}
