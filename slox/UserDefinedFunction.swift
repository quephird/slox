//
//  Function.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

import Foundation

struct UserDefinedFunction: LoxCallable, Equatable {
    var name: String
    var enclosingEnvironment: Environment
    var body: [ResolvedStatement]
    var isInitializer: Bool
    var objectId: UUID
    var parameterList: ParameterList? = nil

    var isComputedProperty: Bool {
        return parameterList == nil
    }

    init(name: String,
         parameterList: ParameterList?,
         enclosingEnvironment: Environment,
         body: [ResolvedStatement],
         isInitializer: Bool) {
        self.name = name
        self.parameterList = parameterList
        self.enclosingEnvironment = enclosingEnvironment
        self.body = body
        self.isInitializer = isInitializer
        self.objectId = UUID()
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        let newEnvironment = Environment(enclosingEnvironment: enclosingEnvironment)

        if let parameterList {
            for (i, arg) in args.enumerated() {
                let paramName = parameterList.normalParameters[i]
                newEnvironment.define(name: paramName.lexeme, value: arg)
            }
        }

        do {
            try interpreter.handleBlock(statements: body, environment: newEnvironment)
        } catch JumpType.return(let value) {
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
                                   parameterList: parameterList,
                                   enclosingEnvironment: newEnvironment,
                                   body: body,
                                   isInitializer: isInitializer)
    }
}
