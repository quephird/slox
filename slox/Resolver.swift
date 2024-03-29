//
//  Resolver.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

struct Resolver {
    private enum FunctionType {
        case none
        case function
        case method
        case lambda
        case initializer
    }

    private enum ClassType {
        case none
        case `class`
        case subclass
    }

    private enum LoopType {
        case none
        case loop
    }

    private var scopeStack: [[String: Bool]] = []
    private var currentFunctionType: FunctionType = .none
    private var currentClassType: ClassType = .none
    private var currentLoopType: LoopType = .none

    // Main point of entry
    mutating func resolve(statements: [Statement]) throws -> [ResolvedStatement] {
        let resolvedStatements = try statements.map { statement in
            return try resolve(statement: statement)
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
        case .class(let nameToken, let superclassExpr, let methods, let staticMethods):
            return try handleClassDeclaration(nameToken: nameToken,
                                              superclassExpr: superclassExpr,
                                              methods: methods,
                                              staticMethods: staticMethods)
        case .function(let nameToken, let lambdaExpr):
            return try handleFunctionDeclaration(nameToken: nameToken,
                                                 lambdaExpr: lambdaExpr,
                                                 functionType: .function)
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
        case .for(let initializerStmt, let testExpr, let incrementExpr, let bodyStmt):
            return try handleFor(initializerStmt: initializerStmt,
                                 testExpr: testExpr,
                                 incrementExpr: incrementExpr,
                                 bodyStmt: bodyStmt)
        case .break(let breakToken):
            return try handleBreak(breakToken: breakToken)
        case .continue(let continueToken):
            return try handleContinue(continueToken: continueToken)
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

    mutating private func handleClassDeclaration(nameToken: Token,
                                                 superclassExpr: Expression?,
                                                 methods: [Statement],
                                                 staticMethods: [Statement]) throws -> ResolvedStatement {
        let previousClassType = currentClassType
        let previousLoopType = currentLoopType
        currentClassType = .class
        currentLoopType = .none
        defer {
            currentClassType = previousClassType
            currentLoopType = previousLoopType
        }

        try declareVariable(name: nameToken.lexeme)
        defineVariable(name: nameToken.lexeme)

        // ACHTUNG! We need to attmept to resolve the superclass _before_
        // pushing `this` onto the stack, otherwise we won't find it!
        var resolvedSuperclassExpr: ResolvedExpression? = nil
        if case .variable(let superclassName) = superclassExpr {
            currentClassType = .subclass

            if superclassName.lexeme == nameToken.lexeme {
                throw ResolverError.classCannotInheritFromItself
            }

            resolvedSuperclassExpr = try handleVariable(nameToken: superclassName)
        }

        if resolvedSuperclassExpr != nil {
            beginScope()
            scopeStack.lastMutable["super"] = true
        }
        defer {
            if resolvedSuperclassExpr != nil {
                endScope()
            }
        }

        beginScope()
        defer {
            endScope()
        }
        // NOTA BENE: Note that the scope stack is never empty at this point
        scopeStack.lastMutable["this"] = true

        let resolvedMethods = try methods.map { method in
            guard case .function(let nameToken, let lambdaExpr) = method else {
                throw ResolverError.notAFunction
            }

            let functionType: FunctionType = if nameToken.lexeme == "init" {
                .initializer
            } else {
                .method
            }
            return try handleFunctionDeclaration(nameToken: nameToken,
                                                 lambdaExpr: lambdaExpr,
                                                 functionType: functionType)
        }

        let resolvedStaticMethods = try staticMethods.map { method in
            guard case .function(let nameToken, let lambdaExpr) = method else {
                throw ResolverError.notAFunction
            }

            if nameToken.lexeme == "init" {
                throw ResolverError.staticInitsNotAllowed
            }

            return try handleFunctionDeclaration(nameToken: nameToken,
                                                 lambdaExpr: lambdaExpr,
                                                 functionType: .method)
        }

        return .class(nameToken, resolvedSuperclassExpr, resolvedMethods, resolvedStaticMethods)
    }

    mutating private func handleFunctionDeclaration(nameToken: Token,
                                                    lambdaExpr: Expression,
                                                    functionType: FunctionType) throws -> ResolvedStatement {
        guard case .lambda(let paramTokens, let statements) = lambdaExpr else {
            throw ResolverError.notAFunction
        }

        try declareVariable(name: nameToken.lexeme)
        defineVariable(name: nameToken.lexeme)

        let resolvedLambda = try handleLambda(params: paramTokens,
                                              statements: statements,
                                              functionType: functionType)

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

        // NOTA BENE: We allow for an initializer to have a `return`
        // statement if it does _not_ include an expression.
        if let expr {
            if currentFunctionType == .initializer {
                throw ResolverError.cannotReturnValueFromInitializer
            }

            let resolvedExpr = try resolve(expression: expr)
            return .return(returnToken, resolvedExpr)
        }

        return .return(returnToken, nil)
    }

    mutating private func handleBreak(breakToken: Token) throws -> ResolvedStatement {
        if currentLoopType == .none {
            throw ResolverError.cannotBreakOutsideLoop
        }

        return .break(breakToken)
    }

    mutating private func handleContinue(continueToken: Token) throws -> ResolvedStatement {
        if currentLoopType == .none {
            throw ResolverError.cannotContinueOutsideLoop
        }

        return .continue(continueToken)
    }

    mutating private func handleWhile(conditionExpr: Expression, bodyStmt: Statement) throws -> ResolvedStatement {
        let previousLoopType = currentLoopType
        currentLoopType = .loop
        defer {
            currentLoopType = previousLoopType
        }

        let resolvedConditionExpr = try resolve(expression: conditionExpr)
        let resolvedBodyStmt = try resolve(statement: bodyStmt)

        return .while(resolvedConditionExpr, resolvedBodyStmt)
    }

    mutating private func handleFor(initializerStmt: Statement?,
                                    testExpr: Expression,
                                    incrementExpr: Expression?,
                                    bodyStmt: Statement) throws -> ResolvedStatement {
        let previousLoopType = currentLoopType
        currentLoopType = .loop
        defer {
            currentLoopType = previousLoopType
        }

        var resolvedInitializerStmt: ResolvedStatement? = nil
        if let initializerStmt {
            resolvedInitializerStmt = try resolve(statement: initializerStmt)
        }

        let resolvedTestExpr = try resolve(expression: testExpr)

        var resolvedIncrementExpr: ResolvedExpression? = nil
        if let incrementExpr {
            resolvedIncrementExpr = try resolve(expression: incrementExpr)
        }

        let resolvedBodyStmt = try resolve(statement: bodyStmt)

        return .for(resolvedInitializerStmt,
                    resolvedTestExpr,
                    resolvedIncrementExpr,
                    resolvedBodyStmt)
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
        case .get(let instanceExpr, let propertyNameToken):
            return try handleGet(instanceExpr: instanceExpr, propertyNameToken: propertyNameToken)
        case .set(let instanceExpr, let propertyNameToken, let valueExpr):
            return try handleSet(instanceExpr: instanceExpr,
                                 propertyNameToken: propertyNameToken,
                                 valueExpr: valueExpr)
        case .this(let thisToken):
            return try handleThis(thisToken: thisToken)
        case .literal(let value):
            return .literal(value)
        case .grouping(let expr):
            let resolvedExpr = try resolve(expression: expr)
            return .grouping(resolvedExpr)
        case .logical(let leftExpr, let operToken, let rightExpr):
            return try handleLogical(leftExpr: leftExpr, operToken: operToken, rightExpr: rightExpr)
        case .lambda(let params, let statements):
            return try handleLambda(params: params, statements: statements, functionType: .lambda)
        case .super(let superToken, let methodToken):
            return try handleSuper(superToken: superToken, methodToken: methodToken)
        case .list(let elements):
            return try handleList(elements: elements)
        case .subscriptGet(let listExpr, let indexExpr):
            return try handleSubscriptGet(listExpr: listExpr, indexExpr: indexExpr)
        case .subscriptSet(let listExpr, let indexExpr, let valueExpr):
            return try handleSubscriptSet(listExpr: listExpr, indexExpr: indexExpr, valueExpr: valueExpr)
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

    mutating private func handleGet(instanceExpr: Expression,
                                    propertyNameToken: Token) throws -> ResolvedExpression {
        // Note that we don't attempt to resolve property names
        // because they are defined and looked up at _runtime_.
        let resolvedInstanceExpr = try resolve(expression: instanceExpr)

        return .get(resolvedInstanceExpr, propertyNameToken)
    }

    mutating private func handleSet(instanceExpr: Expression,
                                    propertyNameToken: Token,
                                    valueExpr: Expression) throws -> ResolvedExpression {
        // As with `get` expressions, we do _not_ try to
        // resolve property names.
        let resolvedInstanceExpr = try resolve(expression: instanceExpr)
        let resolvedValueExpr = try resolve(expression: valueExpr)

        return .set(resolvedInstanceExpr, propertyNameToken, resolvedValueExpr)
    }

    mutating private func handleThis(thisToken: Token) throws -> ResolvedExpression {
        guard case .class = currentClassType else {
            throw ResolverError.cannotReferenceThisOutsideClass
        }

        let depth = getDepth(name: thisToken.lexeme)
        return .this(thisToken, depth)
    }

    mutating private func handleLogical(leftExpr: Expression,
                                        operToken: Token,
                                        rightExpr: Expression) throws -> ResolvedExpression {
        let resolvedLeftExpr = try resolve(expression: leftExpr)
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .logical(resolvedLeftExpr, operToken, resolvedRightExpr)
    }

    mutating private func handleLambda(params: [Token]?,
                                       statements: [Statement],
                                       functionType: FunctionType) throws -> ResolvedExpression {
        beginScope()
        let previousFunctionType = currentFunctionType
        let previousLoopType = currentLoopType
        currentFunctionType = functionType
        currentLoopType = .none
        defer {
            endScope()
            currentFunctionType = previousFunctionType
            currentLoopType = previousLoopType
        }

        if let params {
            for param in params {
                try declareVariable(name: param.lexeme)
                defineVariable(name: param.lexeme)
            }
        }

        let resolvedStatements = try statements.map { statement in
            try resolve(statement: statement)
        }

        return .lambda(params, resolvedStatements)
    }

    mutating private func handleSuper(superToken: Token, methodToken: Token) throws -> ResolvedExpression {
        switch currentClassType {
        case .none:
            throw ResolverError.cannotReferenceSuperOutsideClass
        case .class:
            throw ResolverError.cannotReferenceSuperWithoutSubclassing
        case .subclass:
            break
        }

        let depth = getDepth(name: superToken.lexeme)
        return .super(superToken, methodToken, depth)
    }

    mutating private func handleList(elements: [Expression]) throws -> ResolvedExpression {
        let resolvedElements = try elements.map { element in
            return try resolve(expression: element)
        }

        return .list(resolvedElements)
    }

    mutating private func handleSubscriptGet(listExpr: Expression, indexExpr: Expression) throws -> ResolvedExpression {
        let resolvedListExpr = try resolve(expression: listExpr)
        let resolvedIndexExpr = try resolve(expression: indexExpr)

        return .subscriptGet(resolvedListExpr, resolvedIndexExpr)
    }

    mutating private func handleSubscriptSet(listExpr: Expression,
                                             indexExpr: Expression,
                                             valueExpr: Expression) throws -> ResolvedExpression {
        let resolvedListExpr = try resolve(expression: listExpr)
        let resolvedIndexExpr = try resolve(expression: indexExpr)
        let resolvedValueExpr = try resolve(expression: valueExpr)

        return .subscriptSet(resolvedListExpr, resolvedIndexExpr, resolvedValueExpr)
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
