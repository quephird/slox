//
//  RuntimeError.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

enum RuntimeError: CustomStringConvertible, Equatable, LocalizedError {
    case unaryOperandMustBeNumber(Token)
    case unsupportedUnaryOperator(Token)
    case binaryOperandsMustBeNumbers(Token)
    case binaryOperandsMustBeNumbersOrStringsOrLists(Token)
    case unsupportedBinaryOperator(Token)
    case undefinedVariable(Token)
    case notACallableObject(Token)
    case notAList(Token)
    case notAListOrDictionary(Token)
    case notANumber
    case notAString
    case notAnInt
    case notADouble
    case onlyInstancesHaveProperties(Token)
    case undefinedProperty(Token)
    case wrongArity(Token, Int, Int)
    case superclassMustBeAClass(Token)
    case indexMustBeAnInteger(Token?)

    indirect case errorInCall(RuntimeError, Token)

    var description: String {
        switch self {
        case .unaryOperandMustBeNumber(let locToken):
            return "[Line \(locToken.line)] Error: operand must be a number"
        case .unsupportedUnaryOperator(let locToken):
            return "[Line \(locToken.line)] Error: unsupported unary operator"
        case .binaryOperandsMustBeNumbers(let locToken):
            return "[Line \(locToken.line)] Error: operands must be both numbers"
        case .binaryOperandsMustBeNumbersOrStringsOrLists(let locToken):
            return "[Line \(locToken.line)] Error: operands must be either both numbers, strings, or lists"
        case .unsupportedBinaryOperator(let locToken):
            return "[Line \(locToken.line)] Error: unsupported binary operator"
        case .undefinedVariable(let nameToken):
            return "[Line \(nameToken.line)] Error: undefined variable '\(nameToken.lexeme)'"
        case .notACallableObject(let locToken):
            return "[Line \(locToken.line)] Error: expected a callable object"
        case .notAList(let locToken):
            return "[Line \(locToken.line)] Error: expected a list"
        case .notAListOrDictionary(let locToken):
            return "[Line \(locToken.line)] Error: expected a list or dictionary"
        case .notANumber:
            return "Error: expected a number"
        case .notAString:
            return "Error: expected a string"
        case .notAnInt:
            return "Error: expected an integer"
        case .notADouble:
            return "Error: expected a double"
        case .onlyInstancesHaveProperties(let locToken):
            return "[Line \(locToken.line)] Error: can only get/set properties of instances"
        case .undefinedProperty(let nameToken):
            return "[Line \(nameToken.line)] Error: undefined property '\(nameToken.lexeme)'"
        case .wrongArity(let locToken, let expected, let actual):
            return "[Line \(locToken.line)] Error: incorrect number of arguments; expected \(expected), got \(actual)"
        case .superclassMustBeAClass(let locToken):
            return "[Line \(locToken.line)] Error: can only subclass from another class"
        case .indexMustBeAnInteger(let locToken?):
            return "[Line \(locToken.line)] Error: index must be an integer"
        case .indexMustBeAnInteger(nil):
            return "Error: index must be an integer"

        case .errorInCall(let underlyingError, let nameToken):
            return underlyingError.description + "\n    [Line \(nameToken.line)] in call to \(nameToken.lexeme)()"
        }
    }
}
