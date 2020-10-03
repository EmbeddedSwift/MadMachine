//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation

struct GitHub {

    struct VersionInfo: Decodable {
        
        enum CodingKeys: String, CodingKey {
            case version = "tag_name"
            case downloadLink = "tarball_url"
        }

        let version: String
        let downloadLink: String
    }
    
    let repo: String
    
    init(repo: String) {
        self.repo = repo
    }

    var latestVersion: VersionInfo {
        var info: VersionInfo!
        let semaphore = DispatchSemaphore(value: 0)
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }
            
            guard
                let response = response as? HTTPURLResponse,
                    response.statusCode == 200,
                let data = data,
                let result = try? JSONDecoder().decode(VersionInfo.self, from: data)
            else {
                return
            }
            info = result
        }
        task.resume()
        semaphore.wait()
        precondition(info != nil, "Could not fetch version info")
        return info
    }
}
