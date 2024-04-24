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
    //                   | enumDecl
    //                   | funDecl
    //                   | varDecl
    //                   | statement ;
    //    classDecl      → "class" IDENTIFIER ( "<" IDENTIFIER )?
    //                     "{" function* "}" ;
    //    enumDecl       → "enum" IDENTIFIER "{"
    //                     "case" (IDENTIFIER ( "," IDENTIFIER )*)? ";"
    //                     function* "}" ;
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

        if let enumDecl = try parseEnumDeclaration() {
            return enumDecl
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

        guard let className = consumeToken(type: .identifier) else {
            throw ParseError.missingClassName(currentToken)
        }

        var superclassExpr: Expression? = nil
        if currentTokenMatchesAny(types: [.less]) {
            guard let superclassName = consumeToken(type: .identifier) else {
                throw ParseError.missingSuperclassName(currentToken)
            }

            superclassExpr = .variable(superclassName)
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

        guard currentTokenMatchesAny(types: [.rightBrace]) else {
            throw ParseError.missingClosingBrace(previousToken)
        }

        return .class(className, superclassExpr, methodStatements, staticMethodStatements)
    }

    mutating private func parseEnumDeclaration() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.enum]) else {
            return nil
        }

        guard let enumName = consumeToken(type: .identifier) else {
            throw ParseError.missingEnumName(currentToken)
        }

        guard currentTokenMatchesAny(types: [.leftBrace]) else {
            throw ParseError.missingOpenBraceBeforeEnumBody(currentToken)
        }

        guard currentTokenMatchesAny(types: [.case]) else {
            throw ParseError.missingCaseKeyword(currentToken)
        }

        var enumCases: [Token] = []
        if currentToken.type != .rightBrace {
            repeat {
                guard let enumCase = consumeToken(type: .identifier) else {
                    throw ParseError.missingParameterName(currentToken)
                }

                enumCases.append(enumCase)
            } while currentTokenMatchesAny(types: [.comma])
        }

        guard currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolonAfterCaseClause(currentToken)
        }

        var methods: [Statement] = []
        while currentToken.type != .rightBrace && currentToken.type != .eof {
            // Note that we don't look for/consume a `fun` token before
            // calling `parseFunction()`. That's a deliberate design decision
            // by the original author.
            let method = try parseFunction()
            methods.append(method)
        }

        guard currentTokenMatchesAny(types: [.rightBrace]) else {
            throw ParseError.missingCloseParenAfterArguments(currentToken)
        }

        return .enum(enumName, enumCases, methods)
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
        guard let functionName = consumeToken(type: .identifier) else {
            throw ParseError.missingFunctionName(currentToken)
        }

        var parameterList: ParameterList? = nil
        if currentTokenMatchesAny(types: [.leftParen]) {
            parameterList = try parseParameters()
            if !currentTokenMatchesAny(types: [.rightParen]) {
                throw ParseError.missingCloseParenAfterArguments(currentToken)
            }
        }

        guard let functionBody = try parseBlock() else {
            throw ParseError.missingOpenBraceBeforeFunctionBody(currentToken)
        }

        return .function(functionName, .lambda(parameterList, functionBody))
    }

    mutating private func parseVariableDeclaration() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.var]) else {
            return nil
        }

        guard let varName = consumeToken(type: .identifier) else {
            throw ParseError.missingVariableName(currentToken)
        }

        var initializer: Expression? = nil
        if currentTokenMatchesAny(types: [.equal]) {
            initializer = try parseExpression()
        }

        guard currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolon(currentToken)
        }

        return .variableDeclaration(varName, initializer);
    }

    mutating private func parseStatement() throws -> Statement {
        if let forStmt = try parseForStatement() {
            return forStmt
        }

        if let ifStmt = try parseIfStatement() {
            return ifStmt
        }

        if let printStmt = try parsePrintStatement() {
            return printStmt
        }

        if let jumpStmt = try parseJumpStatement() {
            return jumpStmt
        }

        if let whileStmt = try parseWhileStatement() {
            return whileStmt
        }

        if let blockStmts = try parseBlock() {
            return .block(blockStmts)
        }

        return try parseExpressionStatement()
    }

    mutating private func parseForStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.for]) else {
            return nil
        }

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

    mutating private func parseIfStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.if]) else {
            return nil
        }

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

    mutating private func parsePrintStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.print]) else {
            return nil
        }

        let expr = try parseExpression()

        guard currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolon(currentToken)
        }

        return .print(expr)
    }

    mutating private func parseJumpStatement() throws -> Statement? {
        if let returnStmt = try parseReturnStatement() {
            return returnStmt
        }

        if let breakStmt = try parseBreakStatement() {
            return breakStmt
        }

        if let continueStmt = try parseContinueStatement() {
            return continueStmt
        }

        return nil
    }

    mutating private func parseReturnStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.return]) else {
            return nil
        }

        let returnToken = previousToken

        var expr: Expression? = nil
        if currentToken.type != .semicolon {
            expr = try parseExpression()
        }

        guard currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolon(currentToken)
        }

        return .return(returnToken, expr)
    }

    mutating private func parseBreakStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.break]) else {
            return nil
        }

        let breakToken = previousToken

        guard currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolon(currentToken)
        }

        return .break(breakToken)
    }

    mutating private func parseContinueStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.continue]) else {
            return nil
        }

        let continueToken = previousToken

        guard currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolon(currentToken)
        }

        return .continue(continueToken)
    }

    mutating private func parseWhileStatement() throws -> Statement? {
        guard currentTokenMatchesAny(types: [.while]) else {
            return nil
        }

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

    mutating private func parseBlock() throws -> [Statement]? {
        guard currentTokenMatchesAny(types: [.leftBrace]) else {
            return nil
        }

        var statements: [Statement] = []

        while currentToken.type != .rightBrace && currentToken.type != .eof {
            let statement = try parseDeclaration()
            statements.append(statement)
        }

        guard currentTokenMatchesAny(types: [.rightBrace]) else {
            throw ParseError.missingClosingBrace(previousToken)
        }

        return statements
    }

    mutating private func parseExpressionStatement() throws -> Statement {
        let expr = try parseExpression()

        // NOTA BENE: If the expression is the last thing to be parsed,
        // then we want to return that immediately so it can be evaluated
        // and whose result can be printed in the REPL, and without burdening
        // the user to add a semicolon at the end.
        guard currentToken.type == .eof || currentTokenMatchesAny(types: [.semicolon]) else {
            throw ParseError.missingSemicolon(currentToken)
        }

        return .expression(expr)
    }

    // The parsing strategy below follows these rules of precedence
    // in _ascending_ order:
    //
    //    expression     → assignment ;
    //    assignment     → ( call "." )? IDENTIFIER ( "=" | "+=" | "-=" | "*=" | "/=" ) assignment
    //                   | logicOr ;
    //    logicOr        → logicAnd ( "or" logicAnd )* ;
    //    logicAnd       → equality ( "and" equality )* ;
    //    equality       → comparison ( ( "!=" | "==" ) comparison )* ;
    //    comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
    //    term           → factor ( ( "-" | "+" ) factor )* ;
    //    factor         → unary ( ( "/" | "*" | "%" ) unary )* ;
    //    unary          → ( "!" | "-" | "*" ) unary
    //                   | postfix ;
    //    postfix        → primary ( "(" arguments? ")" | "." IDENTIFIER | "[" logicOr "]" )* ;
    //    primary        → NUMBER | STRING | "true" | "false" | "nil"
    //                   | "(" expression ")"
    //                   | "[" ( arguments? | kvPairs? ) "]"
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

        guard currentTokenMatchesAny(types: [.equal, .plusEqual, .minusEqual, .starEqual, .slashEqual]) else {
            return expr
        }

        let assignmentOperToken = previousToken
        let newAssignmentOperToken: Token? = switch assignmentOperToken.type {
        case .plusEqual:
            Token(type: .plus, lexeme: "+", line: previousToken.line)
        case .minusEqual:
            Token(type: .minus, lexeme: "-", line: previousToken.line)
        case .starEqual:
            Token(type: .star, lexeme: "*", line: previousToken.line)
        case .slashEqual:
            Token(type: .slash, lexeme: "/", line: previousToken.line)
        case .equal:
            nil
        default:
            fatalError()
        }

        let valueExpr = try parseAssignment()
        let newValueExpr = if let newAssignmentOperToken {
            Expression.binary(expr, newAssignmentOperToken, valueExpr)
        } else {
            valueExpr
        }

        if case .variable(let name) = expr {
            return .assignment(name, newValueExpr)
        } else if case .get(let instanceExpr, let propertyNameToken) = expr {
            return .set(instanceExpr, propertyNameToken, newValueExpr)
        } else if case .subscriptGet(let listExpr, let indexExpr) = expr {
            return .subscriptSet(listExpr, indexExpr, newValueExpr)
        }

        throw ParseError.invalidAssignmentTarget(assignmentOperToken)
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

        while currentTokenMatchesAny(types: [.slash, .star, .modulus]) {
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

        if currentTokenMatchesAny(types: [.star]) {
            let expr = try parseUnary()
            return .splat(expr)
        }

        return try parsePostfix()
    }

    mutating private func parsePostfix() throws -> Expression {
        var expr = try parsePrimary()

        while true {
            if let callExpr = try parseCall(expr: expr) {
                expr = callExpr
                continue
            }

            if let getExpr = try parseGet(expr: expr) {
                expr = getExpr
                continue
            }

            if let subscriptExpr = try parseSubscript(expr: expr) {
                expr = subscriptExpr
                continue
            }

            break
        }

        return expr
    }

    mutating private func parseCall(expr: Expression) throws -> Expression? {
        guard currentTokenMatchesAny(types: [.leftParen]) else {
            return nil
        }

        let args = try parseArguments(endTokenType: .rightParen)

        guard currentTokenMatchesAny(types: [.rightParen]) else {
            throw ParseError.missingCloseParenAfterArguments(currentToken)
        }

        return.call(expr, previousToken, args)
    }

    mutating private func parseGet(expr: Expression) throws -> Expression? {
        guard currentTokenMatchesAny(types: [.dot]) else {
            return nil
        }

        guard currentTokenMatchesAny(types: [.identifier]) else {
            throw ParseError.missingIdentifierAfterDot(currentToken)
        }

        return .get(expr, previousToken)
    }

    mutating private func parseSubscript(expr: Expression) throws -> Expression? {
        guard currentTokenMatchesAny(types: [.leftBracket]) else {
            return nil
        }

        let indexExpr = try parseLogicOr()

        guard currentTokenMatchesAny(types: [.rightBracket]) else {
            throw ParseError.missingCloseBracketForSubscriptAccess(currentToken)
        }

        return .subscriptGet(expr, indexExpr)
    }

    mutating private func parsePrimary() throws -> Expression {
        if let lambdaExpr = try parseLambda() {
            return lambdaExpr
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

        if currentTokenMatchesAny(types: [.double]) {
            let number = Double(previousToken.lexeme)!
            return .literal(.double(number))
        }
        if currentTokenMatchesAny(types: [.int]) {
            let number = Int(previousToken.lexeme)!
            return .literal(.int(number))
        }

        if currentTokenMatchesAny(types: [.string]) {
            return .string(previousToken)
        }

        if let groupingExpr = try parseGrouping() {
            return groupingExpr
        }

        if let collectionExpr = try parseCollectionExpression() {
            return collectionExpr
        }

        if let superExpr = try parseSuperExpression() {
            return superExpr
        }

        if currentTokenMatchesAny(types: [.this]) {
            return .this(previousToken)
        }

        if currentTokenMatchesAny(types: [.identifier]) {
            return .variable(previousToken)
        }

        throw ParseError.expectedPrimaryExpression(currentToken)
    }

    mutating private func parseGrouping() throws -> Expression? {
        guard currentTokenMatchesAny(types: [.leftParen]) else {
            return nil
        }

        let expr = try parseExpression()

        guard currentTokenMatchesAny(types: [.rightParen]) else {
            throw ParseError.missingClosingParenthesis(currentToken)
        }

        return .grouping(expr)
    }

    mutating private func parseCollectionExpression() throws -> Expression? {
        guard currentTokenMatchesAny(types: [.leftBracket]) else {
            return nil
        }

        if currentTokenMatchesAny(types: [.rightBracket]) {
            return .list([])
        }

        if currentTokenMatchesAny(types: [.colon]) && currentTokenMatchesAny(types: [.rightBracket]) {
            return .dictionary([])
        }

        let firstExpr = try parseExpression()

        if currentTokenMatchesAny(types: [.colon]) {
            let kvPairs = try parseKeyValuePairs(firstKeyExpr: firstExpr)
            return .dictionary(kvPairs)
        }

        let elements = try parseExpressionList(firstExpr: firstExpr)
        return .list(elements)
    }

    mutating private func parseSuperExpression() throws -> Expression? {
        guard currentTokenMatchesAny(types: [.super]) else {
            return nil
        }

        let superToken = previousToken
        if !currentTokenMatchesAny(types: [.dot]) {
            throw ParseError.missingDotAfterSuper(currentToken)
        }

        guard let methodToken = consumeToken(type: .identifier) else {
            throw ParseError.expectedSuperclassMethodName(currentToken)
        }

        return .super(superToken, methodToken)
    }

    mutating private func parseLambda() throws -> Expression? {
        guard currentTokenMatchesAny(types: [.fun]) else {
            return nil
        }

        if !currentTokenMatchesAny(types: [.leftParen]) {
            throw ParseError.missingOpenParenForFunctionDeclaration(currentToken)
        }
        let parameters = try parseParameters()
        if !currentTokenMatchesAny(types: [.rightParen]) {
            throw ParseError.missingCloseParenAfterArguments(currentToken)
        }

        guard let functionBody = try parseBlock() else {
            throw ParseError.missingOpenBraceBeforeFunctionBody(currentToken)
        }

        return .lambda(parameters, functionBody)
    }

    // Utility grammar rules:
    //
    //    parameters     → IDENTIFIER ( "," IDENTIFIER )* ;
    //    arguments      → expression ( "," expression )* ;
    //    kvPairs        → ( expression ":" expression ) ( expression ":" expression )* ;
    //
    mutating private func parseParameters() throws -> ParameterList {
        var normalParameters: [Token] = []
        var variadicParameter: Token? = nil
        if currentToken.type != .rightParen {
            repeat {
                if currentTokenMatchesAny(types: [.star]) {
                    guard let newParameter = consumeToken(type: .identifier) else {
                        throw ParseError.missingParameterName(currentToken)
                    }
                    variadicParameter = newParameter

                    guard currentTokenMatches(type: .rightParen) else {
                        throw ParseError.onlyOneTrailingVariadicParameterAllowed(currentToken)
                    }

                    break
                }

                guard let newParameter = consumeToken(type: .identifier) else {
                    throw ParseError.missingParameterName(currentToken)
                }

                normalParameters.append(newParameter)
            } while currentTokenMatchesAny(types: [.comma])
        }

        let parameterList = ParameterList(normalParameters: normalParameters, variadicParameter: variadicParameter)
        return parameterList
    }

    mutating private func parseExpressionList(firstExpr: Expression) throws -> [Expression] {
        var exprs: [Expression] = [firstExpr]

        while currentTokenMatchesAny(types: [.comma]) {
            let expr = try parseExpression()
            exprs.append(expr)
        }

        guard currentTokenMatchesAny(types: [.rightBracket]) else {
            throw ParseError.missingClosingBracket(previousToken)
        }

        return exprs
    }


    mutating private func parseKeyValuePairs(firstKeyExpr: Expression) throws -> [(Expression, Expression)] {
        let firstValueExpr = try parseExpression()

        var kvPairs = [(firstKeyExpr, firstValueExpr)]

        while currentTokenMatchesAny(types: [.comma]) {
            let keyExpr = try parseExpression()
            _ = consumeToken(type: .colon)
            let valExpr = try parseExpression()
            kvPairs.append((keyExpr, valExpr))
        }

        guard currentTokenMatchesAny(types: [.rightBracket]) else {
            throw ParseError.missingClosingBracket(previousToken)
        }

        return kvPairs
    }

    mutating private func parseArguments(endTokenType: TokenType) throws -> [Expression] {
        var args: [Expression] = []
        if currentToken.type != endTokenType {
            repeat {
                let newArg = try parseExpression()
                args.append(newArg)
            } while currentTokenMatchesAny(types: [.comma])
        }

        return args
    }

    // Other utility methods
    mutating private func consumeToken(type: TokenType) -> Token? {
        guard currentTokenMatches(type: type) else {
            return nil
        }

        advanceCursor()
        return previousToken
    }

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

    // TODO: We need to make sure we don't run out of tokens here
    mutating private func advanceCursor() {
        cursor += 1
    }
}
