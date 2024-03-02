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
        let clock = LoxFunction(name: "clock",
                                arity: 0,
                                function: { _, _ -> LoxValue in
            return .number(Date().timeIntervalSince1970)
        })
        environment.define(name: "clock", value: .function(clock))
    }

    func interpret(statements: [Statement]) throws {
        for statement in statements {
            try execute(statement: statement)
        }
    }

    func interpretRepl(statements: [Statement]) throws -> LoxValue? {
        var result: LoxValue? = nil

        for (i, statement) in statements.enumerated() {
            if i == statements.endIndex-1, case .expression(let expr) = statement {
                result = try evaluate(expr: expr)
            } else {
                do {
                    try execute(statement: statement)
                } catch Return.return(let value) {
                    result = value
                }
            }
        }

        return result
    }

    private func execute(statement: Statement) throws {
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
        case .function(let name, let params, let body):
            try handleFunctionDeclaration(name: name, params: params, body: body)
        case .return(let returnToken, let expr):
            try handleReturnStatement(returnToken: returnToken, expr: expr)
        }
    }

    private func handleIfStatement(testExpr: Expression,
                                   consequentStmt: Statement,
                                   alternativeStmt: Statement?) throws {
        if isTruthy(value: try evaluate(expr: testExpr)) {
            try execute(statement: consequentStmt)
        } else if let alternativeStmt {
            try execute(statement: alternativeStmt)
        }
    }

    private func handlePrintStatement(expr: Expression) throws {
        let literal = try evaluate(expr: expr)
        print(literal)
    }

    private func handleFunctionDeclaration(name: Token, params: [Token], body: [Statement]) throws {
        let function = LoxFunction(name: name.lexeme, arity: params.count, function: { (interpreter, args) in
            let environment = interpreter.environment

            for (i, arg) in args.enumerated() {
                environment.define(name: params[i].lexeme, value: arg)
            }

            do {
                try interpreter.handleBlock(statements: body, environment: environment)
            } catch Return.return(let value) {
                return value
            }

            return .nil
        })
        environment.define(name: name.lexeme, value: .function(function))
    }

    private func handleReturnStatement(returnToken: Token, expr: Expression?) throws {
        var value: LoxValue = .nil
        if let expr {
            value = try evaluate(expr: expr)
        }

        throw Return.return(value)
    }

    private func handleVariableDeclaration(name: Token, expr: Expression?) throws {
        var value: LoxValue = .nil
        if let expr = expr {
            value = try evaluate(expr: expr)
        }

        environment.define(name: name.lexeme, value: value)
    }

    func handleBlock(statements: [Statement], environment: Environment) throws {
        let environmentBeforeBlock = self.environment

        self.environment = environment
        for statement in statements {
            try execute(statement: statement)
        }

        self.environment = environmentBeforeBlock
    }

    private func handleWhileStatement(expr: Expression, stmt: Statement) throws {
        while isTruthy(value: try evaluate(expr: expr)) {
            try execute(statement: stmt)
        }
    }

    private func evaluate(expr: Expression) throws -> LoxValue {
        switch expr {
        case .literal(let literal):
            return literal
        case .grouping(let expr):
            return try evaluate(expr: expr)
        case .unary(let oper, let expr):
            return try handleUnaryExpression(oper: oper, expr: expr)
        case .binary(let leftExpr, let oper, let rightExpr):
            return try handleBinaryExpression(leftExpr: leftExpr, oper: oper, rightExpr: rightExpr)
        case .variable(let varToken):
            return try environment.getValue(name: varToken.lexeme)
        case .assignment(let varToken, let valueExpr):
            return try handleAssignmentExpression(name: varToken, expr: valueExpr)
        case .logical(let leftExpr, let oper, let rightExpr):
            return try handleLogicalExpression(leftExpr: leftExpr, oper: oper, rightExpr: rightExpr)
        case .call(let calleeExpr, let rightParen, let args):
            return try handleFunctionCallExpression(calleeExpr: calleeExpr, rightParen: rightParen, args: args)
        }
    }

    private func handleUnaryExpression(oper: Token, expr: Expression) throws -> LoxValue {
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

    private func handleBinaryExpression(leftExpr: Expression,
                                        oper: Token,
                                        rightExpr: Expression) throws -> LoxValue {
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

    private func handleAssignmentExpression(name: Token, expr: Expression) throws -> LoxValue {
        let value = try evaluate(expr: expr)
        try environment.assign(name: name.lexeme, value: value)
        return value
    }

    private func handleLogicalExpression(leftExpr: Expression,
                                         oper: Token,
                                         rightExpr: Expression) throws -> LoxValue {
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

    private func handleFunctionCallExpression(calleeExpr: Expression,
                                              rightParen: Token,
                                              args: [Expression]) throws -> LoxValue {
        let callee = try evaluate(expr: calleeExpr)
        guard case .function(let actualFunction) = callee else {
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
