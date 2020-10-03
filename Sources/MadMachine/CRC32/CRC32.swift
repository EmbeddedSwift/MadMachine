//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 03..
//

import Foundation

/// https://gist.github.com/antfarm/695fa78e0730b67eb094c77d53942216
class CRC32 {
        
    static var table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            (0..<8).reduce(UInt32(i), { c, _ in
                (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
            })
        }
    }()

    static func checksum<T: DataProtocol>(bytes: T) -> UInt32 {
        return ~(bytes.reduce(~UInt32(0), { crc, byte in
            (crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }
}
