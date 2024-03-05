//
//  LoxClass.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxClass: Equatable {
    var name: String

    init(name: String) {
        self.name = name
    }

    static func == (lhs: LoxClass, rhs: LoxClass) -> Bool {
        return lhs === rhs
    }
}
