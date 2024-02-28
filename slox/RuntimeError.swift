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

    var description: String {
        switch self {
        case .unaryOperandMustBeNumber:
            return "Operand must be a number"
        case .unsupportedUnaryOperator:
            return "Unsupported unary operator"
        case .binaryOperandsMustBeNumbers:
            return "Operands must be both numbers"
        case .binaryOperandsMustBeNumbersOrStrings:
            return "Operands must be either both numbers or both strings"
        case .unsupportedBinaryOperator:
            return "Unsupported binary operator"
        case .undefinedVariable(let name):
            return "Undefined variable: \(name)"
        }
    }
}
