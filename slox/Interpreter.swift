//
//  Interpreter.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

class Interpreter {
    static let standardLibrary = """
        class List {
            append(element) {
                appendNative(this, element);
            }

            deleteAt(index) {
                return deleteAtNative(this, index);
            }
        }
"""
    var environment: Environment = Environment()

    init() {
        setUpGlobals()
    }

    private func prepareCode(source: String) throws -> [ResolvedStatement] {
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

        try! interpret(source: Self.standardLibrary)
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

    private func execute(statement: ResolvedStatement) throws {
        switch statement {
        case .expression(let expr):
            let _ = try evaluate(expr: expr)
        case .if(let testExpr, let consequentStmt, let alternativeStmt):
            try handleIfStatement(testExpr: testExpr,
                                  consequentStmt: consequentStmt,
                                  alternativeStmt: alternativeStmt)
        case .print(let expr):
            try handlePrintStatement(expr: expr)
        case .variableDeclaration(let name, let expr):
            try handleVariableDeclaration(name: name, expr: expr)
        case .block(let statements):
            try handleBlock(statements: statements,
                            environment: Environment(enclosingEnvironment: environment))
        case .while(let expr, let stmt):
            try handleWhileStatement(expr: expr, stmt: stmt)
        case .for(let initializerStmt, let testExpr, let incrementExpr, let bodyStmt):
            try handleForStatement(initializerStmt: initializerStmt,
                                   testExpr: testExpr,
                                   incrementExpr: incrementExpr,
                                   bodyStmt: bodyStmt)
        case .class(let nameToken, let superclassExpr, let methods, let staticMethods):
            try handleClassDeclaration(nameToken: nameToken,
                                       superclassExpr: superclassExpr,
                                       methods: methods,
                                       staticMethods: staticMethods)
        case .function(let name, let lambda):
            try handleFunctionDeclaration(name: name, lambda: lambda)
        case .return(let returnToken, let expr):
            try handleReturnStatement(returnToken: returnToken, expr: expr)
        case .break(let breakToken):
            try handleBreakStatement(breakToken: breakToken)
        case .continue(let continueToken):
            try handleContinueStatement(continueToken: continueToken)
        }
    }

    private func handleIfStatement(testExpr: ResolvedExpression,
                                   consequentStmt: ResolvedStatement,
                                   alternativeStmt: ResolvedStatement?) throws {
        let value = try evaluate(expr: testExpr)

        if value.isTruthy {
            try execute(statement: consequentStmt)
        } else if let alternativeStmt {
            try execute(statement: alternativeStmt)
        }
    }

    private func handlePrintStatement(expr: ResolvedExpression) throws {
        let literal = try evaluate(expr: expr)
        print(literal)
    }

    private func handleClassDeclaration(nameToken: Token,
                                        superclassExpr: ResolvedExpression?,
                                        methods: [ResolvedStatement],
                                        staticMethods: [ResolvedStatement]) throws {
        // NOTA BENE: We temporarily set the initial value associated with
        // the class name to `.nil` so that, according to the book,
        // "allows references to the class inside its own methods".
        environment.define(name: nameToken.lexeme, value: .nil)

        let superclass = try superclassExpr.map { superclassExpr in
            guard case .instance(let superclass as LoxClass) = try evaluate(expr: superclassExpr) else {
                throw RuntimeError.superclassMustBeAClass
            }

            environment = Environment(enclosingEnvironment: environment);
            environment.define(name: "super", value: .instance(superclass));

            return superclass
        }

        var methodImpls: [String: UserDefinedFunction] = [:]
        for method in methods {
            guard case .function(let nameToken, let lambdaExpr) = method else {
                throw RuntimeError.notAFunctionDeclaration
            }

            guard case .lambda(let paramTokens, let methodBody) = lambdaExpr else {
                throw RuntimeError.notALambda
            }

            let isInitializer = nameToken.lexeme == "init"
            let methodImpl = UserDefinedFunction(name: nameToken.lexeme,
                                                 params: paramTokens,
                                                 enclosingEnvironment: environment,
                                                 body: methodBody,
                                                 isInitializer: isInitializer)
            methodImpls[nameToken.lexeme] = methodImpl
        }

        var staticMethodImpls: [String: UserDefinedFunction] = [:]
        for staticMethod in staticMethods {
            guard case .function(let nameToken, let lambdaExpr) = staticMethod else {
                throw RuntimeError.notAFunctionDeclaration
            }

            guard case .lambda(let paramTokens, let methodBody) = lambdaExpr else {
                throw RuntimeError.notALambda
            }

            let staticMethodImpl = UserDefinedFunction(name: nameToken.lexeme,
                                                       params: paramTokens,
                                                       enclosingEnvironment: environment,
                                                       body: methodBody,
                                                       isInitializer: false)
            staticMethodImpls[nameToken.lexeme] = staticMethodImpl
        }

        let newClass = LoxClass(name: nameToken.lexeme,
                                superclass: superclass,
                                methods: methodImpls)
        if !staticMethodImpls.isEmpty {
            // NOTA BENE: This assigns the static methods to the metaclass,
            // which is lazily created in `LoxInstance`
            newClass.klass.methods = staticMethodImpls
        }

        // Note that we can't accomplish this via a defer block because we need
        // to assign the class to the _outermost_ environment, not the enclosing one.
        if superclassExpr != nil {
            environment = environment.enclosingEnvironment!
        }

        try environment.assignAtDepth(name: nameToken.lexeme, value: .instance(newClass), depth: 0)
    }

    private func handleFunctionDeclaration(name: Token, lambda: ResolvedExpression) throws {
        guard case .lambda(let params, let body) = lambda else {
            throw RuntimeError.notALambda
        }

        let environmentWhenDeclared = self.environment
        let function = UserDefinedFunction(name: name.lexeme,
                                           params: params,
                                           enclosingEnvironment: environmentWhenDeclared,
                                           body: body,
                                           isInitializer: false)
        environment.define(name: name.lexeme, value: .userDefinedFunction(function))
    }

    private func handleReturnStatement(returnToken: Token, expr: ResolvedExpression?) throws {
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

    private func handleVariableDeclaration(name: Token, expr: ResolvedExpression?) throws {
        var value: LoxValue = .nil
        if let expr = expr {
            value = try evaluate(expr: expr)
        }

        environment.define(name: name.lexeme, value: value)
    }

    func handleBlock(statements: [ResolvedStatement], environment: Environment) throws {
        let environmentBeforeBlock = self.environment
        self.environment = environment

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

    private func handleWhileStatement(expr: ResolvedExpression, stmt: ResolvedStatement) throws {
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

    private func handleForStatement(initializerStmt: ResolvedStatement?,
                                    testExpr: ResolvedExpression,
                                    incrementExpr: ResolvedExpression?,
                                    bodyStmt: ResolvedStatement) throws {
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

    private func evaluate(expr: ResolvedExpression) throws -> LoxValue {
        switch expr {
        case .literal(let literal):
            return literal
        case .grouping(let expr):
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
        case .get(let instanceExpr, let propertyNameToken):
            return try handleGetExpression(instanceExpr: instanceExpr, propertyNameToken: propertyNameToken)
        case .set(let instanceExpr, let propertyNameToken, let valueExpr):
            return try handleSetExpression(instanceExpr: instanceExpr,
                                           propertyNameToken: propertyNameToken,
                                           valueExpr: valueExpr)
        case .this(let thisToken, let depth):
            return try handleThis(thisToken: thisToken, depth: depth)
        case .lambda(let params, let statements):
            return try handleLambdaExpression(params: params, statements: statements)
        case .super(let superToken, let methodToken, let depth):
            return try handleSuperExpression(superToken: superToken, methodToken: methodToken, depth: depth)
        case .list(let elements):
            return try handleListExpression(elements: elements)
        case .subscriptGet(let listExpr, let indexExpr):
            return try handleSubscriptGetExpression(listExpr: listExpr, indexExpr: indexExpr)
        case .subscriptSet(let listExpr, let indexExpr, let valueExpr):
            return try handleSubscriptSetExpression(listExpr: listExpr,
                                                    indexExpr: indexExpr,
                                                    valueExpr: valueExpr)
        }
    }

    private func handleUnaryExpression(oper: Token, expr: ResolvedExpression) throws -> LoxValue {
        let value = try evaluate(expr: expr)

        switch oper.type {
        case .minus:
            switch value {
            case .double(let number):
                return .double(-number)
            case .int(let number):
                return .int(-number)
            default:
                throw RuntimeError.unaryOperandMustBeNumber
            }
        case .bang:
            return .boolean(!value.isTruthy)
        default:
            throw RuntimeError.unsupportedUnaryOperator
        }
    }

    private func handleBinaryExpression(leftExpr: ResolvedExpression,
                                        oper: Token,
                                        rightExpr: ResolvedExpression) throws -> LoxValue {
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
        case (.string(let leftString), .string(let rightString)):
            switch oper.type {
            case .plus:
                return .string(leftString + rightString)
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
            throw RuntimeError.binaryOperandsMustBeNumbersOrStringsOrLists
        case .minus, .star, .slash, .greater, .greaterEqual, .less, .lessEqual:
            throw RuntimeError.binaryOperandsMustBeNumbers
        default:
            throw RuntimeError.unsupportedBinaryOperator
        }
    }

    private func handleVariableExpression(varToken: Token, depth: Int) throws -> LoxValue {
        return try environment.getValueAtDepth(name: varToken.lexeme, depth: depth)
    }

    private func handleAssignmentExpression(name: Token,
                                            expr: ResolvedExpression,
                                            depth: Int) throws -> LoxValue {
        let value = try evaluate(expr: expr)
        try environment.assignAtDepth(name: name.lexeme, value: value, depth: depth)
        return value
    }

    private func handleLogicalExpression(leftExpr: ResolvedExpression,
                                         oper: Token,
                                         rightExpr: ResolvedExpression) throws -> LoxValue {
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

    private func handleCallExpression(calleeExpr: ResolvedExpression,
                                      rightParen: Token,
                                      args: [ResolvedExpression]) throws -> LoxValue {
        let callee = try evaluate(expr: calleeExpr)

        let actualCallable: LoxCallable = switch callee {
        case .userDefinedFunction(let userDefinedFunction):
            userDefinedFunction
        case .nativeFunction(let nativeFunction):
            nativeFunction
        case .instance(let klass as LoxClass):
            klass
        default:
            throw RuntimeError.notACallableObject
        }

        guard args.count == actualCallable.arity else {
            throw RuntimeError.wrongArity(actualCallable.arity, args.count)
        }

        var argValues: [LoxValue] = []
        for arg in args {
            let argValue = try evaluate(expr: arg)
            argValues.append(argValue)
        }

        return try actualCallable.call(interpreter: self, args: argValues)
    }

    private func handleGetExpression(instanceExpr: ResolvedExpression,
                                     propertyNameToken: Token) throws -> LoxValue {
        guard case .instance(let instance) = try evaluate(expr: instanceExpr) else {
            throw RuntimeError.onlyInstancesHaveProperties
        }

        return try instance.get(propertyName: propertyNameToken.lexeme)
    }

    private func handleSetExpression(instanceExpr: ResolvedExpression,
                                     propertyNameToken: Token,
                                     valueExpr: ResolvedExpression) throws -> LoxValue {
        guard case .instance(let instance) = try evaluate(expr: instanceExpr) else {
            throw RuntimeError.onlyInstancesHaveProperties
        }

        let propertyValue = try evaluate(expr: valueExpr)

        try instance.set(propertyName: propertyNameToken.lexeme, propertyValue: propertyValue)
        return propertyValue
    }

    private func handleThis(thisToken: Token, depth: Int) throws -> LoxValue {
        return try environment.getValueAtDepth(name: thisToken.lexeme, depth: depth)
    }

    private func handleLambdaExpression(params: [Token], statements: [ResolvedStatement]) throws -> LoxValue {
        let environmentWhenDeclared = self.environment

        let function = UserDefinedFunction(name: "lambda",
                                           params: params,
                                           enclosingEnvironment: environmentWhenDeclared,
                                           body: statements,
                                           isInitializer: false)

        return .userDefinedFunction(function)
    }

    private func handleSuperExpression(superToken: Token, methodToken: Token, depth: Int) throws -> LoxValue {
        guard case .instance(let superclass as LoxClass) = try environment.getValueAtDepth(name: "super", depth: depth) else {
            throw RuntimeError.superclassMustBeAClass
        }

        guard case .instance(let thisInstance) = try environment.getValueAtDepth(name: "this", depth: depth - 1) else {
            throw RuntimeError.notAnInstance
        }

        if let method = superclass.findMethod(name: methodToken.lexeme) {
            return .userDefinedFunction(method.bind(instance: thisInstance))
        }

        throw RuntimeError.undefinedProperty(methodToken.lexeme)
    }

    private func handleListExpression(elements: [ResolvedExpression]) throws -> LoxValue {
        let elementValues = try elements.map { element in
            return try evaluate(expr: element)
        }

        return try makeList(elements: elementValues)
    }

    private func handleSubscriptGetExpression(listExpr: ResolvedExpression,
                                              indexExpr: ResolvedExpression) throws -> LoxValue {
        guard case .instance(let list as LoxList) = try evaluate(expr: listExpr) else {
            throw RuntimeError.notAList
        }

        guard case .int(let index) = try evaluate(expr: indexExpr) else {
            throw RuntimeError.indexMustBeAnInteger
        }

        return list[Int(index)]
    }

    private func handleSubscriptSetExpression(listExpr: ResolvedExpression,
                                              indexExpr: ResolvedExpression,
                                              valueExpr: ResolvedExpression) throws -> LoxValue {
        guard case .instance(let list as LoxList) = try evaluate(expr: listExpr) else {
            throw RuntimeError.notAList
        }

        guard case .int(let index) = try evaluate(expr: indexExpr) else {
            throw RuntimeError.indexMustBeAnInteger
        }

        let value = try evaluate(expr: valueExpr)

        list[Int(index)] = value
        return value
    }

    func makeList(elements: [LoxValue]) throws -> LoxValue {
        guard case .instance(let listClass as LoxClass) = try environment.getValue(name: "List") else {
            fatalError()
        }

        let list = LoxList(elements: elements, klass: listClass)
        return .instance(list)
    }
}
