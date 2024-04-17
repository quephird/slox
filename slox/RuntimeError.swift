//
//  RuntimeError.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

enum RuntimeError: CustomStringConvertible, Equatable, LocalizedError {
    case unaryOperandMustBeNumber
    case unsupportedUnaryOperator
    case binaryOperandsMustBeNumbers
    case binaryOperandsMustBeNumbersOrStringsOrLists
    case unsupportedBinaryOperator
    case undefinedVariable(String)
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
    case onlyInstancesHaveProperties
    case undefinedProperty(String)
    case wrongArity(Int, Int)
    case notALambda
    case couldNotFindAncestorEnvironmentAtDepth(Int)
    case superclassMustBeAClass
    case indexMustBeAnInteger

    var description: String {
        switch self {
        case .unaryOperandMustBeNumber:
            return "Error: operand must be a number"
        case .unsupportedUnaryOperator:
            return "Error: unsupported unary operator"
        case .binaryOperandsMustBeNumbers:
            return "Error: operands must be both numbers"
        case .binaryOperandsMustBeNumbersOrStringsOrLists:
            return "Error: operands must be either both numbers, strings, or lists"
        case .unsupportedBinaryOperator:
            return "Error: unsupported binary operator"
        case .undefinedVariable(let name):
            return "Error: undefined variable '\(name)'"
        case .notAFunctionDeclaration:
            return "Error: expected function declaration in class"
        case .notACallableObject:
            return "Error: expected a callable object"
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
        case .onlyInstancesHaveProperties:
            return "Error: can only get/set properties of instances"
        case .undefinedProperty(let name):
            return "Error: undefined property '\(name)'"
        case .wrongArity(let expected, let actual):
            return "Error: incorrect number of arguments; expected \(expected), got \(actual)"
        case .notALambda:
            return "Error: expected lambda as body of function declaration"
        case .couldNotFindAncestorEnvironmentAtDepth(let depth):
            return "Error: could not find ancestor environment at depth \(depth)."
        case .superclassMustBeAClass:
            return "Error: superclass must be a class"
        case .indexMustBeAnInteger:
            return "Error: index must be a number"
        }
    }
}
