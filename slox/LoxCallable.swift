//
//  Callable.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

protocol LoxCallable {
    func arity() -> Int
    func call(interpreter: Interpreter, args: [LoxValue]) throws
}
