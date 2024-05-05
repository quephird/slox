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
        case `enum`
    }

    private enum JumpableType {
        case none
        case loop
        case `switch`
    }

    private enum ArgumentListType {
        case none
        case functionCall
        case listInitializer
    }

    private var scopeStack: [[String: Bool]] = []
    private var currentFunctionType: FunctionType = .none
    private var currentClassType: ClassType = .none
    private var currentJumpableType: JumpableType = .none
    private var currentArgumentListType: ArgumentListType = .none

    // Main point of entry
    mutating func resolve(statements: [Statement<UnresolvedDepth>]) throws -> [Statement<Int>] {
        let resolvedStatements = try statements.map { statement in
            return try resolve(statement: statement)
        }
        return resolvedStatements
    }

    // Resolver for statements
    private mutating func resolve(statement: Statement<UnresolvedDepth>) throws -> Statement<Int> {
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
        case .enum(let nameToken, let caseTokens, let methods, let staticMethods):
            return try handleEnumDeclaration(nameToken: nameToken,
                                             caseTokens: caseTokens,
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
        case .switch(let switchToken, let testExpr, let switchCaseDecls):
            return try handleSwitch(switchToken: switchToken,
                                    testExpr: testExpr,
                                    switchCaseDecls: switchCaseDecls)
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

    mutating private func handleBlock(statements: [Statement<UnresolvedDepth>]) throws -> Statement<Int> {
        beginScope()
        defer {
            endScope()
        }

        let resolvedStatements = try resolve(statements: statements)

        return .block(resolvedStatements)
    }

    mutating private func handleVariableDeclaration(nameToken: Token,
                                                    initializeExpr: Expression<UnresolvedDepth>?) throws -> Statement<Int> {
        try declareVariable(variableToken: nameToken)

        var resolvedInitializerExpr: Expression<Int>? = nil
        if let initializeExpr {
            resolvedInitializerExpr = try resolve(expression: initializeExpr)
        }

        defineVariable(name: nameToken.lexeme)
        return .variableDeclaration(nameToken, resolvedInitializerExpr)
    }

    mutating private func handleClassDeclaration(nameToken: Token,
                                                 superclassExpr: Expression<UnresolvedDepth>?,
                                                 methods: [Statement<UnresolvedDepth>],
                                                 staticMethods: [Statement<UnresolvedDepth>]) throws -> Statement<Int> {
        let previousClassType = currentClassType
        let previousJumpableType = currentJumpableType
        currentClassType = .class
        currentJumpableType = .none
        defer {
            currentClassType = previousClassType
            currentJumpableType = previousJumpableType
        }

        try declareVariable(variableToken: nameToken)
        defineVariable(name: nameToken.lexeme)

        // ACHTUNG! We need to attmept to resolve the superclass _before_
        // pushing `this` onto the stack, otherwise we won't find it!
        var resolvedSuperclassExpr: Expression<Int>? = nil
        if case .variable(let superclassName, _) = superclassExpr {
            currentClassType = .subclass

            if superclassName.lexeme == nameToken.lexeme {
                throw ResolverError.classCannotInheritFromItself(superclassName)
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
                throw ResolverError.staticInitsNotAllowed(nameToken)
            }

            return try handleFunctionDeclaration(nameToken: nameToken,
                                                 lambdaExpr: lambdaExpr,
                                                 functionType: .method)
        }

        return .class(nameToken, resolvedSuperclassExpr, resolvedMethods, resolvedStaticMethods)
    }

    mutating private func handleEnumDeclaration(nameToken: Token,
                                                caseTokens: [Token],
                                                methods: [Statement<UnresolvedDepth>],
                                                staticMethods: [Statement<UnresolvedDepth>]) throws -> Statement<Int> {
        let previousClassType = currentClassType
        currentClassType = .enum
        defer {
            currentClassType = previousClassType
        }

        try declareVariable(variableToken: nameToken)
        defineVariable(name: nameToken.lexeme)

        beginScope()
        defer {
            endScope()
        }
        scopeStack.lastMutable["this"] = true

        var caseNameSet: Set<String> = Set()
        for caseToken in caseTokens {
            let (inserted, _) = caseNameSet.insert(caseToken.lexeme)
            if !inserted {
                throw ResolverError.duplicateCaseNamesNotAllowed(caseToken)
            }
        }

        let resolvedMethods = try methods.map { method in
            guard case .function(let nameToken, let lambdaExpr) = method else {
                throw ResolverError.notAFunction
            }

            return try handleFunctionDeclaration(nameToken: nameToken,
                                                 lambdaExpr: lambdaExpr,
                                                 functionType: .method)
        }

        let resolvedStaticMethods = try staticMethods.map { method in
            guard case .function(let nameToken, let lambdaExpr) = method else {
                throw ResolverError.notAFunction
            }

            if nameToken.lexeme == "init" {
                throw ResolverError.staticInitsNotAllowed(nameToken)
            }

            return try handleFunctionDeclaration(nameToken: nameToken,
                                                 lambdaExpr: lambdaExpr,
                                                 functionType: .method)
        }

        return .enum(nameToken, caseTokens, resolvedMethods, resolvedStaticMethods)
    }


    mutating private func handleFunctionDeclaration(nameToken: Token,
                                                    lambdaExpr: Expression<UnresolvedDepth>,
                                                    functionType: FunctionType) throws -> Statement<Int> {
        guard case .lambda(let locToken, let parameterList, let statements) = lambdaExpr else {
            throw ResolverError.notAFunction
        }

        try declareVariable(variableToken: nameToken)
        defineVariable(name: nameToken.lexeme)

        let resolvedLambda = try handleLambda(locToken: locToken,
                                              parameterList: parameterList,
                                              statements: statements,
                                              functionType: functionType)

        return .function(nameToken, resolvedLambda)
    }

    mutating private func handleExpressionStatement(expr: Expression<UnresolvedDepth>) throws -> Statement<Int> {
        let resolvedExpression = try resolve(expression: expr)
        return .expression(resolvedExpression)
    }

    mutating private func handleIf(testExpr: Expression<UnresolvedDepth>,
                                   consequentStmt: Statement<UnresolvedDepth>,
                                   alternativeStmt: Statement<UnresolvedDepth>?) throws -> Statement<Int> {
        let resolvedTestExpr = try resolve(expression: testExpr)
        let resolvedConsequentStmt = try resolve(statement: consequentStmt)

        var resolvedAlternativeStmt: Statement<Int>? = nil
        if let alternativeStmt {
            resolvedAlternativeStmt = try resolve(statement: alternativeStmt)
        }

        return .if(resolvedTestExpr, resolvedConsequentStmt, resolvedAlternativeStmt)
    }

    mutating private func handleSwitch(switchToken: Token,
                                       testExpr: Expression<UnresolvedDepth>,
                                       switchCaseDecls: [SwitchCaseDeclaration<UnresolvedDepth>]) throws -> Statement<Int> {
        let previousJumpableType = currentJumpableType
        currentJumpableType = .switch
        defer {
            currentJumpableType = previousJumpableType
        }

        let resolvedTestExpr = try resolve(expression: testExpr)

        guard switchCaseDecls.count > 0 else {
            throw ResolverError.switchMustHaveAtLeastOneCaseOrDefault(switchToken)
        }
        let resolvedSwitchCaseDecls = try switchCaseDecls.map { switchCaseDecl in
            try handleSwitchCaseDeclaration(switchCaseDecl: switchCaseDecl)
        }

        return .switch(switchToken, resolvedTestExpr, resolvedSwitchCaseDecls)
    }

    mutating private func handleSwitchCaseDeclaration(switchCaseDecl: SwitchCaseDeclaration<UnresolvedDepth>) throws -> SwitchCaseDeclaration<Int> {
        let resolvedValueExprs = try switchCaseDecl.valueExpressions?.map { valueExpr in
            try resolve(expression: valueExpr)
        }

        guard case .block(let statements) = switchCaseDecl.statement,
              statements.count > 0 else {
            throw ResolverError.switchMustHaveAtLeastOneStatementPerCaseOrDefault(switchCaseDecl.caseToken)
        }

        let resolvedStmt = try resolve(statement: switchCaseDecl.statement)

        return SwitchCaseDeclaration(caseToken: switchCaseDecl.caseToken,
                                     valueExpressions: resolvedValueExprs,
                                     statement: resolvedStmt)
    }

    mutating private func handlePrintStatement(expr: Expression<UnresolvedDepth>) throws -> Statement<Int> {
        let resolvedExpression = try resolve(expression: expr)
        return .print(resolvedExpression)
    }

    mutating private func handleReturnStatement(returnToken: Token, expr: Expression<UnresolvedDepth>?) throws -> Statement<Int> {
        if currentFunctionType == .none {
            throw ResolverError.cannotReturnOutsideFunction(returnToken)
        }

        // NOTA BENE: We allow for an initializer to have a `return`
        // statement if it does _not_ include an expression.
        if let expr {
            if currentFunctionType == .initializer {
                throw ResolverError.cannotReturnValueFromInitializer(returnToken)
            }

            let resolvedExpr = try resolve(expression: expr)
            return .return(returnToken, resolvedExpr)
        }

        return .return(returnToken, nil)
    }

    mutating private func handleBreak(breakToken: Token) throws -> Statement<Int> {
        if currentJumpableType == .none {
            throw ResolverError.cannotBreakOutsideLoopOrSwitch(breakToken)
        }

        return .break(breakToken)
    }

    mutating private func handleContinue(continueToken: Token) throws -> Statement<Int> {
        if currentJumpableType != .loop {
            throw ResolverError.cannotContinueOutsideLoop(continueToken)
        }

        return .continue(continueToken)
    }

    mutating private func handleWhile(conditionExpr: Expression<UnresolvedDepth>,
                                      bodyStmt: Statement<UnresolvedDepth>) throws -> Statement<Int> {
        let previousLoopType = currentJumpableType
        currentJumpableType = .loop
        defer {
            currentJumpableType = previousLoopType
        }

        let resolvedConditionExpr = try resolve(expression: conditionExpr)
        let resolvedBodyStmt = try resolve(statement: bodyStmt)

        return .while(resolvedConditionExpr, resolvedBodyStmt)
    }

    mutating private func handleFor(initializerStmt: Statement<UnresolvedDepth>?,
                                    testExpr: Expression<UnresolvedDepth>,
                                    incrementExpr: Expression<UnresolvedDepth>?,
                                    bodyStmt: Statement<UnresolvedDepth>) throws -> Statement<Int> {
        let previousJumpableType = currentJumpableType
        currentJumpableType = .loop
        defer {
            currentJumpableType = previousJumpableType
        }

        beginScope()
        defer {
            endScope()
        }

        var resolvedInitializerStmt: Statement<Int>? = nil
        if let initializerStmt {
            resolvedInitializerStmt = try resolve(statement: initializerStmt)
        }

        let resolvedTestExpr = try resolve(expression: testExpr)

        var resolvedIncrementExpr: Expression<Int>? = nil
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
    mutating private func resolve(expression: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        switch expression {
        case .variable(let nameToken, _):
            return try handleVariable(nameToken: nameToken)
        case .assignment(let nameToken, let valueExpr, _):
            return try handleAssignment(nameToken: nameToken, valueExpr: valueExpr)
        case .binary(let leftExpr, let operToken, let rightExpr):
            return try handleBinary(leftExpr: leftExpr, operToken: operToken, rightExpr: rightExpr)
        case .unary(let operToken, let rightExpr):
            return try handleUnary(operToken: operToken, rightExpr: rightExpr)
        case .call(let calleeExpr, let rightParenToken, let args):
            return try handleCall(calleeExpr: calleeExpr, rightParenToken: rightParenToken, args: args)
        case .get(let locToken, let instanceExpr, let propertyNameToken):
            return try handleGet(locToken: locToken,
                                 instanceExpr: instanceExpr,
                                 propertyNameToken: propertyNameToken)
        case .set(let locToken, let instanceExpr, let propertyNameToken, let valueExpr):
            return try handleSet(locToken: locToken,
                                 instanceExpr: instanceExpr,
                                 propertyNameToken: propertyNameToken,
                                 valueExpr: valueExpr)
        case .this(let thisToken, _):
            return try handleThis(thisToken: thisToken)
        case .literal(let valueToken, let value):
            return .literal(valueToken, value)
        case .grouping(let expr):
            let resolvedExpr = try resolve(expression: expr)
            return .grouping(resolvedExpr)
        case .logical(let leftExpr, let operToken, let rightExpr):
            return try handleLogical(leftExpr: leftExpr, operToken: operToken, rightExpr: rightExpr)
        case .lambda(let locToken, let parameterList, let statements):
            return try handleLambda(locToken: locToken,
                                    parameterList: parameterList,
                                    statements: statements,
                                    functionType: .lambda)
        case .super(let superToken, let methodToken, _):
            return try handleSuper(superToken: superToken, methodToken: methodToken)
        case .string(let stringToken):
            return .string(stringToken)
        case .list(let elements):
            return try handleList(elements: elements)
        case .subscriptGet(let listExpr, let indexExpr):
            return try handleSubscriptGet(listExpr: listExpr, indexExpr: indexExpr)
        case .subscriptSet(let listExpr, let indexExpr, let valueExpr):
            return try handleSubscriptSet(listExpr: listExpr, indexExpr: indexExpr, valueExpr: valueExpr)
        case .splat(let starToken, let listExpr):
            return try handleSplat(starToken: starToken, listExpr: listExpr)
        case .dictionary(let kvPairs):
            return try handleDictionary(kvPairs: kvPairs)
        }
    }

    mutating private func handleVariable(nameToken: Token) throws -> Expression<Int> {
        if !scopeStack.isEmpty && scopeStack.lastMutable[nameToken.lexeme] == false {
            throw ResolverError.variableAccessedBeforeInitialization(nameToken)
        }

        let depth = getDepth(name: nameToken.lexeme)
        return .variable(nameToken, depth)
    }

    mutating private func handleAssignment(nameToken: Token, valueExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        let resolveValueExpr = try resolve(expression: valueExpr)
        let depth = getDepth(name: nameToken.lexeme)

        return .assignment(nameToken, resolveValueExpr, depth)
    }

    mutating private func handleBinary(leftExpr: Expression<UnresolvedDepth>,
                                       operToken: Token,
                                       rightExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        let resolvedLeftExpr = try resolve(expression: leftExpr)
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .binary(resolvedLeftExpr, operToken, resolvedRightExpr)
    }

    mutating private func handleUnary(operToken: Token,
                                      rightExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .unary(operToken, resolvedRightExpr)
    }

    mutating private func handleCall(calleeExpr: Expression<UnresolvedDepth>,
                                     rightParenToken: Token,
                                     args: [Expression<UnresolvedDepth>]) throws -> Expression<Int> {
        let previousArgumentListType = currentArgumentListType
        currentArgumentListType = .functionCall
        defer {
            currentArgumentListType = previousArgumentListType
        }

        let resolvedCalleeExpr = try resolve(expression: calleeExpr)

        let resolvedArgs = try args.map { arg in
            try resolve(expression: arg)
        }

        return .call(resolvedCalleeExpr, rightParenToken, resolvedArgs)
    }

    mutating private func handleGet(locToken: Token,
                                    instanceExpr: Expression<UnresolvedDepth>,
                                    propertyNameToken: Token) throws -> Expression<Int> {
        // Note that we don't attempt to resolve property names
        // because they are defined and looked up at _runtime_.
        let resolvedInstanceExpr = try resolve(expression: instanceExpr)

        return .get(locToken, resolvedInstanceExpr, propertyNameToken)
    }

    mutating private func handleSet(locToken: Token,
                                    instanceExpr: Expression<UnresolvedDepth>,
                                    propertyNameToken: Token,
                                    valueExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        // As with `get` expressions, we do _not_ try to
        // resolve property names.
        let resolvedInstanceExpr = try resolve(expression: instanceExpr)
        let resolvedValueExpr = try resolve(expression: valueExpr)

        return .set(locToken, resolvedInstanceExpr, propertyNameToken, resolvedValueExpr)
    }

    mutating private func handleThis(thisToken: Token) throws -> Expression<Int> {
        guard currentClassType != .none else {
            throw ResolverError.cannotReferenceThisOutsideClass(thisToken)
        }

        let depth = getDepth(name: thisToken.lexeme)
        return .this(thisToken, depth)
    }

    mutating private func handleLogical(leftExpr: Expression<UnresolvedDepth>,
                                        operToken: Token,
                                        rightExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        let resolvedLeftExpr = try resolve(expression: leftExpr)
        let resolvedRightExpr = try resolve(expression: rightExpr)

        return .logical(resolvedLeftExpr, operToken, resolvedRightExpr)
    }

    mutating private func handleLambda(locToken: Token,
                                       parameterList: ParameterList?,
                                       statements: [Statement<UnresolvedDepth>],
                                       functionType: FunctionType) throws -> Expression<Int> {
        beginScope()
        let previousFunctionType = currentFunctionType
        let previousLoopType = currentJumpableType
        currentFunctionType = functionType
        currentJumpableType = .none
        defer {
            endScope()
            currentFunctionType = previousFunctionType
            currentJumpableType = previousLoopType
        }

        if let parameterList {
            for param in parameterList.normalParameters {
                try declareVariable(variableToken: param)
                defineVariable(name: param.lexeme)
            }

            if let variadicParameter = parameterList.variadicParameter {
                try declareVariable(variableToken: variadicParameter)
                defineVariable(name: variadicParameter.lexeme)
            }
        } else if currentClassType == .none {
            throw ResolverError.functionsMustHaveAParameterList(locToken)
        }

        let resolvedStatements = try statements.map { statement in
            try resolve(statement: statement)
        }

        return .lambda(locToken, parameterList, resolvedStatements)
    }

    mutating private func handleSuper(superToken: Token, methodToken: Token) throws -> Expression<Int> {
        switch currentClassType {
        case .none:
            throw ResolverError.cannotReferenceSuperOutsideClass(superToken)
        case .class:
            throw ResolverError.cannotReferenceSuperWithoutSubclassing(superToken)
        default:
            break
        }

        let depth = getDepth(name: superToken.lexeme)
        return .super(superToken, methodToken, depth)
    }

    mutating private func handleList(elements: [Expression<UnresolvedDepth>]) throws -> Expression<Int> {
        let previousArgumentListType = currentArgumentListType
        currentArgumentListType = .listInitializer
        defer {
            currentArgumentListType = previousArgumentListType
        }

        let resolvedElements = try elements.map { element in
            return try resolve(expression: element)
        }

        return .list(resolvedElements)
    }

    mutating private func handleSubscriptGet(listExpr: Expression<UnresolvedDepth>,
                                             indexExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        let resolvedListExpr = try resolve(expression: listExpr)
        let resolvedIndexExpr = try resolve(expression: indexExpr)

        return .subscriptGet(resolvedListExpr, resolvedIndexExpr)
    }

    mutating private func handleSubscriptSet(listExpr: Expression<UnresolvedDepth>,
                                             indexExpr: Expression<UnresolvedDepth>,
                                             valueExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        let resolvedListExpr = try resolve(expression: listExpr)
        let resolvedIndexExpr = try resolve(expression: indexExpr)
        let resolvedValueExpr = try resolve(expression: valueExpr)

        return .subscriptSet(resolvedListExpr, resolvedIndexExpr, resolvedValueExpr)
    }

    mutating private func handleSplat(starToken: Token,
                                      listExpr: Expression<UnresolvedDepth>) throws -> Expression<Int> {
        if currentArgumentListType == .none {
            throw ResolverError.cannotUseSplatOperatorOutOfContext(starToken)
        }

        let resolvedListExpr = try resolve(expression: listExpr)

        return .splat(starToken, resolvedListExpr)
    }

    mutating private func handleDictionary(kvPairs: [(Expression<UnresolvedDepth>, Expression<UnresolvedDepth>)]) throws -> Expression<Int> {
        var resolvedKVPairs: [(Expression<Int>, Expression<Int>)] = []

        for (keyExpr, valueExpr) in kvPairs {
            let resolvedKey = try resolve(expression: keyExpr)
            let resolvedValue = try resolve(expression: valueExpr)
            resolvedKVPairs.append((resolvedKey, resolvedValue))
        }

        return .dictionary(resolvedKVPairs)
    }


    // Internal helpers
    mutating private func beginScope() {
        scopeStack.append([:])
    }

    mutating private func endScope() {
        scopeStack.removeLast()
    }

    mutating private func declareVariable(variableToken: Token) throws {
        // ACHTUNG!!! Only variables declared/defined in local
        // blocks are tracked by the resolver, which is why
        // we bail here since the stack is empty in the
        // global environment.
        if scopeStack.isEmpty {
            return
        }

        if scopeStack.lastMutable.keys.contains(variableToken.lexeme) {
            throw ResolverError.variableAlreadyDefined(variableToken)
        }

        scopeStack.lastMutable[variableToken.lexeme] = false
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
