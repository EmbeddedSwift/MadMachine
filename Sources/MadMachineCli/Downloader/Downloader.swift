//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation

struct Downloader {

    let link: String
    let progressReport: ((Double) -> Void)?
    
    init(link: String, progressReport: ((Double) -> Void)? = nil) {
        self.link = link
        self.progressReport = progressReport
    }

    func download(to: String) -> URL? {
        var fileUrl: URL?
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.downloadTask(with: URL(string: link)!) { url, response, error in
            defer { semaphore.signal() }
            guard
                let response = response as? HTTPURLResponse,
                    response.statusCode == 200,
                let url = url
            else {
                return
            }

            let destination = URL(fileURLWithPath: to)
            do {
                try FileManager.default.moveItem(at: url, to: destination)
            }
            catch {
                /// todo: better error handler
                fatalError(error.localizedDescription)
            }
            fileUrl = destination
        }
        let observation = task.progress.observe(\.fractionCompleted) { report, _ in
            progressReport?(report.fractionCompleted)
        }
        task.resume()
        semaphore.wait()
        observation.invalidate()
        return fileUrl
    }
}
