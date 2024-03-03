//
//  Callable.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

protocol LoxCallable {
    var arity: Int { get }
    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue
}
