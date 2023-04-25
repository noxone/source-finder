//
//  SourceMapIdentifier.swift
//  source-finder
//
//  Created by Olaf Neumann on 20.04.23.
//

import Foundation
import SourceMapper

func searchSource(mapURL: URL, line: Int, column: Int) throws {
    let map = try SourceMap(data: try Data(contentsOf: mapURL))
    let segment = try map.map(line: line, column: column)
    print("segment", segment as Any)
    if let sp = segment?.sourcePos, let index = segment?.sourcePos?.source {
        print("sp", sp)
        let source = map.sources[Int(index)]
        print("source", source.url)
    }
}
