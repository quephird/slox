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
    case userDefinedFunction(UserDefinedFunction)
    case nativeFunction(NativeFunction)
    case `class`(LoxClass)
    case instance(LoxInstance)

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
        case .userDefinedFunction(let function):
            return "<function: \(function.name)>"
        case .nativeFunction(let function):
            return "<function: \(function)>"
        case .class(let klass):
            return "<class: \(klass.name)>"
        case .instance(let instance):
            if let klass = instance.klass {
                return "<instance: \(klass.name)>"
            }

            return "<instance: metaclass>"
        }
    }
}
