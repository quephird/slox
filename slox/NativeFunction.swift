//
//  NativeFunction.swift
//  slox
//
//  Created by Danielle Kefford on 3/2/24.
//

import Foundation

enum NativeFunction: LoxCallable, Equatable, CaseIterable {
    case clock
    case appendNative
    case deleteAtNative

    var arity: Int {
        switch self {
        case .clock:
            return 0
        case .appendNative:
            return 2
        case .deleteAtNative:
            return 2
        }
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        switch self {
        case .clock:
            return .number(Date().timeIntervalSince1970)
        case .appendNative:
            guard case .instance(let loxList as LoxList) = args[0] else {
                throw RuntimeError.notAList
            }

            let element = args[1]
            loxList.elements.append(element)

            return .nil
        case .deleteAtNative:
            guard case .instance(let loxList as LoxList) = args[0] else {
                throw RuntimeError.notAList
            }

            guard case .number(let index) = args[1] else {
                throw RuntimeError.indexMustBeANumber
            }

            return loxList.elements.remove(at: Int(index))
        }
    }
}
