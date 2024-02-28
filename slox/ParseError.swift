//
//  ParseError.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

import Foundation

//struct ParseError: CustomStringConvertible, LocalizedError {
//    var token: Token
//    var message: String
//
//    var description: String {
//        return "[Line \(token.line)] Error: \(message)"
//    }
//}

enum ParseError: CustomStringConvertible, Equatable, LocalizedError {
    case missingClosingParenthesis(Token)
    case expectedPrimaryExpression(Token)
    case missingSemicolon(Token)
    case missingVariableName(Token)

    var description: String {
        switch self {
        case .missingClosingParenthesis(let token):
            return "[Line \(token.line)] Error: expected closing parenthesis in expression"
        case .expectedPrimaryExpression(let token):
            return "[Line \(token.line)] Error: expected primary expression"
        case .missingSemicolon(let token):
            return "[Line \(token.line)] Error: expected semicolon after value"
        case .missingVariableName(let token):
            return "[Line \(token.line)] Error: expected variable name"
        }
    }
}
