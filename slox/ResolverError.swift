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
    case cannotReferenceSuperOutsideClass
    case cannotReferenceSuperWithoutSubclassing
    case cannotBreakOutsideLoop
    case cannotContinueOutsideLoop
    case functionsMustHaveAParameterList
    case cannotUseSplatOperatorOutOfContext
    case duplicateCaseNamesNotAllowed(Token)

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
        case .cannotReferenceSuperOutsideClass:
            return "Cannot use `super` from outside a class"
        case .cannotReferenceSuperWithoutSubclassing:
            return "Cannot use `super` without subclassing"
        case .cannotBreakOutsideLoop:
            return "Can only `break` from inside a `while` or `for` loop"
        case .cannotContinueOutsideLoop:
            return "Can only `continue` from inside a `while` or `for` loop"
        case .functionsMustHaveAParameterList:
            return "Functions must have a parameter list"
        case .cannotUseSplatOperatorOutOfContext:
            return "Cannot use splat operator in this context"
        case .duplicateCaseNamesNotAllowed(let token):
            return "Cannot use duplicate case names in enum: \(token.lexeme)"
        }
    }
}
