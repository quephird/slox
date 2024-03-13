//
//  LoxList.swift
//  slox
//
//  Created by Danielle Kefford on 3/12/24.
//

class LoxList: Equatable {
    var elements: [LoxValue]
    var count: Int {
        return elements.count
    }

    init(elements: [LoxValue]) {
        self.elements = elements
    }

    static func == (lhs: LoxList, rhs: LoxList) -> Bool {
        return lhs.elements == rhs.elements
    }

    // TODO: Need to think about how to handle invalid indices!!!
    subscript(index: Int) -> LoxValue {
        get {
            return elements[index]
        }
        set(newValue) {
            elements[index] = newValue
        }
    }
}
