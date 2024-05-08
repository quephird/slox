//
//  ResolverError.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

import Foundation

enum ResolverError: CustomStringConvertible, Equatable, LocalizedError {
    case variableAccessedBeforeInitialization(Token)
    case variableAlreadyDefined(Token)
    case cannotReturnOutsideFunction(Token)
    case cannotReferenceThisOutsideClass(Token)
    case cannotReturnValueFromInitializer(Token)
    case staticInitsNotAllowed(Token)
    case classCannotInheritFromItself(Token)
    case cannotReferenceSuperOutsideClass(Token)
    case cannotReferenceSuperWithoutSubclassing(Token)
    case cannotBreakOutsideLoopOrSwitch(Token)
    case cannotContinueOutsideLoop(Token)
    case functionsMustHaveAParameterList(Token)
    case cannotUseSplatOperatorOutOfContext(Token)
    case duplicateCaseNamesNotAllowed(Token)
    case switchMustHaveAtLeastOneCaseOrDefault(Token)
    case switchMustHaveAtLeastOneStatementPerCaseOrDefault(Token)

    var description: String {
        switch self {
        case .variableAccessedBeforeInitialization(let token):
            return "[Line \(token.line)] Error: cannot read local variable in its own initializer"
        case .variableAlreadyDefined(let token):
            return "[Line \(token.line)] Error: variable \(token.lexeme) already defined in this scope"
        case .cannotReturnOutsideFunction(let token):
            return "[Line \(token.line)] Error: cannot return from outside a function"
        case .cannotReferenceThisOutsideClass(let token):
            return "[Line \(token.line)] Error: cannot use `this` from outside a class"
        case .cannotReturnValueFromInitializer(let token):
            return "[Line \(token.line)] Error: cannot return value from an initializer"
        case .staticInitsNotAllowed(let token):
            return "[Line \(token.line)] Error: cannot have class-level init function"
        case .classCannotInheritFromItself(let token):
            return "[Line \(token.line)] Error: class cannot inherit from itself"
        case .cannotReferenceSuperOutsideClass(let token):
            return "[Line \(token.line)] Error: cannot use `super` from outside a class"
        case .cannotReferenceSuperWithoutSubclassing(let token):
            return "[Line \(token.line)] Error: cannot use `super` without subclassing"
        case .cannotBreakOutsideLoopOrSwitch(let token):
            return "[Line \(token.line)] Error: can only `break` from inside a loop or switch statement"
        case .cannotContinueOutsideLoop(let token):
            return "[Line \(token.line)] Error: can only `continue` from inside a `while` or `for` loop"
        case .functionsMustHaveAParameterList(let token):
            return "[Line \(token.line)] Error: functions must have a parameter list"
        case .cannotUseSplatOperatorOutOfContext(let token):
            return "[Line \(token.line)] Error: cannot use splat operator in this context"
        case .duplicateCaseNamesNotAllowed(let token):
            return "[Line \(token.line)] Error: cannot use duplicate case names in enum: \(token.lexeme)"
        case .switchMustHaveAtLeastOneCaseOrDefault(let token):
            return "[Line \(token.line)] Error: `switch` statement must have at least one `case` or `default` block"
        case .switchMustHaveAtLeastOneStatementPerCaseOrDefault(let token):
            return "[Line \(token.line)] Error: `Each `case` or `default` block must have at least one statement"
        }
    }
}
