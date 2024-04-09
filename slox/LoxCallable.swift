//
//  Callable.swift
//  slox
//
//  Created by Danielle Kefford on 2/29/24.
//

protocol LoxCallable {
    var parameterList: ParameterList? { get }
    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue
}
