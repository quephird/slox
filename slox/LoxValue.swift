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
    case callable(LoxCallable)

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
        case .callable:
            return "<callable>"
        }
    }

    // These are the rules of equality for Lox
    func isEqual(to: Self) -> Bool {
        switch (self, to) {
        case (.nil, .nil):
            return true
        case (.number(let leftNumber), .number(let rightNumber)):
            return leftNumber == rightNumber
        case (.string(let leftString), .string(let rightString)):
            return leftString == rightString
        case (.boolean(let leftBoolean), .boolean(let rightBoolean)):
            return leftBoolean == rightBoolean
        case (.instance(let leftList as LoxList), .instance(let rightList as LoxList)):
            return leftList == rightList
        default:
            return false
        }
    }

    // In Lox, `false` and `nil` are false; everything else is true
    var isTruthy: Bool {
        switch self {
        case .nil:
            return false
        case .boolean(let boolean):
            return boolean
        default:
            return true
        }
    }

    // NOTA BENE: This equality conformance is only for unit tests
    static func == (lhs: LoxValue, rhs: LoxValue) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.number(let lhsNumber), .number(let rhsNumber)):
            return lhsNumber == rhsNumber
        case (.boolean(let lhsBoolean), .boolean(let rhsBoolean)):
            return lhsBoolean == rhsBoolean
        case (.nil, .nil):
            return true
        default:
            return false
        }
    }
}
