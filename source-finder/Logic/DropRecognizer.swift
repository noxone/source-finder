//
//  MultiProgressHandler.swift
//  source-finder
//
//  Created by Olaf Neumann on 21.04.23.
//

import Foundation
import CollectionConcurrencyKit

class DropRecognizer {
    static let shared = DropRecognizer()
    
    private init() {}

    func work(with providers: [NSItemProvider]) async -> [URL] {
        return await providers
            .concurrentMap { await $0.loadObject(ofClass: URL.self) }
            .compactMap { $0 }
    }
    
    func work(with providers: [NSItemProvider], action: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        var urls = [URL]()
        providers.forEach { provider in
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    urls.append(url)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            action(urls)
        }
    }
}

fileprivate extension NSItemProvider {
    func loadObject<T>(ofClass clazz: T.Type) async -> T?
        where T: _ObjectiveCBridgeable, T._ObjectiveCType : NSItemProviderReading {
        return await withCheckedContinuation { continuation in
            _ = loadObject(ofClass: clazz) { object, error in
                continuation.resume(returning: object)
            }
        }
    }
}
