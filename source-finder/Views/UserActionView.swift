//
//  UserActionView.swift
//  source-finder
//
//  Created by Olaf Neumann on 20.04.23.
//

import SwiftUI
import SourceMapper

struct UserActionView: View {
    @State var mapData: MapData
    
    @State private var lineNumberString = "0"
    @State private var columnNumberString = "0"
    @State private var variableName = ""

    var body: some View {
        List {
            Section("Search by source position") {
                TextField("Line", text: $lineNumberString)
                    .textFieldStyle(.roundedBorder)
                TextField("Column", text: $columnNumberString)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    searchSource()
                }, label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                })
            }
            
            Section("Search by variable name") {
                TextField("Variable name", text: $variableName)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    searchSource()
                }, label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                })
            }
        }
    }
    
    
    private func searchSource() {
        if let line = Int(lineNumberString), let column = Int(columnNumberString) {
            do {
                try source_finder.searchSource(mapURL: mapData.url, line: line, column: column)
            } catch {
                print(error)
            }
        }
    }
}

struct UserActionView_Previews: PreviewProvider {
    static var previews: some View {
        UserActionView(mapData: MapData(url: URL(string: "file:///")!, shortName: "abcd", map: SourceMap()))
    }
}
