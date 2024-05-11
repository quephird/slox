//
//  Array+Extension.swift
//  slox
//
//  Created by Danielle Kefford on 5/10/24.
//

extension Array {
    func split(with predicate: (Element) -> Bool) -> ([Element], [Element]) {
        return self.reduce(into: ([], [])) { accumulator, element in
            if predicate(element) {
                accumulator.0.append(element)
            } else {
                accumulator.1.append(element)
            }
        }
    }
}
