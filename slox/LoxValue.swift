//
//  LoxValue.swift
//  slox
//
//  Created by Danielle Kefford on 2/23/24.
//

enum LoxValue: CustomStringConvertible, Equatable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case `nil`
    case function(LoxFunction)

    var description: String {
        switch self {
        case .string(let string):
            return string
        case .number(let number):
            return "\(number)"
        case .boolean(let boolean):
            return "\(boolean)"
        case .nil:
            return "nil"
        case .function(let function):
            return "<function: \(function.name)>"
        }
    }
}
