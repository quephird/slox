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

    private func setUpGlobals() {
        for nativeFunction in NativeFunction.allCases {
            environment.define(name: String(describing: nativeFunction),
                               value: .nativeFunction(nativeFunction))
        }
    }

    func interpret(statements: [ResolvedStatement]) throws {
        for statement in statements {
            try execute(statement: statement)
        }
    }

    func interpretRepl(statements: [ResolvedStatement]) throws -> LoxValue? {
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
        case .class(let nameToken, let body):
            try handleClassDeclaration(nameToken: nameToken, body: body)
        case .function(let name, let lambda):
            try handleFunctionDeclaration(name: name, lambda: lambda)
        case .return(let returnToken, let expr):
            try handleReturnStatement(returnToken: returnToken, expr: expr)
        }
    }

    private func handleIfStatement(testExpr: ResolvedExpression,
                                   consequentStmt: ResolvedStatement,
                                   alternativeStmt: ResolvedStatement?) throws {
        if isTruthy(value: try evaluate(expr: testExpr)) {
            try execute(statement: consequentStmt)
        } else if let alternativeStmt {
            try execute(statement: alternativeStmt)
        }
    }

    private func handlePrintStatement(expr: ResolvedExpression) throws {
        let literal = try evaluate(expr: expr)
        print(literal)
    }

    private func handleClassDeclaration(nameToken: Token, body: [ResolvedStatement]) throws {
        // NOTA BENE: We temporarily set the initial value associated with
        // the class name to `.nil` so that, according to the book,
        // "allows references to the class inside its own methods".
        // We haven't gotten there yet.
        environment.define(name: nameToken.lexeme, value: .nil)
        let newClass = LoxClass(name: nameToken.lexeme)
        try environment.assignAtDepth(name: nameToken.lexeme, value: .class(newClass), depth: 0)
    }

    private func handleFunctionDeclaration(name: Token, lambda: ResolvedExpression) throws {
        guard case .lambda(let params, let body) = lambda else {
            throw RuntimeError.notALambda
        }

        let environmentWhenDeclared = self.environment
        let function = UserDefinedFunction(name: name.lexeme,
                                   params: params,
                                   enclosingEnvironment: environmentWhenDeclared,
                                   body: body)
        environment.define(name: name.lexeme, value: .userDefinedFunction(function))
    }

    private func handleReturnStatement(returnToken: Token, expr: ResolvedExpression?) throws {
        var value: LoxValue = .nil
        if let expr {
            value = try evaluate(expr: expr)
        }

        throw Return.return(value)
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
        while isTruthy(value: try evaluate(expr: expr)) {
            try execute(statement: stmt)
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
            return try handleFunctionCallExpression(calleeExpr: calleeExpr, rightParen: rightParen, args: args)
        case .lambda(let params, let statements):
            return try handleLambdaExpression(params: params, statements: statements)
        }
    }

    private func handleUnaryExpression(oper: Token, expr: ResolvedExpression) throws -> LoxValue {
        let value = try evaluate(expr: expr)

        switch oper.type {
        case .minus:
            guard case .number(let number) = value else {
                throw RuntimeError.unaryOperandMustBeNumber
            }

            return .number(-number)
        case .bang:
            return .boolean(!isTruthy(value: value))
        default:
            throw RuntimeError.unsupportedUnaryOperator
        }
    }

    private func handleBinaryExpression(leftExpr: ResolvedExpression,
                                        oper: Token,
                                        rightExpr: ResolvedExpression) throws -> LoxValue {
        let leftValue = try evaluate(expr: leftExpr)
        let rightValue = try evaluate(expr: rightExpr)

        if case .number(let leftNumber) = leftValue,
           case .number(let rightNumber) = rightValue {
            switch oper.type {
            case .plus:
                return .number(leftNumber + rightNumber)
            case .minus:
                return .number(leftNumber - rightNumber)
            case .star:
                return .number(leftNumber * rightNumber)
            case .slash:
                return .number(leftNumber / rightNumber)
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
        }

        if case .string(let leftString) = leftValue,
           case .string(let rightString) = rightValue,
           case .plus = oper.type {
            return .string(leftString + rightString)
        }

        switch oper.type {
        case .bangEqual:
            return .boolean(!isEqual(leftValue: leftValue, rightValue: rightValue))
        case .equalEqual:
            return .boolean(isEqual(leftValue: leftValue, rightValue: rightValue))
        case .plus:
            throw RuntimeError.binaryOperandsMustBeNumbersOrStrings
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
            if !isTruthy(value: leftValue) {
                return leftValue
            } else {
                return try evaluate(expr: rightExpr)
            }
        } else {
            if isTruthy(value: leftValue) {
                return leftValue
            } else {
                return try evaluate(expr: rightExpr)
            }
        }
    }

    private func handleFunctionCallExpression(calleeExpr: ResolvedExpression,
                                              rightParen: Token,
                                              args: [ResolvedExpression]) throws -> LoxValue {
        let callee = try evaluate(expr: calleeExpr)

        let actualFunction: LoxCallable = switch callee {
        case .userDefinedFunction(let userDefinedFunction):
            userDefinedFunction
        case .nativeFunction(let nativeFunction):
            nativeFunction
        default:
            throw RuntimeError.notAFunction
        }

        guard args.count == actualFunction.arity else {
            throw RuntimeError.wrongArity(actualFunction.arity, args.count)
        }

        var argValues: [LoxValue] = []
        for arg in args {
            let argValue = try evaluate(expr: arg)
            argValues.append(argValue)
        }

        return try actualFunction.call(interpreter: self, args: argValues)
    }

    private func handleLambdaExpression(params: [Token], statements: [ResolvedStatement]) throws -> LoxValue {
        let environmentWhenDeclared = self.environment

        let function = UserDefinedFunction(name: "<lambda>",
                                   params: params,
                                   enclosingEnvironment: environmentWhenDeclared,
                                   body: statements)

        return .userDefinedFunction(function)
    }

    private func isEqual(leftValue: LoxValue, rightValue: LoxValue) -> Bool {
        switch (leftValue, rightValue) {
        case (.nil, .nil):
            return true
        case (.number(let leftNumber), .number(let rightNumber)):
            return leftNumber == rightNumber
        case (.string(let leftString), .string(let rightString)):
            return leftString == rightString
        case (.boolean(let leftBoolean), .boolean(let rightBoolean)):
            return leftBoolean == rightBoolean
        default:
            return false
        }
    }

    // In Lox, `false` and `nil` are false; everything else is true
    private func isTruthy(value: LoxValue) -> Bool {
        switch value {
        case .nil:
            return false
        case .boolean(let boolean):
            return boolean
        default:
            return true
        }
    }
}
