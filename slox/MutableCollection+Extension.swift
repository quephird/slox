//
//  MutableCollection+Extension.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

extension MutableCollection where Self: BidirectionalCollection {
    // Accesses the last element of the collection, mutably.
    //
    // - Precondition: Collection is not empty.
    var lastMutable: Element {
        get {
            precondition(!isEmpty)
            return self[index(before: endIndex)]
        }
        set {
            precondition(!isEmpty)
            self[index(before: endIndex)] = newValue
        }
    }
}
