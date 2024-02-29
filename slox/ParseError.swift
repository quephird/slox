//
//  ParseError.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

import Foundation

enum ParseError: CustomStringConvertible, Equatable, LocalizedError {
    case missingClosingParenthesis(Token)
    case expectedPrimaryExpression(Token)
    case missingSemicolon(Token)
    case missingVariableName(Token)
    case invalidAssignmentTarget(Token)
    case missingClosingBrace(Token)
    case missingOpenParenForIfStatement(Token)
    case missingCloseParenForIfStatement(Token)
    case missingOpenParenForWhileStatement(Token)
    case missingCloseParenForWhileStatement(Token)
    case missingOpenParenForForStatement(Token)
    case missingCloseParenForForStatement(Token)
    case missingSemicolonAfterForLoopCondition(Token)

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
        case .invalidAssignmentTarget(let token):
            return "[Line \(token.line)] Error: invalid assignment target"
        case .missingClosingBrace(let token):
            return "[Line \(token.line)] Error: expected closing brace after block"
        case .missingOpenParenForIfStatement(let token):
            return "[Line \(token.line)] Error: expected left parenthesis after `if`"
        case .missingCloseParenForIfStatement(let token):
            return "[Line \(token.line)] Error: expected right parenthesis after `if` condition"
        case .missingOpenParenForWhileStatement(let token):
            return "[Line \(token.line)] Error: expected left parenthesis after `while`"
        case .missingCloseParenForWhileStatement(let token):
            return "[Line \(token.line)] Error: expected right parenthesis after `while` condition"
        case .missingOpenParenForForStatement(let token):
            return "[Line \(token.line)] Error: expected left parenthesis after `for`"
        case .missingCloseParenForForStatement(let token):
            return "[Line \(token.line)] Error: expected right parenthesis after `for` clauses"
        case .missingSemicolonAfterForLoopCondition(let token):
            return "[Line \(token.line)] Error: expected semicolon after `for` loop condition"
        }
    }
}
