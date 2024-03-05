//
//  LoxInstance.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxInstance: Equatable {
    var klass: LoxClass

    init(klass: LoxClass) {
        self.klass = klass
    }

    static func == (lhs: LoxInstance, rhs: LoxInstance) -> Bool {
        return lhs === rhs
    }
}
