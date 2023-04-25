//
//  ItemDropper.swift
//  source-finder
//
//  Created by Olaf Neumann on 20.04.23.
//

import SwiftUI

struct ItemDropper: View {
    let onDropAction: ([URL]) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(style: StrokeStyle(lineWidth: 5, dash: [10]))
            
            VStack {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .imageScale(.large)
                .frame(width: 60, height: 80)
                
                Text("Drag & Drop")
                    .font(.title)
                
                Text("Drop text, files, URLs or something similar here. We will try to figure out, how to open that.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
            }
            .opacity(0.7)
        }
        .onDrop(of: [.text, .plainText, .url, .fileURL], isTargeted: nil) {
            DropRecognizer.shared.work(with: $0, action: onDropAction)
            return true
        }
    }
}

struct ItemDropper_Previews: PreviewProvider {
    static var previews: some View {
        ItemDropper { _ in }
            .frame(maxWidth: 300)
    }
}
