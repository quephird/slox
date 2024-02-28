//
//  Token.swift
//  slox
//
//  Created by Danielle Kefford on 2/22/24.
//

struct Token: CustomStringConvertible, Equatable {
    let type: TokenType
    let lexeme: String
    let line: Int

    init(type: TokenType, lexeme: String, line: Int) {
        self.type = type
        self.lexeme = lexeme
        self.line = line
    }

    var description: String {
        return "\(type) \(lexeme)"
    }
}
