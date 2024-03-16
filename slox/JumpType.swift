//
//  Return.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

import Foundation

enum JumpType: LocalizedError {
    case `return`(LoxValue)
    case `break`
    case `continue`
}
