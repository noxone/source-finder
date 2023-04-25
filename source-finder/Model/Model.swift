//
//  Model.swift
//  source-finder
//
//  Created by Olaf Neumann on 25.04.23.
//

import Foundation
import SourceMapper

class Model: ObservableObject {
    @Published var mapDatas: [MapData] = []
    @Published var loadingMapData = false
    @Published var selectedMapData: MapData? = nil
    
    @MainActor
    func loadMapData(urls: [URL]) async {
        loadingMapData = true
        selectedMapData = nil
        do {
            mapDatas = try await MapLoader.shared.loadContent(urls: urls)
        } catch {
            print("---------------")
            print(error)
            mapDatas = []
        }
        if !mapDatas.isEmpty {
            selectedMapData = mapDatas[0]
        }
        loadingMapData = false
    }
}

struct MapData : Hashable, Equatable, Identifiable {
    static func == (lhs: MapData, rhs: MapData) -> Bool {
        lhs.url.absoluteString == rhs.url.absoluteString
    }
    
    let url: URL
    let shortName: String
    let map: SourceMap
    
    var id: String {
        url.absoluteString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
