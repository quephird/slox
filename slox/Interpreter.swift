//
//  Interpreter.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

class Interpreter {
    var environment: Environment = Environment()

    init() {
        setUpGlobals()
    }

    private func prepareCode(source: String) throws -> [Statement<Int>] {
        var scanner = Scanner(source: source)
        let tokens = try scanner.scanTokens()
        var parser = Parser(tokens: tokens)
        let statements = try parser.parse()
        var resolver = Resolver()

        return try resolver.resolve(statements: statements)
    }

    private func setUpGlobals() {
        for nativeFunction in NativeFunction.allCases {
            environment.define(name: String(describing: nativeFunction),
                               value: .nativeFunction(nativeFunction))
        }

        try! interpret(source: standardLibrary)
    }

    func interpret(source: String) throws {
        let statements = try prepareCode(source: source)

        for statement in statements {
            try execute(statement: statement)
        }
    }

    func interpretRepl(source: String) throws -> LoxValue? {
        let statements = try prepareCode(source: source)

        for (i, statement) in statements.enumerated() {
            if i == statements.endIndex-1, case .expression(let expr) = statement {
                return try evaluate(expr: expr)
            } else {
                try execute(statement: statement)
            }
        }

        return nil
    }

    func execute(statement: Statement<Int>) throws {
        switch statement {
        case .expression(let expr):
            let _ = try evaluate(expr: expr)
        case .if(_, let testExpr, let consequentStmt, let alternativeStmt):
            try handleIfStatement(testExpr: testExpr,
                                  consequentStmt: consequentStmt,
                                  alternativeStmt: alternativeStmt)
        case .switch(_, let testExpr, let switchCaseDecls):
            try handleSwitchStatement(testExpr: testExpr,
                                      switchCaseDecls: switchCaseDecls)
        case .print(_, let expr):
            try handlePrintStatement(expr: expr)
        case .variableDeclaration(let name, let expr):
            try handleVariableDeclaration(name: name, expr: expr)
        case .block(_, let statements):
            try handleBlock(statements: statements)
        case .while(_, let expr, let stmt):
            try handleWhileStatement(expr: expr, stmt: stmt)
        case .for(_, let initializerStmt, let testExpr, let incrementExpr, let bodyStmt):
            try handleForStatement(initializerStmt: initializerStmt,
                                   testExpr: testExpr,
                                   incrementExpr: incrementExpr,
                                   bodyStmt: bodyStmt)
        case .class(let nameToken, let superclassExpr, let methods):
            try handleClassDeclaration(nameToken: nameToken,
                                       superclassExpr: superclassExpr,
                                       methods: methods)
        case .enum(let nameToken, let caseTokens, let methods):
            try handleEnumDeclaration(nameToken: nameToken,
                                      caseTokens: caseTokens,
                                      methods: methods)
        case .function(let name, let modifierTokens, let lambda):
            try handleFunctionDeclaration(name: name, modifierTokens: modifierTokens, lambda: lambda)
        case .return(let returnToken, let expr):
            try handleReturnStatement(returnToken: returnToken, expr: expr)
        case .break(let breakToken):
            try handleBreakStatement(breakToken: breakToken)
        case .continue(let continueToken):
            try handleContinueStatement(continueToken: continueToken)
        }
    }

    private func handleIfStatement(testExpr: Expression<Int>,
                                   consequentStmt: Statement<Int>,
                                   alternativeStmt: Statement<Int>?) throws {
        let value = try evaluate(expr: testExpr)

        if value.isTruthy {
            try execute(statement: consequentStmt)
        } else if let alternativeStmt {
            try execute(statement: alternativeStmt)
        }
    }

    private func handleSwitchStatement(testExpr: Expression<Int>,
                                       switchCaseDecls: [SwitchCaseDeclaration<Int>]) throws {
        let testValue = try evaluate(expr: testExpr)

        for switchCaseDecl in switchCaseDecls {
            let caseValues = try switchCaseDecl.valueExpressions?.map { valueExpr in
                try evaluate(expr: valueExpr)
            }

            if caseValues?.contains(testValue) ?? true {
                do {
                    try execute(statement: switchCaseDecl.statement)
                } catch JumpType.break {
                    break
                }

                return
            }
        }
    }

    private func handlePrintStatement(expr: Expression<Int>) throws {
        let literal = try evaluate(expr: expr)
        print(literal)
    }

    private func handleClassDeclaration(nameToken: Token,
                                        superclassExpr: Expression<Int>?,
                                        methods: [Statement<Int>]) throws {
        // NOTA BENE: We temporarily set the initial value associated with
        // the class name to `.nil` so that, according to the book,
        // "allows references to the class inside its own methods".
        environment.define(name: nameToken.lexeme, value: .nil)

        let superclass = try superclassExpr.map { superclassExpr in
            guard case .instance(let superclass as LoxClass) = try evaluate(expr: superclassExpr),
                  !(superclass is LoxEnum) else {
                throw RuntimeError.superclassMustBeAClass(superclassExpr.locToken)
            }

            environment = Environment(enclosingEnvironment: environment);
            environment.define(name: "super", value: .instance(superclass));

            return superclass
        }

        var methodsCopy = methods
        let partIndex = methodsCopy.partition(by: { method in
            guard case .function(_, let modifierTokens, _) = method else {
                fatalError("expected function declaration in class")
            }

            return modifierTokens.contains(where: { token in
                token.lexeme == "class"
            })
        })
        let instanceMethodLookup = try makeMethodLookup(methodDecls: Array(methodsCopy[0..<partIndex]))
        let staticMethodLookup = try makeMethodLookup(methodDecls: Array(methodsCopy[partIndex...]))

        let newClass = LoxClass(name: nameToken.lexeme,
                                superclass: superclass,
                                methods: instanceMethodLookup)
        if !staticMethodLookup.isEmpty {
            // NOTA BENE: This assigns the static methods to the metaclass,
            // which is lazily created in `LoxInstance`
            newClass.klass.methods = staticMethodLookup
        }

        // Note that we can't accomplish this via a defer block because we need
        // to assign the class to the _outermost_ environment, not the enclosing one.
        if superclassExpr != nil {
            environment = environment.enclosingEnvironment!
        }

        try environment.assignAtDepth(nameToken: nameToken, value: .instance(newClass), depth: 0)
    }

    private func handleEnumDeclaration(nameToken: Token,
                                       caseTokens: [Token],
                                       methods: [Statement<Int>]) throws {
        let enumSuperclass = lookUpStandardLibraryClass(named: "Enum")
        let enumClass = LoxEnum(name: nameToken.lexeme,
                                superclass: enumSuperclass,
                                methods: [:])

        for caseToken in caseTokens {
            let caseInstance = LoxInstance(klass: enumClass)
            caseInstance.properties["name"] = try makeString(string: caseToken.lexeme)
            enumClass.properties[caseToken.lexeme] = .instance(caseInstance)
        }

        var methodsCopy = methods
        let partIndex = methodsCopy.partition(by: { method in
            guard case .function(_, let modifierTokens, _) = method else {
                fatalError("expected function declaration in class")
            }

            return modifierTokens.contains(where: { token in
                token.lexeme == "class"
            })
        })
        let instanceMethodLookup = try makeMethodLookup(methodDecls: Array(methodsCopy[0..<partIndex]))
        let staticMethodLookup = try makeMethodLookup(methodDecls: Array(methodsCopy[partIndex...]))

        enumClass.methods = instanceMethodLookup
        if !staticMethodLookup.isEmpty {
            enumClass.klass.methods = staticMethodLookup
        }

        environment.define(name: nameToken.lexeme, value: .instance(enumClass))
    }

    private func handleFunctionDeclaration(name: Token, modifierTokens: [Token], lambda: Expression<Int>) throws {
        guard case .lambda(_, let parameterList, let body) = lambda else {
            fatalError("Fatal error: expected lambda as body of function declaration")
        }

        let environmentWhenDeclared = self.environment
        let function = UserDefinedFunction(name: name.lexeme,
                                           parameterList: parameterList,
                                           enclosingEnvironment: environmentWhenDeclared,
                                           body: body,
                                           isInitializer: false,
                                           isPrivate: false)
        environment.define(name: name.lexeme, value: .userDefinedFunction(function))
    }

    private func handleReturnStatement(returnToken: Token, expr: Expression<Int>?) throws {
        var value: LoxValue = .nil
        if let expr {
            value = try evaluate(expr: expr)
        }

        throw JumpType.return(value)
    }

    private func handleBreakStatement(breakToken: Token) throws {
        throw JumpType.break
    }

    private func handleContinueStatement(continueToken: Token) throws {
        throw JumpType.continue
    }

    private func handleVariableDeclaration(name: Token, expr: Expression<Int>?) throws {
        var value: LoxValue = .nil
        if let expr = expr {
            value = try evaluate(expr: expr)
        }

        environment.define(name: name.lexeme, value: value)
    }

    func handleBlock(statements: [Statement<Int>]) throws {
        let environmentBeforeBlock = self.environment
        self.environment = Environment(enclosingEnvironment: environmentBeforeBlock)

        // This ensures that the previous environment is restored
        // if the try below throws, which is what will happen if
        // there is a return statement.
        defer {
            self.environment = environmentBeforeBlock
        }

        for statement in statements {
            try execute(statement: statement)
        }
    }

    private func handleWhileStatement(expr: Expression<Int>, stmt: Statement<Int>) throws {
        while try evaluate(expr: expr).isTruthy {
            do {
                try execute(statement: stmt)
            } catch JumpType.break {
                break
            } catch JumpType.continue {
                continue
            }
        }
    }

    private func handleForStatement(initializerStmt: Statement<Int>?,
                                    testExpr: Expression<Int>,
                                    incrementExpr: Expression<Int>?,
                                    bodyStmt: Statement<Int>) throws {
        let environmentBeforeBlock = self.environment
        self.environment = Environment(enclosingEnvironment: environmentBeforeBlock)

        defer {
            self.environment = environmentBeforeBlock
        }

        if let initializerStmt {
            try execute(statement: initializerStmt)
        }

        while try evaluate(expr: testExpr).isTruthy {
            do {
                try execute(statement: bodyStmt)
            } catch JumpType.break {
                break
            } catch JumpType.continue {
                if let incrementExpr {
                    _ = try evaluate(expr: incrementExpr)
                }
                continue
            }

            if let incrementExpr {
                _ = try evaluate(expr: incrementExpr)
            }
        }
    }

    private func evaluate(expr: Expression<Int>) throws -> LoxValue {
        switch expr {
        case .literal(_, let literal):
            return literal
        case .grouping(_, let expr):
            return try evaluate(expr: expr)
        case .unary(let oper, let expr):
            return try handleUnaryExpression(oper: oper, expr: expr)
        case .binary(let leftExpr, let oper, let rightExpr):
            return try handleBinaryExpression(leftExpr: leftExpr, oper: oper, rightExpr: rightExpr)
        case .variable(let varToken, let depth):
            return try handleVariableExpression(varToken: varToken, depth: depth)
        case .assignment(let varToken, let valueExpr, let depth):
            return try handleAssignmentExpression(name: varToken, expr: valueExpr, depth: depth)
        case .logical(let leftExpr, let oper, let rightExpr):
            return try handleLogicalExpression(leftExpr: leftExpr, oper: oper, rightExpr: rightExpr)
        case .call(let calleeExpr, let rightParen, let args):
            return try handleCallExpression(calleeExpr: calleeExpr, rightParen: rightParen, args: args)
        case .get(let locToken, let instanceExpr, let propertyNameToken):
            return try handleGetExpression(locToken: locToken,
                                           instanceExpr: instanceExpr,
                                           propertyNameToken: propertyNameToken)
        case .set(let locToken, let instanceExpr, let propertyNameToken, let valueExpr):
            return try handleSetExpression(locToken: locToken,
                                           instanceExpr: instanceExpr,
                                           propertyNameToken: propertyNameToken,
                                           valueExpr: valueExpr)
        case .this(let thisToken, let depth):
            return try handleThis(thisToken: thisToken, depth: depth)
        case .lambda(_, let parameterList, let body):
            return try handleLambdaExpression(parameterList: parameterList, body: body)
        case .super(let superToken, let methodToken, let depth):
            return try handleSuperExpression(superToken: superToken, methodToken: methodToken, depth: depth)
        case .string(let stringToken):
            return try handleStringExpression(stringToken: stringToken)
        case .list(_, let elements):
            return try handleListExpression(elements: elements)
        case .subscriptGet(_, let listExpr, let indexExpr):
            return try handleSubscriptGetExpression(collectionExpr: listExpr, indexExpr: indexExpr)
        case .subscriptSet(_, let listExpr, let indexExpr, let valueExpr):
            return try handleSubscriptSetExpression(collectionExpr: listExpr,
                                                    indexExpr: indexExpr,
                                                    valueExpr: valueExpr)
        case .splat(_, let listExpr):
            return try handleSplatExpression(listExpr: listExpr)
        case .dictionary(_, let kvPairs):
            return try handleDictionary(kvExprPairs: kvPairs)
        }
    }

    private func handleUnaryExpression(oper: Token, expr: Expression<Int>) throws -> LoxValue {
        let value = try evaluate(expr: expr)

        switch oper.type {
        case .minus:
            switch value {
            case .double(let number):
                return .double(-number)
            case .int(let number):
                return .int(-number)
            default:
                throw RuntimeError.unaryOperandMustBeNumber(oper)
            }
        case .bang:
            return .boolean(!value.isTruthy)
        default:
            throw RuntimeError.unsupportedUnaryOperator(oper)
        }
    }

    private func handleBinaryExpression(leftExpr: Expression<Int>,
                                        oper: Token,
                                        rightExpr: Expression<Int>) throws -> LoxValue {
        let leftValue = try evaluate(expr: leftExpr)
        let rightValue = try evaluate(expr: rightExpr)

        switch (leftValue, rightValue) {
        case (.int(let leftNumber), .int(let rightNumber)):
            switch oper.type {
            case .plus:
                return .int(leftNumber + rightNumber)
            case .minus:
                return .int(leftNumber - rightNumber)
            case .star:
                return .int(leftNumber * rightNumber)
            case .slash:
                return .int(leftNumber / rightNumber)
            case .modulus:
                return .int(leftNumber % rightNumber)
            case .greater:
                return .boolean(leftNumber > rightNumber)
            case .greaterEqual:
                return .boolean(leftNumber >= rightNumber)
            case .less:
                return .boolean(leftNumber < rightNumber)
            case .lessEqual:
                return .boolean(leftNumber <= rightNumber)
            default:
                break
            }
        case (.int, .double), (.double, .int), (.double, .double):
            let leftNumber = try leftValue.convertToRawDouble()
            let rightNumber = try rightValue.convertToRawDouble()

            switch oper.type {
            case .plus:
                return .double(leftNumber + rightNumber)
            case .minus:
                return .double(leftNumber - rightNumber)
            case .star:
                return .double(leftNumber * rightNumber)
            case .slash:
                return .double(leftNumber / rightNumber)
            case .greater:
                return .boolean(leftNumber > rightNumber)
            case .greaterEqual:
                return .boolean(leftNumber >= rightNumber)
            case .less:
                return .boolean(leftNumber < rightNumber)
            case .lessEqual:
                return .boolean(leftNumber <= rightNumber)
            default:
                break
            }
        case (.instance(let leftString as LoxString), .instance(let rightString as LoxString)):
            switch oper.type {
            case .plus:
                return try makeString(string: leftString.string + rightString.string)
            default:
                break
            }
        case (.instance(let leftList as LoxList), .instance(let rightList as LoxList)):
            switch oper.type {
            case .plus:
                let newElements = leftList.elements + rightList.elements
                return try makeList(elements: newElements)
            default:
                break
            }
        default:
            break
        }

        switch oper.type {
        case .bangEqual:
            return .boolean(!leftValue.isEqual(to: rightValue))
        case .equalEqual:
            return .boolean(leftValue.isEqual(to: rightValue))
        case .plus:
            throw RuntimeError.binaryOperandsMustBeNumbersOrStringsOrLists(oper)
        case .minus, .star, .slash, .greater, .greaterEqual, .less, .lessEqual:
            throw RuntimeError.binaryOperandsMustBeNumbers(oper)
        default:
            throw RuntimeError.unsupportedBinaryOperator(oper)
        }
    }

    private func handleVariableExpression(varToken: Token, depth: Int) throws -> LoxValue {
        return try environment.getValueAtDepth(nameToken: varToken, depth: depth)
    }

    private func handleAssignmentExpression(name: Token,
                                            expr: Expression<Int>,
                                            depth: Int) throws -> LoxValue {
        let value = try evaluate(expr: expr)
        try environment.assignAtDepth(nameToken: name, value: value, depth: depth)
        return value
    }

    private func handleLogicalExpression(leftExpr: Expression<Int>,
                                         oper: Token,
                                         rightExpr: Expression<Int>) throws -> LoxValue {
        let leftValue = try evaluate(expr: leftExpr)

        if case .and = oper.type {
            if !leftValue.isTruthy {
                return leftValue
            } else {
                return try evaluate(expr: rightExpr)
            }
        } else {
            if leftValue.isTruthy {
                return leftValue
            } else {
                return try evaluate(expr: rightExpr)
            }
        }
    }

    private func handleCallExpression(calleeExpr: Expression<Int>,
                                      rightParen: Token,
                                      args: [Expression<Int>]) throws -> LoxValue {
        let callee = try evaluate(expr: calleeExpr)

        let actualCallable: LoxCallable = switch callee {
        case .userDefinedFunction(let userDefinedFunction):
            userDefinedFunction
        case .nativeFunction(let nativeFunction):
            nativeFunction
        case .instance(let klass as LoxClass):
            klass
        default:
            throw RuntimeError.notACallableObject(calleeExpr.locToken)
        }

        let argValues = try evaluateAndFlatten(exprs: args)

        guard let parameterList = actualCallable.parameterList else {
            fatalError()
        }
        if !parameterList.checkArity(argCount: argValues.count) {
            throw RuntimeError.wrongArity(calleeExpr.locToken,
                                          parameterList.normalParameters.count,
                                          argValues.count)
        }

        do {
            return try actualCallable.call(interpreter: self, args: argValues)
        } catch let error as RuntimeError {
            let nameToken = if case .get(_, _, let name) = calleeExpr {
                name
            } else {
                calleeExpr.locToken // Correct for variables; best guess otherwise
            }

            throw RuntimeError.errorInCall(error, nameToken)
        }
    }

    private func handleGetExpression(locToken: Token,
                                     instanceExpr: Expression<Int>,
                                     propertyNameToken: Token) throws -> LoxValue {
        guard case .instance(let instance) = try evaluate(expr: instanceExpr) else {
            throw RuntimeError.onlyInstancesHaveProperties(instanceExpr.locToken)
        }

        let property = try instance.get(propertyName: propertyNameToken, includePrivate: instanceExpr.isThis)

        if case .userDefinedFunction(let userDefinedFunction) = property,
           userDefinedFunction.isComputedProperty {
            return try userDefinedFunction.call(interpreter: self, args: [])
        }

        return property
    }

    private func handleSetExpression(locToken: Token,
                                     instanceExpr: Expression<Int>,
                                     propertyNameToken: Token,
                                     valueExpr: Expression<Int>) throws -> LoxValue {
        guard case .instance(let instance) = try evaluate(expr: instanceExpr) else {
            throw RuntimeError.onlyInstancesHaveProperties(locToken)
        }

        let propertyValue = try evaluate(expr: valueExpr)

        try instance.set(propertyName: propertyNameToken, propertyValue: propertyValue)
        return propertyValue
    }

    private func handleThis(thisToken: Token, depth: Int) throws -> LoxValue {
        return try environment.getValueAtDepth(nameToken: thisToken, depth: depth)
    }

    private func handleLambdaExpression(parameterList: ParameterList?, body: Statement<Int>) throws -> LoxValue {
        let environmentWhenDeclared = self.environment

        let function = UserDefinedFunction(name: "lambda",
                                           parameterList: parameterList,
                                           enclosingEnvironment: environmentWhenDeclared,
                                           body: body,
                                           isInitializer: false,
                                           isPrivate: false)

        return .userDefinedFunction(function)
    }

    private func handleSuperExpression(superToken: Token, methodToken: Token, depth: Int) throws -> LoxValue {
        guard case .instance(let superclass as LoxClass) = try environment.getValueAtDepth(nameToken: superToken, depth: depth) else {
            fatalError("unable to find superclass at depth, \(depth)")
        }

        let dummyThisToken = Token(type: .identifier, lexeme: "this", line: 0)
        guard case .instance(let thisInstance)? = try? environment.getValueAtDepth(nameToken: dummyThisToken, depth: depth - 1) else {
            fatalError("unable to resolve `this` at depth, \(depth - 1)")
        }

        if let method = superclass.findMethod(name: methodToken.lexeme, includePrivate: true) {
            return .userDefinedFunction(method.bind(instance: thisInstance))
        }

        throw RuntimeError.undefinedProperty(methodToken)
    }

    private func handleStringExpression(stringToken: Token) throws -> LoxValue {
        let stringValue = String(stringToken.lexeme.dropFirst().dropLast())

        return try makeString(string: stringValue)
    }

    private func handleListExpression(elements: [Expression<Int>]) throws -> LoxValue {
        let elementValues = try evaluateAndFlatten(exprs: elements)

        return try makeList(elements: elementValues)
    }

    private func handleSubscriptGetExpression(collectionExpr: Expression<Int>,
                                              indexExpr: Expression<Int>) throws -> LoxValue {
        let collection = try evaluate(expr: collectionExpr)

        switch collection {
        case .instance(let list as LoxList):
            guard case .int(let index) = try evaluate(expr: indexExpr) else {
                throw RuntimeError.indexMustBeAnInteger(indexExpr.locToken)
            }

            return list[index]
        case .instance(let dictionary as LoxDictionary):
            let key = try evaluate(expr: indexExpr)

            return dictionary[key]
        default:
            throw RuntimeError.notAListOrDictionary(collectionExpr.locToken)
        }
    }

    private func handleSubscriptSetExpression(collectionExpr: Expression<Int>,
                                              indexExpr: Expression<Int>,
                                              valueExpr: Expression<Int>) throws -> LoxValue {
        let collection = try evaluate(expr: collectionExpr)
        let value = try evaluate(expr: valueExpr)

        switch collection {
        case .instance(let list as LoxList):
            guard case .int(let index) = try evaluate(expr: indexExpr) else {
                throw RuntimeError.indexMustBeAnInteger(indexExpr.locToken)
            }

            list[Int(index)] = value
        case .instance(let dictionary as LoxDictionary):
            let key = try evaluate(expr: indexExpr)

            dictionary[key] = value
        default:
            throw RuntimeError.notAListOrDictionary(collectionExpr.locToken)
        }

        return value
    }

    private func handleSplatExpression(listExpr: Expression<Int>) throws -> LoxValue {
        return try evaluate(expr: listExpr)
    }

    private func handleDictionary(kvExprPairs: [(Expression<Int>, Expression<Int>)]) throws -> LoxValue {
        var kvPairs: [LoxValue: LoxValue] = [:]

        for (keyExpr, valueExpr) in kvExprPairs {
            let key = try evaluate(expr: keyExpr)
            let value = try evaluate(expr: valueExpr)
            kvPairs[key] = value
        }

        let dictionaryClass = lookUpStandardLibraryClass(named: "Dictionary")
        let dictionary = LoxDictionary(kvPairs: kvPairs, klass: dictionaryClass)

        return .instance(dictionary)
    }

    // Utility functions
    private func makeMethodLookup(methodDecls: [Statement<Int>]) throws -> [String: UserDefinedFunction] {
        return methodDecls.reduce(into: [:]) { lookup, methodDecl in
            guard case .function(let nameToken, let modifierTokens, let lambdaExpr) = methodDecl else {
                fatalError("Fatal error: expected function declaration in class")
            }

            guard case .lambda(_, let parameterList, let methodBody) = lambdaExpr else {
                fatalError("Fatal error: expected lambda as body of function declaration")
            }

            let isInitializer = nameToken.lexeme == "init"
            let isPrivate = modifierTokens.contains(where: { token in
                token.type == .private
            })
            let method = UserDefinedFunction(name: nameToken.lexeme,
                                             parameterList: parameterList,
                                             enclosingEnvironment: environment,
                                             body: methodBody,
                                             isInitializer: isInitializer,
                                             isPrivate: isPrivate)
            lookup[nameToken.lexeme] = method
        }
    }

    private func evaluateAndFlatten(exprs: [Expression<Int>]) throws -> [LoxValue] {
        let values = try exprs.flatMap { expr in
            if case .splat = expr {
                guard case .instance(let list as LoxList) = try evaluate(expr: expr) else {
                    throw RuntimeError.notAList(expr.locToken)
                }
                return list.elements
            } else {
                let elementValue = try evaluate(expr: expr)
                return [elementValue]
            }
        }

        return values
    }

    private func lookUpStandardLibraryClass(named name: String) -> LoxClass {
        let dummyToken = Token(type: .identifier, lexeme: name, line: 0)
        guard case .instance(let klass as LoxClass)? = try? environment.getValue(nameToken: dummyToken) else {
            fatalError("no class '\(name)' found in standard library")
        }

        return klass
    }

    func makeString(string: String) throws -> LoxValue {
        let stringClass = lookUpStandardLibraryClass(named: "String")
        let list = LoxString(string: string, klass: stringClass)

        return .instance(list)
    }

    func makeList(elements: [LoxValue]) throws -> LoxValue {
        let listClass = lookUpStandardLibraryClass(named: "List")
        let list = LoxList(elements: elements, klass: listClass)

        return .instance(list)
    }

    func makeDictionary(kvPairs: [LoxValue: LoxValue]) throws -> LoxValue {
        let dictionaryClass = lookUpStandardLibraryClass(named: "Dictionary")
        let dictionary = LoxDictionary(kvPairs: kvPairs, klass: dictionaryClass)

        return .instance(dictionary)
    }
}
