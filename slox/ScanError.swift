//
//  LoxError.swift
//  slox
//
//  Created by Danielle Kefford on 2/23/24.
//

import Foundation

enum ScanError: CustomStringConvertible, Equatable, LocalizedError {
    case unterminatedString(Int)
    case unexpectedCharacter(Int)

    var description: String {
        switch self {
        case .unterminatedString(let line):
            return "[Line \(line)] Error: unterminated string"
        case .unexpectedCharacter(let line):
            return "[Line \(line)] Error: unexpected character"
        }
    }
}
