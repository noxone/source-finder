//
//  SourceFinderView.swift
//  source-finder
//
//  Created by Olaf Neumann on 17.04.23.
//

import SwiftUI

struct SourceFinderView: View {
    @StateObject var model: Model = Model()
    
    @State private var visibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility, sidebar: {
            MapSelectionView()
                .frame(minWidth: 300)
        }, detail: {
            if let mapData = model.selectedMapData {
                UserActionView(mapData: mapData)
                    .navigationTitle(mapData.shortName)
            } else {
                Text("No source map loaded or selected.")
            }
        })
        .environmentObject(model)
        .onAppear {
            if model.mapDatas.isEmpty {
                visibility = .all
            } else {
                visibility = .detailOnly
            }
        }
    }
}

struct SourceFinderView_Previews: PreviewProvider {
    static var previews: some View {
        SourceFinderView()
    }
}
