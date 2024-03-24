//
//  LoxInstance.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxInstance {
    // `klass` is what is used in the interpreter when we need
    // to know the class of a particular instance. Every Lox
    // instance, including Lox classes, need to have a non-nil
    // parent class, and so we lazily construct one if the
    // instance/class was initialized with a nil one, which will
    // only ever happen for the class of a so-called metaclass.
    // We do it lazily so we can avoid instantiating an infinite
    // tower of parent instances of LoxClass.
    private var _klass: LoxClass?
    var klass: LoxClass {
        if _klass == nil {
            // Only metaclasses should ever have a `nil` value for `_klass`
            let selfClass = self as! LoxClass
            _klass = LoxClass(name: "\(selfClass.name) metaclass", superclass: nil, methods: [:])
        }
        return _klass!
    }
    var properties: [String: LoxValue] = [:]

    /// - Parameter klass: The class this instance belongs to.
    /// Use `nil` if this instance *is* a class; the `klass` property
    /// will then instantiate a metaclass for it on demand.
    required init(klass: LoxClass?) {
        self._klass = klass
    }

    func get(propertyName: String) throws -> LoxValue {
        if let propertyValue = self.properties[propertyName] {
            return propertyValue
        }

        if let method = klass.findMethod(name: propertyName) {
            let boundMethod = method.bind(instance: self)
            return .userDefinedFunction(boundMethod)
        }

        throw RuntimeError.undefinedProperty(propertyName)
    }

    func set(propertyName: String, propertyValue: LoxValue) throws {
        self.properties[propertyName] = propertyValue
    }
}
