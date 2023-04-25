//
//  UrlSelectionView.swift
//  source-finder
//
//  Created by Olaf Neumann on 20.04.23.
//

import SwiftUI
import CollectionConcurrencyKit
import SourceMapper

struct MapSelectionView: View {
    @EnvironmentObject var model: Model

    var body: some View {
        VStack {
            VStack {
                if model.loadingMapData {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .padding()
                    Spacer()
                } else {
                    if model.mapDatas.isEmpty {
                        Text("No SourceMaps loaded...")
                            .italic()
                            .padding()
                        Spacer()
                    } else {
                        List(selection: $model.selectedMapData) {
                            ForEach(model.mapDatas) { mapData in
                                NavigationLink(value: mapData) {
                                    Text(mapData.shortName)
                                        .help(mapData.url.absoluteString)
                                }
                            }
                        }
                        .disabled(model.mapDatas.isEmpty)
                        .listStyle(.sidebar)
                    }
                }
            }

            ItemDropper(onDropAction: onDropUrls(urls:))
            .frame(minHeight: 200)
            .padding()
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: onShowOpenFilePanel, label: {
                        Image(systemName: "folder")
                    })
                    .help("Read source map")
                }
            }
        }
    }
    
    private func onDropUrls(urls: [URL]) {
        Task {
            await model.loadMapData(urls: urls)
        }
    }
    
    private func onShowOpenFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            if !panel.urls.isEmpty {
                Task {
                    await model.loadMapData(urls: panel.urls)
                }
            }
        }
    }
}

struct MapSelectionView_Previews: PreviewProvider {
    static let filledModel = {
        let model = Model()
        model.mapDatas.append(MapData(url: URL(string: "file:///")!, shortName: "Bernd", map: SourceMap()))
        model.selectedMapData = model.mapDatas[0]
        return model
    }()
    
    static var previews: some View {
        HStack {
            MapSelectionView()
                //.frame(width: 394)
                .frame(width: 200)
                .environmentObject(Model())
            MapSelectionView()
                //.frame(width: 394)
                .frame(width: 200)
                .environmentObject(filledModel)
        }
    }
}
