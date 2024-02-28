//
//  Parser.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

struct Parser {
    private var tokens: [Token]
    private var cursor: Int = 0
    private var currentToken: Token {
        return tokens[cursor]
    }
    private var previousToken: Token {
        return tokens[cursor - 1]
    }

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    mutating func parse() throws -> [Statement] {
        var statements: [Statement] = []
        while currentToken.type != .eof {
            let statement = try parseDeclaration()
            statements.append(statement)
        }

        return statements
    }

    // Statements are parsed in the following order:
    //
    //    program        → declaration* EOF ;
    //    declaration    → varDecl
    //                   | statement ;
    //    varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;
    //    statement      → expresssionStatement
    //                   | printStatement ;
    mutating func parseDeclaration() throws -> Statement {
        if matchesAny(types: [.var]) {
            return try parseVariableDeclaration()
        }

        return try parseStatement()
    }

    mutating private func parseVariableDeclaration() throws -> Statement {
        guard case .identifier = currentToken.type else {
            throw ParseError.missingVariableName(currentToken)
        }
        let name = currentToken
        advanceCursor()

        var initializer: Expression? = nil
        if matchesAny(types: [.equal]) {
            initializer = try parseExpression()
        }

        if matchesAny(types: [.semicolon]) {
            return .variableDeclaration(name, initializer);
        }

        throw ParseError.missingSemicolon(currentToken)
    }

    mutating func parseStatement() throws -> Statement {
        if matchesAny(types: [.print]) {
            return try parsePrintStatement()
        }

        return try parseExpressionStatement()
    }

    mutating func parsePrintStatement() throws -> Statement {
        let expr = try parseExpression()
        if matchesAny(types: [.semicolon]) {
            return .print(expr)
        }

        throw ParseError.missingSemicolon(currentToken)
    }

    mutating func parseExpressionStatement() throws -> Statement {
        let expr = try parseExpression()
        if matchesAny(types: [.semicolon]) {
            return .expression(expr)
        }

        throw ParseError.missingSemicolon(currentToken)
    }

    // The parsing strategy below follows these rules of precedence
    // in _ascending_ order:
    //
    //    expression     → equality ;
    //    equality       → comparison ( ( "!=" | "==" ) comparison )* ;
    //    comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
    //    term           → factor ( ( "-" | "+" ) factor )* ;
    //    factor         → unary ( ( "/" | "*" ) unary )* ;
    //    unary          → ( "!" | "-" ) unary
    //                   | primary ;
    //    primary        → NUMBER | STRING | "true" | "false" | "nil"
    //                   | "(" expression ")"
    //                   | IDENTIFIER
    //
    mutating private func parseExpression() throws -> Expression {
        return try parseEquality()
    }

    mutating private func parseEquality() throws -> Expression {
        var expr = try parseComparison()

        while matchesAny(types: [.bangEqual, .equalEqual]) {
            let oper = previousToken
            let rightExpr = try parseComparison()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseComparison() throws -> Expression {
        var expr = try parseTerm()

        while matchesAny(types: [.less, .lessEqual, .greater, .greaterEqual]) {
            let oper = previousToken
            let rightExpr = try parseTerm()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseTerm() throws -> Expression {
        var expr = try parseFactor()

        while matchesAny(types: [.plus, .minus]) {
            let oper = previousToken
            let rightExpr = try parseFactor()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseFactor() throws -> Expression {
        var expr = try parseUnary()

        while matchesAny(types: [.slash, .star]) {
            let oper = previousToken
            let rightExpr = try parseUnary()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseUnary() throws -> Expression {
        if matchesAny(types: [.bang, .minus]) {
            let oper = previousToken
            let expr = try parseUnary()
            return .unary(oper, expr)
        }

        return try parsePrimary()
    }

    mutating private func parsePrimary() throws -> Expression {
        if matchesAny(types: [.false]) {
            return .literal(.boolean(false))
        }
        if matchesAny(types: [.true]) {
            return .literal(.boolean(true))
        }
        if matchesAny(types: [.nil]) {
            return .literal(.nil)
        }

        if matchesAny(types: [.number]) {
            let number = Double(previousToken.lexeme)!
            return .literal(.number(number))
        }
        if matchesAny(types: [.string]) {
            assert(previousToken.lexeme.hasPrefix("\"") && previousToken.lexeme.hasSuffix("\""))
            let string = String(previousToken.lexeme.dropFirst().dropLast())
            return .literal(.string(string))
        }

        if matchesAny(types: [.leftParen]) {
            let expr = try parseExpression()
            if matchesAny(types: [.rightParen]) {
                return .grouping(expr)
            }

            throw ParseError.missingClosingParenthesis(currentToken)
        }

        if matchesAny(types: [.identifier]) {
            return .variable(previousToken)
        }

        throw ParseError.expectedPrimaryExpression(currentToken)
    }

    mutating private func matchesAny(types: [TokenType]) -> Bool {
        for type in types {
            if matches(type: type) {
                advanceCursor()
                return true
            }
        }

        return false
    }

    private func matches(type: TokenType) -> Bool {
        if currentToken.type == .eof {
            return false
        }

        return currentToken.type == type
    }

    // TODO: Figure out if we actually need this, and if so
    // figure out how to wire it up.
    mutating private func synchronize() {
        advanceCursor()

        while currentToken.type != .eof {
            if previousToken.type == .semicolon {
                return
            }

            switch currentToken.type {
            case .class, .fun, .var, .for, .if, .while, .print, .return:
                return
            default:
                break
            }

            advanceCursor()
        }
    }

    // TODO: We need to make sure we don't run out of tokens here
    mutating private func advanceCursor() {
        cursor += 1
    }
}
