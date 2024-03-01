//
//  Function.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

struct LoxFunction: LoxCallable, Equatable {
    var name: String
    var arity: Int
    var function: (Interpreter, [LoxValue]) throws -> LoxValue

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        return try function(interpreter, args)
    }

    static func == (lhs: LoxFunction, rhs: LoxFunction) -> Bool {
        // TODO: need to improve this or look into removing the Equatable conformance
        return lhs.name == rhs.name && lhs.arity == rhs.arity
    }
}
