//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 01..
//

import Foundation

extension FileManager {

    func findFiles(at path: String, _ extensions: String...) -> [URL] {
        let url = URL(fileURLWithPath: path)
        var files = [URL]()
        if let enumerator = enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        files.append(fileURL)
                    }
                }
                catch {
                    fatalError(error.localizedDescription)
                }
            }
        }
        return files.filter { extensions.contains($0.pathExtension.lowercased()) }
    }
}
