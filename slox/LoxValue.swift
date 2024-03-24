//
//  LoxValue.swift
//  slox
//
//  Created by Danielle Kefford on 2/23/24.
//

enum LoxValue: CustomStringConvertible, Equatable {
    case string(String)
    case double(Double)
    case int(Int)
    case boolean(Bool)
    case `nil`
    case userDefinedFunction(UserDefinedFunction)
    case nativeFunction(NativeFunction)
    case instance(LoxInstance)

    var description: String {
        switch self {
        case .string(let string):
            return "\"\(string)\""
        case .double(let number):
            return "\(number)"
        case .int(let number):
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

    // These are the rules of equality for Lox
    func isEqual(to: Self) -> Bool {
        switch (self, to) {
        case (.nil, .nil):
            return true
        case (.int(let leftNumber), .int(let rightNumber)):
            return leftNumber == rightNumber
        case (.double(let leftNumber), .double(let rightNumber)):
            return leftNumber == rightNumber
        case (.int(let leftNumber), .double(let rightNumber)):
            return Double(leftNumber) == rightNumber
        case (.double(let leftNumber), .int(let rightNumber)):
            return leftNumber == Double(rightNumber)
        case (.string(let leftString), .string(let rightString)):
            return leftString == rightString
        case (.boolean(let leftBoolean), .boolean(let rightBoolean)):
            return leftBoolean == rightBoolean
        case (.instance(let leftList as LoxList), .instance(let rightList as LoxList)):
            return leftList.elements == rightList.elements
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

    func convertToRawInt() throws -> Int {
        switch self {
        case .int(let number):
            return number
        case .double(let number):
            return Int(number)
        default:
            throw RuntimeError.notANumber
        }
    }

    func convertToRawDouble() throws -> Double {
        switch self {
        case .int(let number):
            return Double(number)
        case .double(let number):
            return number
        default:
            throw RuntimeError.notANumber
        }
    }

    // NOTA BENE: This equality conformance is only for unit tests
    static func == (lhs: LoxValue, rhs: LoxValue) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.int(let lhsNumber), .int(let rhsNumber)):
            return lhsNumber == rhsNumber
        case (.int, .double), (.double, .int), (.double, .double):
            let leftNumber = try! lhs.convertToRawDouble()
            let rightNumber = try! rhs.convertToRawDouble()
            return leftNumber == rightNumber
        case (.boolean(let lhsBoolean), .boolean(let rhsBoolean)):
            return lhsBoolean == rhsBoolean
        case (.nil, .nil):
            return true
        case (.instance(let leftList as LoxList), .instance(let rightList as LoxList)):
            return leftList.elements == rightList.elements
        default:
            return false
        }
    }
}
