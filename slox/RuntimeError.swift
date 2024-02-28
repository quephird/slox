//
//  RuntimeError.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

//struct RuntimeError: CustomStringConvertible, Equatable, LocalizedError {
//    var message: String
//
//    var description: String {
//        return "Error: \(message)"
//    }
//}

enum RuntimeError: CustomStringConvertible, Equatable, LocalizedError {
    case unaryOperandMustBeNumber
    case unsupportedUnaryOperator
    case binaryOperandsMustBeNumbers
    case binaryOperandsMustBeNumbersOrStrings
    case unsupportedBinaryOperator

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
        }
    }
}
