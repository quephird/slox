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
    case binaryOperandsMustBeNumbersOrStrings
    case unsupportedBinaryOperator
    case undefinedVariable(String)
    case notAFunction
    case wrongArity(Int, Int)
    case notALambda
    case couldNotFindAncestorEnvironmentAtDepth(Int)

    var description: String {
        switch self {
        case .unaryOperandMustBeNumber:
            return "Error: operand must be a number"
        case .unsupportedUnaryOperator:
            return "Error: unsupported unary operator"
        case .binaryOperandsMustBeNumbers:
            return "Error: operands must be both numbers"
        case .binaryOperandsMustBeNumbersOrStrings:
            return "Error: operands must be either both numbers or both strings"
        case .unsupportedBinaryOperator:
            return "Error: unsupported binary operator"
        case .undefinedVariable(let name):
            return "Error: undefined variable: \(name)"
        case .notAFunction:
            return "Error: can only call functions"
        case .wrongArity(let expected, let actual):
            return "Error: incorrect number of arguments: expected \(expected), got \(actual)"
        case .notALambda:
            return "Error: expected lambda as body of function declaration"
        case .couldNotFindAncestorEnvironmentAtDepth(let depth):
            return "Error: could not find ancestor environment at depth \(depth)."
        }
    }
}
