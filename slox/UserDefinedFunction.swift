//
//  Function.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

struct UserDefinedFunction: LoxCallable, Equatable {
    var name: String
    var params: [Token]
    var arity: Int {
        return params.count
    }
    var enclosingEnvironment: Environment
    var body: [Statement]

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        let newEnvironment = Environment(enclosingEnvironment: enclosingEnvironment)

        for (i, arg) in args.enumerated() {
            newEnvironment.define(name: params[i].lexeme, value: arg)
        }

        do {
            try interpreter.handleBlock(statements: body, environment: newEnvironment)
        } catch Return.return(let value) {
            return value
        }

        return .nil
    }
}