//
//  Resolver.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

struct Resolver {
    private var scopeStack: [[String: Bool]] = []
    private var currentFunctionType: FunctionType = .none

    // Main point of entry
    mutating func resolve(statements: [Statement]) throws -> [ResolvedStatement] {
        var resolvedStatements: [ResolvedStatement] = []

        for statement in statements {
            let resolvedStatement = try resolve(statement: statement)
            resolvedStatements.append(resolvedStatement)
        }
        return resolvedStatements
    }

    // Resolver for statements
    private mutating func resolve(statement: Statement) throws -> ResolvedStatement {
        switch statement {
        case .block(let statements):
            return try handleBlock(statements: statements)
        case .variableDeclaration(let nameToken, let initializeExpr):
            return try handleVariableDeclaration(nameToken: nameToken, initializeExpr: initializeExpr)
        case .function(let nameToken, let lambdaExpr):
            return try handleFunctionDeclaration(nameToken: nameToken, lambdaExpr: lambdaExpr)
        case .expression(let expr):
            return try handleExpressionStatement(expr: expr)
        case .if(let testExpr, let consequentStmt, let alternativeStmt):
            return try handleIf(testExpr: testExpr, consequentStmt: consequentStmt, alternativeStmt: alternativeStmt)
        case .print(let expr):
            return try handlePrintStatement(expr: expr)
        case .return(let returnToken, let expr):
            return try handleReturnStatement(returnToken: returnToken, expr: expr)
        case .while(let conditionExpr, let bodyStmt):
            return try handleWhile(conditionExpr: conditionExpr, bodyStmt: bodyStmt)
        }
    }

    mutating private func handleBlock(statements: [Statement]) throws -> ResolvedStatement {
        beginScope()
        defer {
            endScope()
        }

        let resolvedStatements = try resolve(statements: statements)

        return .block(resolvedStatements)
    }

    mutating private func handleVariableDeclaration(nameToken: Token, initializeExpr: Expression?) throws -> ResolvedStatement {
        try declareVariable(name: nameToken.lexeme)

        var resolvedInitializerExpr: ResolvedExpression? = nil
        if let initializeExpr {
            resolvedInitializerExpr = try resolve(expression: initializeExpr)
        }

        defineVariable(name: nameToken.lexeme)
        return .variableDeclaration(nameToken, resolvedInitializerExpr)
    }

    mutating private func handleFunctionDeclaration(nameToken: Token, lambdaExpr: Expression) throws -> ResolvedStatement {
        guard case .lambda(let paramTokens, let statements) = lambdaExpr else {
            throw ResolverError.notAFunction
        }

        try declareVariable(name: nameToken.lexeme)
        defineVariable(name: nameToken.lexeme)

        let resolvedLambda = try handleLambda(params: paramTokens,
                                              statements: statements,
                                              functionType: .function)

        return .function(nameToken, resolvedLambda)
    }

    mutating private func handleExpressionStatement(expr: Expression) throws -> ResolvedStatement {
        let resolvedExpression = try resolve(expression: expr)
        return .expression(resolvedExpression)
    }

    mutating private func handleIf(testExpr: Expression,
                                   consequentStmt: Statement,
                                   alternativeStmt: Statement?) throws -> ResolvedStatement {
        let resolvedTestExpr = try resolve(expression: testExpr)
        let resolvedConsequentStmt = try resolve(statement: consequentStmt)

        var resolvedAlternativeStmt: ResolvedStatement? = nil
        if let alternativeStmt {
            resolvedAlternativeStmt = try resolve(statement: alternativeStmt)
        }

        return .if(resolvedTestExpr, resolvedConsequentStmt, resolvedAlternativeStmt)
    }

    mutating private func handlePrintStatement(expr: Expression) throws -> ResolvedStatement {
        let resolvedExpression = try resolve(expression: expr)
        return .print(resolvedExpression)
    }

    mutating private func handleReturnStatement(returnToken: Token, expr: Expression?) throws -> ResolvedStatement {
        if currentFunctionType == .none {
            throw ResolverError.cannotReturnOutsideFunction
        }

        if let expr {
            let resolvedExpr = try resolve(expression: expr)
            return .return(returnToken, resolvedExpr)
        }

        return .return(returnToken, nil)
    }

    mutating private func handleWhile(conditionExpr: Expression, bodyStmt: Statement) throws -> ResolvedStatement {
        let resolvedConditionExpr = try resolve(expression: conditionExpr)
        let resolvedBodyStmt = try resolve(statement: bodyStmt)

        return .while(resolvedConditionExpr, resolvedBodyStmt)
    }

    // Resolver for expressions
    mutating private func resolve(expression: Expression) throws -> ResolvedExpression {
        switch expression {
        case .variable(let nameToken):
            return try handleVariable(nameToken: nameToken)
        case .assignment(let nameToken, let valueExpr):
            return try handleAssignment(nameToken: nameToken, valueExpr: valueExpr)
        case .binary(let leftExpr, let operToken, let rightExpr):
            return try handleBinary(leftExpr: leftExpr, operToken: operToken, rightExpr: rightExpr)
        case .unary(let operToken, let rightExpr):
            return try handleUnary(operToken: operToken, rightExpr: rightExpr)
        case .call(let calleeExpr, let rightParenToken, let args):
            return try handleCall(calleeExpr: calleeExpr, rightParenToken: rightParenToken, args: args)
        case .literal(let value):
            return .literal(value)
        case .grouping(let expr):
            let resolvedExpr = try resolve(expression: expr)
            return .grouping(resolvedExpr)
        case .logical(let leftExpr, let operToken, let rightExpr):
            return try handleLogical(leftExpr: leftExpr, operToken: operToken, rightExpr: rightExpr)
        case .lambda(let params, let statements):
            return try handleLambda(params: params, statements: statements, functionType: .lambda)
        }
    }

    mutating private func handleVariable(nameToken: Token) throws -> ResolvedExpression {
        if !scopeStack.isEmpty && scopeStack.lastMutable[nameToken.lexeme] == false {
            throw ResolverError.variableAccessedBeforeInitialization
        }

        let depth = getDepth(name: nameToken.lexeme)
        return .variable(nameToken, depth)
    }

    mutating private func handleAssignment(nameToken: Token, valueExpr: Expression) throws -> ResolvedExpression {
        let resolveValueExpr = try resolve(expression: valueExpr)
        let depth = getDepth(name: nameToken.lexeme)

        return .assignment(nameToken, resolveValueExpr, depth)
    }

    mutating private func handleBinary(leftExpr: Expression,
                                       operToken: Token,
                                       rightExpr: Expression) throws -> ResolvedExpression {
        let resolvedLeftExpr = try resolve(expression: leftExpr)
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .binary(resolvedLeftExpr, operToken, resolvedRightExpr)
    }

    mutating private func handleUnary(operToken: Token, rightExpr: Expression) throws -> ResolvedExpression {
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .unary(operToken, resolvedRightExpr)
    }

    mutating private func handleCall(calleeExpr: Expression,
                                     rightParenToken: Token,
                                     args: [Expression]) throws -> ResolvedExpression {
        let resolvedCalleeExpr = try resolve(expression: calleeExpr)

        let resolvedArgs = try args.map { arg in
            try resolve(expression: arg)
        }

        return .call(resolvedCalleeExpr, rightParenToken, resolvedArgs)
    }

    mutating private func handleLogical(leftExpr: Expression,
                                        operToken: Token,
                                        rightExpr: Expression) throws -> ResolvedExpression {
        let resolvedLeftExpr = try resolve(expression: leftExpr)
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .logical(resolvedLeftExpr, operToken, resolvedRightExpr)
    }

    mutating private func handleLambda(params: [Token],
                                       statements: [Statement],
                                       functionType: FunctionType) throws -> ResolvedExpression {
        beginScope()
        let previousFunctionType = currentFunctionType
        currentFunctionType = .function
        defer {
            endScope()
            currentFunctionType = previousFunctionType
        }

        for param in params {
            try declareVariable(name: param.lexeme)
            defineVariable(name: param.lexeme)
        }

        let resolvedStatements = try statements.map { statement in
            try resolve(statement: statement)
        }

        return .lambda(params, resolvedStatements)
    }

    // Internal helpers
    mutating private func beginScope() {
        scopeStack.append([:])
    }

    mutating private func endScope() {
        scopeStack.removeLast()
    }

    mutating private func declareVariable(name: String) throws {
        // ACHTUNG!!! Only variables declared/defined in local
        // blocks are tracked by the resolver, which is why
        // we bail here since the stack is empty in the
        // global environment.
        if scopeStack.isEmpty {
            return
        }

        if scopeStack.lastMutable.keys.contains(name) {
            throw ResolverError.variableAlreadyDefined(name)
        }

        scopeStack.lastMutable[name] = false
    }

    mutating private func defineVariable(name: String) {
        // ACHTUNG!!! Only variables declared/defined in local
        // blocks are tracked by the resolver, which is why
        // we bail here since the stack is empty in the
        // global environment.
        if scopeStack.isEmpty {
            return
        }

        scopeStack.lastMutable[name] = true
    }

    private func getDepth(name: String) -> Int {
        var i = scopeStack.count - 1
        while i >= 0 {
            if let _ = scopeStack[i][name] {
                return scopeStack.count - 1 - i
            }

            i = i - 1
        }

        // If we get here, the variable must be defined
        // in the global environment, and not tracked by the
        // resolver, and so we return the depth required to
        // fetch the value of that variable.
        return scopeStack.count
    }
}

extension MutableCollection where Self: BidirectionalCollection {
    /// Accesses the last element of the collection, mutably.
    ///
    /// - Precondition: Collection is not empty.
    var lastMutable: Element {
        get {
            precondition(!isEmpty)
            return self[index(before: endIndex)]
        }
        set {
            precondition(!isEmpty)
            self[index(before: endIndex)] = newValue
        }
    }
}
