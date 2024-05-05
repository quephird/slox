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
    case notAFunctionDeclaration
    case notACallableObject
    case notAnInstance
    case notAList
    case notADictionary
    case notAListOrDictionary
    case notANumber
    case notAString
    case notAnInt
    case notADouble
    case onlyInstancesHaveProperties(Token)
    case undefinedProperty(Token)
    case wrongArity(Int, Int)
    case notALambda
    case couldNotFindAncestorEnvironmentAtDepth(Int)
    case superclassMustBeAClass
    case indexMustBeAnInteger
    case thisNotResolved

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
        case .notAFunctionDeclaration:
            return "Fatal error: expected function declaration in class"
        case .notACallableObject:
            return "Fatal error: expected a callable object"
        case .notAnInstance:
            return "Error: expected an instance"
        case .notAList:
            return "Error: expected a list"
        case .notADictionary:
            return "Error: expected a dictionary"
        case .notAListOrDictionary:
            return "Error: expected a list or dictionary"
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
        case .wrongArity(let expected, let actual):
            return "Error: incorrect number of arguments; expected \(expected), got \(actual)"
        case .notALambda:
            return "Fatal error: expected lambda as body of function declaration"
        case .couldNotFindAncestorEnvironmentAtDepth(let depth):
            return "Fatal error: could not find ancestor environment at depth \(depth)."
        case .superclassMustBeAClass:
            return "Fatal error: superclass must be a class"
        case .indexMustBeAnInteger:
            return "Error: index must be a number"
        case .thisNotResolved:
            return "Fatal error: `this` not able to be resolved"
        }
    }
}
