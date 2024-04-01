//
//  TokenType.swift
//  slox
//
//  Created by Danielle Kefford on 2/22/24.
//

enum TokenType: Equatable {
    // Single-character tokens
    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case comma
    case dot
    case semicolon
    case leftBracket
    case rightBracket
    case modulus
    case colon

    // One or two character tokens
    case bang
    case bangEqual
    case equal
    case equalEqual
    case greater
    case greaterEqual
    case less
    case lessEqual
    case minus
    case minusEqual
    case plus
    case plusEqual
    case slash
    case slashEqual
    case star
    case starEqual

    // Literals
    case identifier
    case string
    case double
    case int

    // Keywords
    case and
    case `class`
    case `else`
    case `false`
    case fun
    case `for`
    case `if`
    case `nil`
    case or
    case `print`
    case `return`
    case `super`
    case this
    case `true`
    case `var`
    case `while`
    case `break`
    case `continue`

    case eof
}
