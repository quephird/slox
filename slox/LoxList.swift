//
//  LoxList.swift
//  slox
//
//  Created by Danielle Kefford on 3/12/24.
//

class LoxList: Equatable {
    var elements: [LoxValue]

    init(elements: [LoxValue]) {
        self.elements = elements
    }

    static func == (lhs: LoxList, rhs: LoxList) -> Bool {
        return lhs.elements == rhs.elements
    }
}
