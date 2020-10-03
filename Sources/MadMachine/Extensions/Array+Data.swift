//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 03..
//

import Foundation

extension Array where Element == UInt8 {
    var data: Data { .init(self) }
}
