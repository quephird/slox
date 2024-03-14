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

    var arity: Int {
        switch self {
        case .clock:
            return 0
        case .appendNative:
            return 2
        }
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        switch self {
        case .clock:
            return .number(Date().timeIntervalSince1970)
        case .appendNative:
            guard case .instance(let loxList as LoxList) = args[0] else {
                fatalError()
            }
            let element = args[1]
            loxList.elements.append(element)
            return .nil
        }
    }
}
