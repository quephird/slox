//
//  LoxClass.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxClass: LoxInstance, LoxCallable {
    var name: String
    var arity: Int {
        if let initializer = methods["init"] {
            return initializer.params.count
        }

        return 0
    }
    var methods: [String: UserDefinedFunction]

    init(name: String, methods: [String: UserDefinedFunction]) {
        self.name = name
        self.methods = methods

        super.init(klass: nil)
    }

    static func == (lhs: LoxClass, rhs: LoxClass) -> Bool {
        return lhs === rhs
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        let newInstance = LoxInstance(klass: self)

        if let initializer = methods["init"] {
            let boundInit = initializer.bind(instance: newInstance)
            let _ = try boundInit.call(interpreter: interpreter, args: args)
        }

        return .instance(newInstance)
    }
}
