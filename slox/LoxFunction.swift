//
//  Function.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

struct LoxFunction: LoxCallable, Equatable {
    var name: Token
    var params: [Token]
    var body: [Statement]

    func arity() -> Int {
        return params.count
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws {
        let environment = interpreter.environment

        for (i, arg) in args.enumerated() {
            environment.define(name: params[i].lexeme, value: arg)
        }

        try interpreter.handleBlock(statements: body, environment: environment)
    }
}
