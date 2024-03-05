//
//  LoxClass.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxClass: LoxCallable, Equatable {
    var name: String
    var arity: Int {
        return 0
    }

    init(name: String) {
        self.name = name
    }

    static func == (lhs: LoxClass, rhs: LoxClass) -> Bool {
        return lhs === rhs
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        return .instance(LoxInstance(klass: self))
    }
}
