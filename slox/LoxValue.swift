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
    case instance(LoxInstance)

    var description: String {
        switch self {
        case .string(let string):
            return "\"\(string)\""
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
        case .instance(let klass as LoxClass):
            return "<class: \(klass.name)>"
        case .instance(let list as LoxList):
            var string = "["
            for (i, element) in list.elements.enumerated() {
                if i > 0 {
                    string.append(", ")
                }
                string.append("\(element)")
            }
            string.append("]")
            return string
        case .instance(let instance):
            return "<instance: \(instance.klass.name)>"
        }
    }
}
