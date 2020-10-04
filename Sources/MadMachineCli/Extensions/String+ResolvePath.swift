//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 04..
//

import Foundation
import PathKit

extension String {

    var resolvedPath: String { hasPrefix("/") ? self : Path.current.child(self).location }
}
