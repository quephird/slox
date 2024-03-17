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
    //    declaration    → classDecl
    //                   | funDecl
    //                   | varDecl
    //                   | statement ;
    //    classDecl      → "class" IDENTIFIER ( "<" IDENTIFIER )?
    //                     "{" function* "}" ;
    //    funDecl        → "fun" function ;
    //    function       → IDENTIFIER "(" parameters? ")" block ;
    //    varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;
    //    statement      → exprStmt
    //                   | forStmt
    //                   | ifStmt
    //                   | printStmt
    //                   | jumpStmt
    //                   | whileStmt
    //                   | block ;
    //    exprStmt       → expression ";" ;
    //    forStmt        → "for" "(" ( varDecl | exprStmt | ";" )
    //                     expression? ";"
    //                     expression? ")" statement ;
    //    ifStmt         → "if" "(" expression ")" statement
    //                     ( "else" statement )? ;
    //    printStmt      → "print" expression ";" ;
    //    jumpStmt       → ( "return" expression? ";"
    //                   | "break" ";"
    //                   | "continue" ";" ) ;
    //    whileStmt      → "while" "(" expression ")" statement ;
    //    block          → "{" declaration* "}" ;
    mutating private func parseDeclaration() throws -> Statement {
        if let classDecl = try parseClassDeclaration() {
            return classDecl
        }

        if let funDecl = try parseFunctionDeclaration() {
            return funDecl
        }

        if let varDecl = try parseVariableDeclaration() {
            return varDecl
        }

        return try parseStatement()
    }

    mutating private func parseClassDeclaration() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.class]) else {
            return nil
        }

        guard case .identifier = currentToken.type else {
            throw ParseError.missingClassName(currentToken)
        }
        let className = currentToken
        advanceCursor()

        var superclassExpr: Expression? = nil
        if currentTokenMatchesAny(types: [.less]) {
            guard case .identifier = currentToken.type else {
                throw ParseError.missingSuperclassName(currentToken)
            }

            superclassExpr = .variable(currentToken)
            advanceCursor()
        }

        if !currentTokenMatchesAny(types: [.leftBrace]) {
            throw ParseError.missingOpenBraceBeforeClassBody(currentToken)
        }

        var methodStatements: [Statement] = []
        var staticMethodStatements: [Statement] = []
        while currentToken.type != .rightBrace && currentToken.type != .eof {
            // Note that we don't look for/consume a `fun` token before
            // calling `parseFunction()`. That's a deliberate design decision
            // by the original author.
            if currentTokenMatchesAny(types: [.class]) {
                let staticMethodStatement = try parseFunction()
                staticMethodStatements.append(staticMethodStatement)
            } else {
                let methodStatement = try parseFunction()
                methodStatements.append(methodStatement)
            }
        }

        if currentTokenMatchesAny(types: [.rightBrace]) {
            return .class(className, superclassExpr, methodStatements, staticMethodStatements)
        }

        throw ParseError.missingClosingBrace(previousToken)
    }

    mutating private func parseFunctionDeclaration() throws -> Statement? {
        // We look ahead to see if the next token is an identifer,
        // and if so we assume this is a function declaration. Otherwise,
        // if the current token is `fun`, then we have a lambda, and we
        // will eventually parse it when we hit parsePrimary().
        guard currentTokenMatches(type: .fun), nextTokenMatches(type: .identifier) else {
            return nil
        }

        advanceCursor()
        return try parseFunction()
    }

    mutating private func parseFunction() throws -> Statement {
        guard case .identifier = currentToken.type else {
            throw ParseError.missingFunctionName(currentToken)
        }
        let functionName = currentToken
        advanceCursor()

        if !currentTokenMatchesAny(types: [.leftParen]) {
            throw ParseError.missingOpenParenForFunctionDeclaration(currentToken)
        }
        let parameters = try parseParameters()
        if !currentTokenMatchesAny(types: [.rightParen]) {
            throw ParseError.missingCloseParenAfterArguments(currentToken)
        }

        if !currentTokenMatchesAny(types: [.leftBrace]) {
            throw ParseError.missingOpenBraceBeforeFunctionBody(currentToken)
        }
        let functionBody = try parseBlock()

        return .function(functionName, .lambda(parameters, functionBody))
    }

    mutating private func parseVariableDeclaration() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.var]) else {
            return nil
        }

        guard case .identifier = currentToken.type else {
            throw ParseError.missingVariableName(currentToken)
        }
        let name = currentToken
        advanceCursor()

        var initializer: Expression? = nil
        if currentTokenMatchesAny(types: [.equal]) {
            initializer = try parseExpression()
        }

        if currentTokenMatchesAny(types: [.semicolon]) {
            return .variableDeclaration(name, initializer);
        }

        throw ParseError.missingSemicolon(currentToken)
    }

    mutating private func parseStatement() throws -> Statement {
        if currentTokenMatchesAny(types: [.for]) {
            return try parseForStatement()
        }

        if currentTokenMatchesAny(types: [.if]) {
            return try parseIfStatement()
        }

        if currentTokenMatchesAny(types: [.print]) {
            return try parsePrintStatement()
        }

        if [.return, .break, .continue].contains(currentToken.type) {
            return try parseJumpStatement()
        }

        if currentTokenMatchesAny(types: [.while]) {
            return try parseWhileStatement()
        }

        if currentTokenMatchesAny(types: [.leftBrace]) {
            let statements = try parseBlock()
            return .block(statements)
        }

        return try parseExpressionStatement()
    }

    mutating private func parseForStatement() throws -> Statement {
        if !currentTokenMatchesAny(types: [.leftParen]) {
            throw ParseError.missingOpenParenForForStatement(currentToken)
        }

        var initializerStmt: Statement?
        if currentTokenMatchesAny(types: [.semicolon]) {
            initializerStmt = nil
        } else if let varDecl = try parseVariableDeclaration() {
            initializerStmt = varDecl
        } else {
            initializerStmt = try parseExpressionStatement()
        }

        var testExpr: Expression = .literal(.boolean(true))
        if !currentTokenMatches(type: .semicolon) {
            testExpr = try parseExpression()
        }
        if !currentTokenMatchesAny(types: [.semicolon]) {
            throw ParseError.missingSemicolonAfterForLoopCondition(currentToken)
        }

        var incrementExpr: Expression? = nil
        if !currentTokenMatches(type: .rightParen) {
            incrementExpr = try parseExpression()
        }
        if !currentTokenMatchesAny(types: [.rightParen]) {
            throw ParseError.missingCloseParenForForStatement(currentToken)
        }

        let bodyStmt = try parseStatement()

        return .for(initializerStmt, testExpr, incrementExpr, bodyStmt)
    }

    mutating private func parseIfStatement() throws -> Statement {
        if !currentTokenMatchesAny(types: [.leftParen]) {
            throw ParseError.missingOpenParenForIfStatement(currentToken)
        }

        let testExpr = try parseExpression()
        if !currentTokenMatchesAny(types: [.rightParen]) {
            throw ParseError.missingCloseParenForIfStatement(currentToken)
        }

        let consequentStmt = try parseStatement()

        var alternativeStmt: Statement? = nil
        if currentTokenMatchesAny(types: [.else]) {
            alternativeStmt = try parseStatement()
        }

        return .if(testExpr, consequentStmt, alternativeStmt)
    }

    mutating private func parsePrintStatement() throws -> Statement {
        let expr = try parseExpression()
        if currentTokenMatchesAny(types: [.semicolon]) {
            return .print(expr)
        }

        throw ParseError.missingSemicolon(currentToken)
    }

    mutating private func parseJumpStatement() throws -> Statement {
        if currentTokenMatchesAny(types: [.return]) {
            let returnToken = previousToken

            var expr: Expression? = nil
            if currentToken.type != .semicolon {
                expr = try parseExpression()
            }

            if !currentTokenMatchesAny(types: [.semicolon]) {
                throw ParseError.missingSemicolon(currentToken)
            }

            return .return(returnToken, expr)
        }

        if currentTokenMatchesAny(types: [.break]) {
            let breakToken = previousToken

            if !currentTokenMatchesAny(types: [.semicolon]) {
                throw ParseError.missingSemicolon(currentToken)
            }

            return .break(breakToken)
        }

        if currentTokenMatchesAny(types: [.continue]) {
            let continueToken = previousToken

            if !currentTokenMatchesAny(types: [.semicolon]) {
                throw ParseError.missingSemicolon(currentToken)
            }

            return .continue(continueToken)
        }

        throw ParseError.unsupportedJumpStatement(currentToken)
    }

    mutating private func parseWhileStatement() throws -> Statement {
        if !currentTokenMatchesAny(types: [.leftParen]) {
            throw ParseError.missingOpenParenForWhileStatement(currentToken)
        }

        let expr = try parseExpression()
        if !currentTokenMatchesAny(types: [.rightParen]) {
            throw ParseError.missingCloseParenForWhileStatement(currentToken)
        }

        let stmt = try parseStatement()
        return .while(expr, stmt)
    }

    mutating private func parseBlock() throws -> [Statement] {
        var statements: [Statement] = []

        while currentToken.type != .rightBrace && currentToken.type != .eof {
            let statement = try parseDeclaration()
            statements.append(statement)
        }

        if currentTokenMatchesAny(types: [.rightBrace]) {
            return statements
        }

        throw ParseError.missingClosingBrace(previousToken)
    }

    mutating private func parseExpressionStatement() throws -> Statement {
        let expr = try parseExpression()

        // NOTA BENE: If the expression is the last thing to be parsed,
        // then we want to return that immediately so it can be evaluated
        // and whose result can be printed in the REPL, and without burdening
        // the user to add a semicolon at the end.
        if currentToken.type == .eof || currentTokenMatchesAny(types: [.semicolon]) {
            return .expression(expr)
        }

        throw ParseError.missingSemicolon(currentToken)
    }

    // The parsing strategy below follows these rules of precedence
    // in _ascending_ order:
    //
    //    expression     → assignment ;
    //    assignment     → ( call "." )? IDENTIFIER "=" assignment
    //                   | logicOr ;
    //    logicOr        → logicAnd ( "or" logicAnd )* ;
    //    logicAnd       → equality ( "and" equality )* ;
    //    equality       → comparison ( ( "!=" | "==" ) comparison )* ;
    //    comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
    //    term           → factor ( ( "-" | "+" ) factor )* ;
    //    factor         → unary ( ( "/" | "*" ) unary )* ;
    //    unary          → ( "!" | "-" ) unary
    //                   | postfix ;
    //    postfix        → primary ( "(" arguments? ")" | "." IDENTIFIER | "[" logicOr "]" )* ;
    //    primary        → NUMBER | STRING | "true" | "false" | "nil"
    //                   | "(" expression ")"
    //                   | "[" arguments? "]"
    //                   | "this"
    //                   | IDENTIFIER
    //                   | lambda
    //                   | "super" "." IDENTIFIER ;
    //    lambda         → "fun" "(" parameters? ")" block ;
    //
    mutating private func parseExpression() throws -> Expression {
        return try parseAssignment()
    }

    mutating private func parseAssignment() throws -> Expression {
        let expr = try parseLogicOr()

        if currentTokenMatchesAny(types: [.equal]) {
            let equalToken = previousToken
            let valueExpr = try parseAssignment()

            if case .variable(let name) = expr {
                return .assignment(name, valueExpr)
            } else if case .get(let instanceExpr, let propertyNameToken) = expr {
                return .set(instanceExpr, propertyNameToken, valueExpr)
            }

            throw ParseError.invalidAssignmentTarget(equalToken)
        }

        return expr
    }

    mutating private func parseLogicOr() throws -> Expression {
        var expr = try parseLogicAnd()

        while currentTokenMatchesAny(types: [.or]) {
            let oper = previousToken
            let right = try parseLogicAnd()
            expr = .logical(expr, oper, right)
        }

        return expr
    }

    mutating private func parseLogicAnd() throws -> Expression {
        var expr = try parseEquality()

        while currentTokenMatchesAny(types: [.and]) {
            let oper = previousToken
            let right = try parseEquality()
            expr = .logical(expr, oper, right)
        }

        return expr
    }

    mutating private func parseEquality() throws -> Expression {
        var expr = try parseComparison()

        while currentTokenMatchesAny(types: [.bangEqual, .equalEqual]) {
            let oper = previousToken
            let rightExpr = try parseComparison()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseComparison() throws -> Expression {
        var expr = try parseTerm()

        while currentTokenMatchesAny(types: [.less, .lessEqual, .greater, .greaterEqual]) {
            let oper = previousToken
            let rightExpr = try parseTerm()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseTerm() throws -> Expression {
        var expr = try parseFactor()

        while currentTokenMatchesAny(types: [.plus, .minus]) {
            let oper = previousToken
            let rightExpr = try parseFactor()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseFactor() throws -> Expression {
        var expr = try parseUnary()

        while currentTokenMatchesAny(types: [.slash, .star]) {
            let oper = previousToken
            let rightExpr = try parseUnary()
            expr = .binary(expr, oper, rightExpr)
        }

        return expr
    }

    mutating private func parseUnary() throws -> Expression {
        if currentTokenMatchesAny(types: [.bang, .minus]) {
            let oper = previousToken
            let expr = try parseUnary()
            return .unary(oper, expr)
        }

        return try parsePostfix()
    }

    mutating private func parsePostfix() throws -> Expression {
        var expr = try parsePrimary()

        while true {
            if currentTokenMatchesAny(types: [.leftParen]) {
                let args = try parseArguments()

                if !currentTokenMatchesAny(types: [.rightParen]) {
                    throw ParseError.missingCloseParenAfterArguments(currentToken)
                }

                expr = .call(expr, previousToken, args)
            } else if currentTokenMatchesAny(types: [.dot]) {
                if !currentTokenMatchesAny(types: [.identifier]) {
                    throw ParseError.missingIdentifierAfterDot(currentToken)
                }

                expr = .get(expr, previousToken)
            } else if currentTokenMatchesAny(types: [.leftBracket]) {
                let indexExpr = try parseLogicOr()

                if !currentTokenMatchesAny(types: [.rightBracket]) {
                    throw ParseError.missingCloseBracketForSubscriptAccess(currentToken)
                }

                if currentTokenMatchesAny(types: [.equal]) {
                    let valueExpr = try parseExpression()
                    expr = .subscriptSet(expr, indexExpr, valueExpr)
                } else {
                    expr = .subscriptGet(expr, indexExpr)
                }
            } else {
                break
            }
        }

        return expr
    }

    mutating private func parsePrimary() throws -> Expression {
        if currentTokenMatchesAny(types: [.fun]) {
            return try parseLambda()
        }

        if currentTokenMatchesAny(types: [.false]) {
            return .literal(.boolean(false))
        }
        if currentTokenMatchesAny(types: [.true]) {
            return .literal(.boolean(true))
        }
        if currentTokenMatchesAny(types: [.nil]) {
            return .literal(.nil)
        }

        if currentTokenMatchesAny(types: [.number]) {
            let number = Double(previousToken.lexeme)!
            return .literal(.number(number))
        }
        if currentTokenMatchesAny(types: [.string]) {
            assert(previousToken.lexeme.hasPrefix("\"") && previousToken.lexeme.hasSuffix("\""))
            let string = String(previousToken.lexeme.dropFirst().dropLast())
            return .literal(.string(string))
        }

        if currentTokenMatchesAny(types: [.leftParen]) {
            let expr = try parseExpression()
            if currentTokenMatchesAny(types: [.rightParen]) {
                return .grouping(expr)
            }

            throw ParseError.missingClosingParenthesis(currentToken)
        }

        if currentTokenMatchesAny(types: [.leftBracket]) {
            let elements = try parseArguments()

            if currentTokenMatchesAny(types: [.rightBracket]) {
                return .list(elements)
            }

            throw ParseError.missingClosingBracket(previousToken)
        }

        if currentTokenMatchesAny(types: [.super]) {
            let superToken = previousToken
            if !currentTokenMatchesAny(types: [.dot]) {
                throw ParseError.missingDotAfterSuper(currentToken)
            }

            guard case .identifier = currentToken.type else {
                throw ParseError.expectedSuperclassMethodName(currentToken)
            }
            let methodToken = currentToken
            advanceCursor()

            return .super(superToken, methodToken)
        }

        if currentTokenMatchesAny(types: [.this]) {
            return .this(previousToken)
        }

        if currentTokenMatchesAny(types: [.identifier]) {
            return .variable(previousToken)
        }

        throw ParseError.expectedPrimaryExpression(currentToken)
    }

    mutating private func parseLambda() throws -> Expression {
        if !currentTokenMatchesAny(types: [.leftParen]) {
            throw ParseError.missingOpenParenForFunctionDeclaration(currentToken)
        }
        let parameters = try parseParameters()
        if !currentTokenMatchesAny(types: [.rightParen]) {
            throw ParseError.missingCloseParenAfterArguments(currentToken)
        }

        if !currentTokenMatchesAny(types: [.leftBrace]) {
            throw ParseError.missingOpenBraceBeforeFunctionBody(currentToken)
        }
        let functionBody = try parseBlock()

        return .lambda(parameters, functionBody)
    }

    // Utility grammar rules:
    //
    //    parameters     → IDENTIFIER ( "," IDENTIFIER )* ;
    //    arguments      → expression ( "," expression )* ;
    //
    mutating private func parseParameters() throws -> [Token] {
        var parameters: [Token] = []
        if currentToken.type != .rightParen {
            repeat {
                guard case .identifier = currentToken.type else {
                    throw ParseError.missingParameterName(currentToken)
                }
                let newParameter = currentToken
                advanceCursor()

                parameters.append(newParameter)
            } while currentTokenMatchesAny(types: [.comma])
        }

        return parameters
    }

    mutating private func parseArguments() throws -> [Expression] {
        var args: [Expression] = []
        if currentToken.type != .rightParen {
            repeat {
                let newArg = try parseExpression()
                args.append(newArg)
            } while currentTokenMatchesAny(types: [.comma])
        }

        return args
    }

    // Other utility methods
    mutating private func currentTokenMatchesAny(types: [TokenType]) -> Bool {
        for type in types {
            if currentTokenMatches(type: type) {
                advanceCursor()
                return true
            }
        }

        return false
    }

    private func currentTokenMatches(type: TokenType) -> Bool {
        if currentToken.type == .eof {
            return false
        }

        return currentToken.type == type
    }

    private func nextTokenMatches(type: TokenType) -> Bool {
        if currentToken.type == .eof {
            return false
        }

        let nextToken = tokens[cursor + 1]
        if nextToken.type == .eof {
            return false
        }

        return nextToken.type == type
    }

    // TODO: Figure out if we actually need this, and if so
    // how to wire it up.
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
