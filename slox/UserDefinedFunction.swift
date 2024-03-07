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
    var body: [ResolvedStatement]
    var isInitializer: Bool

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        let newEnvironment = Environment(enclosingEnvironment: enclosingEnvironment)

        for (i, arg) in args.enumerated() {
            newEnvironment.define(name: params[i].lexeme, value: arg)
        }

        do {
            try interpreter.handleBlock(statements: body, environment: newEnvironment)
        } catch Return.return(let value) {
            // This is for when we call `init()` explicitly from an instance
            if isInitializer {
                return try enclosingEnvironment.getValueAtDepth(name: "this", depth: 0)
            }

            return value
        }

        // This is for when we call `init()` implicitly through a class constructor
        if isInitializer {
            return try enclosingEnvironment.getValueAtDepth(name: "this", depth: 0)
        }

        return .nil
    }

    func bind(instance: LoxInstance) -> Self {
        // We do this to ensure that `this` is 1) available to the method
        // when invoked, and 2) that `this` resolves to the correct instance,
        // namely the one that owns this method.
        let newEnvironment = Environment(enclosingEnvironment: enclosingEnvironment)
        newEnvironment.define(name: "this", value: .instance(instance))
        return UserDefinedFunction(name: name,
                                   params: params,
                                   enclosingEnvironment: newEnvironment,
                                   body: body,
                                   isInitializer: isInitializer)
    }
}
