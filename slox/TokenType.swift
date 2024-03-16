//
//  TokenType.swift
//  slox
//
//  Created by Danielle Kefford on 2/22/24.
//

enum TokenType: Equatable {
    // Single-character tokens
    case leftParen, rightParen, leftBrace, rightBrace, comma, dot, minus, plus, semicolon, slash, star, leftBracket, rightBracket

    // One of two character tokens
    case bang, bangEqual, equal, equalEqual, greater, greaterEqual, less, lessEqual

    // Literals
    case identifier, string, number

    // Keywords
    case and, `class`, `else`, `false`, fun, `for`, `if`, `nil`, or, `print`, `return`, `super`, this, `true`, `var`, `while`, `break`

    case eof
}
