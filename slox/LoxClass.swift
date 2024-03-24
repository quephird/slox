//
//  LoxClass.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxClass: LoxInstance, LoxCallable {
    var name: String
    var superclass: LoxClass?
    var arity: Int {
        if let initializer = methods["init"] {
            return initializer.params.count
        }

        return 0
    }
    var methods: [String: UserDefinedFunction]
    var instanceType: LoxInstance.Type {
        if self.name == "List" {
            LoxList.self
        } else {
            LoxInstance.self
        }
    }

    convenience init(name: String, superclass: LoxClass?, methods: [String: UserDefinedFunction]) {
        self.init(klass: nil)

        self.name = name
        self.superclass = superclass
        self.methods = methods
    }

    required init(klass: LoxClass?) {
        self.name = "(anonymous)"
        self.superclass = nil
        self.methods = [:]

        super.init(klass: klass)
    }

    static func == (lhs: LoxClass, rhs: LoxClass) -> Bool {
        return lhs === rhs
    }

    func findMethod(name: String) -> UserDefinedFunction? {
        if let method = methods[name] {
            return method
        }

        return superclass?.findMethod(name: name)
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        let newInstance = instanceType.init(klass: self)

        if let initializer = methods["init"] {
            let boundInit = initializer.bind(instance: newInstance)
            let _ = try boundInit.call(interpreter: interpreter, args: args)
        }

        return .instance(newInstance)
    }
}
