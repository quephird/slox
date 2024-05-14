//
//  LoxClass.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxClass: LoxInstance, LoxCallable {
    var name: String
    var superclass: LoxClass?
    var methods: [String: UserDefinedFunction]

    var instanceType: LoxInstance.Type {
        if self.name == "List" {
            LoxList.self
        } else if self.name == "Dictionary" {
            LoxDictionary.self
        } else if self.name == "String" {
            LoxString.self
        } else {
            LoxInstance.self
        }
    }

    var parameterList: ParameterList? {
        if let initializer = methods["init"] {
            return initializer.parameterList
        }

        return ParameterList(normalParameters: [])
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

    func findMethod(name: String, includePrivate: Bool) -> UserDefinedFunction? {
        if let method = methods[name] {
            if includePrivate || !method.isPrivate {
                return method
            }
        }

        return superclass?.findMethod(name: name, includePrivate: includePrivate)
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
