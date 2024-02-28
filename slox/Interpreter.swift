//
//  Interpreter.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

struct Interpreter {
    private var environment: Environment = Environment()

    mutating func interpret(statements: [Statement]) throws {
        for statement in statements {
            try execute(statement: statement)
        }
    }

    mutating private func execute(statement: Statement) throws {
        switch statement {
        case .expression(let expr):
            let _ = try evaluate(expr: expr)
        case .print(let expr):
            try handlePrintStatement(expr: expr)
        case .variableDeclaration(let name, let expr):
            try handleVariableDeclaration(name: name, expr: expr)
        case .block(let statements):
            try handleBlock(statements: statements,
                            environment: Environment(enclosingEnvironment: environment))
        }
    }

    private func handlePrintStatement(expr: Expression) throws {
        let literal = try evaluate(expr: expr)
        print(literal)
    }

    private func handleVariableDeclaration(name: Token, expr: Expression?) throws {
        var value: Literal = .nil
        if let expr = expr {
            value = try evaluate(expr: expr)
        }

        environment.define(name: name.lexeme, value: value)
    }

    mutating private func handleBlock(statements: [Statement], environment: Environment) throws {
        let environmentBeforeBlock = self.environment

        self.environment = environment
        for statement in statements {
            try execute(statement: statement)
        }

        self.environment = environmentBeforeBlock
    }

    private func evaluate(expr: Expression) throws -> Literal {
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
        }
    }

    private func handleUnaryExpression(oper: Token, expr: Expression) throws -> Literal {
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
                                        rightExpr: Expression) throws -> Literal {
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
                return .boolean(leftNumber >= rightNumber)
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

    func handleAssignmentExpression(name: Token, expr: Expression) throws -> Literal {
        let value = try evaluate(expr: expr)
        try environment.assign(name: name.lexeme, value: value)
        return value
    }

    private func isEqual(leftValue: Literal, rightValue: Literal) -> Bool {
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
    private func isTruthy(value: Literal) -> Bool {
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
