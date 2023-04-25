//
//  source_finderApp.swift
//  source-finder
//
//  Created by Olaf Neumann on 17.04.23.
//

import SwiftUI

@main
struct SourceFinderApp: App {
    var body: some Scene {
        WindowGroup {
            // ContentView()
            SourceFinderView()
                .navigationTitle("Source Finder")
        }
    }
}
