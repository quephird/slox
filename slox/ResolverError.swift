//
//  ResolverError.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

import Foundation

enum ResolverError: CustomStringConvertible, Equatable, LocalizedError {
    case variableAccessedBeforeInitialization
    case notAFunction
    case variableAlreadyDefined(String)
    case cannotReturnOutsideFunction
    case cannotReferenceThisOutsideClass
    case cannotReturnValueFromInitializer
    case staticInitsNotAllowed
    case classCannotInheritFromItself

    var description: String {
        switch self {
        case .variableAccessedBeforeInitialization:
            return "Can't read local variable in its own initializer"
        case .notAFunction:
            return "Expected lambda as body of function declaration"
        case .variableAlreadyDefined(let name):
            return "Variable \(name) already defined in this scope"
        case .cannotReturnOutsideFunction:
            return "Cannot return from outside a function"
        case .cannotReferenceThisOutsideClass:
            return "Cannot use `this` from outside a class"
        case .cannotReturnValueFromInitializer:
            return "Cannot return value from an initializer"
        case .staticInitsNotAllowed:
            return "Cannot have class-level init function"
        case .classCannotInheritFromItself:
            return "Class cannot inherit from itself"
        }
    }
}
