//
//  LoxValue.swift
//  slox
//
//  Created by Danielle Kefford on 2/23/24.
//

enum LoxValue: CustomStringConvertible, CustomDebugStringConvertible, Equatable, Hashable {
    case double(Double)
    case int(Int)
    case boolean(Bool)
    case `nil`
    case userDefinedFunction(UserDefinedFunction)
    case nativeFunction(NativeFunction)
    case instance(LoxInstance)

    var description: String {
        switch self {
        case .instance(let loxString as LoxString):
            return loxString.string
        default:
            return self.debugDescription
        }
    }

    var debugDescription: String {
        switch self {
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
        case .instance(let loxString as LoxString):
            return "\"\(loxString.string)\""
        case .instance(let enoom as LoxEnum):
            return "<enum: \(enoom.name)>"
        case .instance(let klass as LoxClass):
            return "<class: \(klass.name)>"
        case .instance(let list as LoxList):
            var string = "["
            for (i, element) in list.elements.enumerated() {
                if i > 0 {
                    string.append(", ")
                }
                string.append("\(String(reflecting: element))")
            }
            string.append("]")
            return string
        case .instance(let list as LoxDictionary):
            var string = "["
            if list.kvPairs.isEmpty {
                string.append(":")
            } else {
                for (i, kvPair) in list.kvPairs.enumerated() {
                    if i > 0 {
                        string.append(", ")
                    }
                    let (key, value) = kvPair
                    string.append("\(String(reflecting: key)): \(String(reflecting: value))")
                }
            }
            string.append("]")
            return string
        case .instance(let instance):
            if instance.klass is LoxEnum {
                let caseName = instance.properties["name"]!
                return "<enum case: \(instance.klass.name).\(caseName)>"
            }
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
        case (.boolean(let leftBoolean), .boolean(let rightBoolean)):
            return leftBoolean == rightBoolean
        case (.instance(let leftString as LoxString), .instance(let rightString as LoxString)):
            return leftString.string == rightString.string
        case (.instance(let leftList as LoxList), .instance(let rightList as LoxList)):
            return leftList.elements == rightList.elements
        case (.instance(let leftInstance), .instance(let rightInstance)):
            return leftInstance === rightInstance
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

    static func == (lhs: LoxValue, rhs: LoxValue) -> Bool {
        switch (lhs, rhs) {
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
        case (.userDefinedFunction(let leftFunc), .userDefinedFunction(let rightFunc)):
            return leftFunc.objectId == rightFunc.objectId
        case (.nativeFunction(let leftFunc), .nativeFunction(let rightFunc)):
            return leftFunc == rightFunc
        case (.instance(let leftString as LoxString), .instance(let rightString as LoxString)):
            return leftString.string == rightString.string
        case (.instance(let leftList as LoxList), .instance(let rightList as LoxList)):
            return leftList.elements == rightList.elements
        case (.instance(let leftDict as LoxDictionary), .instance(let rightDict as LoxDictionary)):
            return leftDict.kvPairs == rightDict.kvPairs
        case (.instance(let leftInstance), .instance(let rightInstance)):
            return leftInstance === rightInstance
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .double(let double):
            hasher.combine(double)
        case .int(let int):
            hasher.combine(int)
        case .boolean(let boolean):
            hasher.combine(boolean)
        case .nil:
            break
        case .userDefinedFunction(let userDefinedFunction):
            hasher.combine(userDefinedFunction.objectId)
        case .nativeFunction(let nativeFunction):
            hasher.combine(nativeFunction)
        case .instance(let loxString as LoxString):
            hasher.combine(loxString.string)
        case .instance(let instance):
            hasher.combine(ObjectIdentifier(instance))
        }
    }
}
