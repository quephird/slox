//
//  StandardLibrary.swift
//  slox
//
//  Created by Danielle Kefford on 3/26/24.
//

let standardLibrary = """
class List {
    append(element) {
        appendNative(this, element);
    }

    deleteAt(index) {
        return deleteAtNative(this, index);
    }

    map(fn) {
        var result = [];
        for (var i = 0; i < this.count; i = i + 1) {
            var newElement = fn(this[i]);
            result.append(newElement);
        }
        return result;
    }

    filter(fn) {
        var result = [];
        for (var i = 0; i < this.count; i = i + 1) {
            if (fn(this[i])) {
                result.append(this[i]);
            }
        }
        return result;
    }

    reduce(initial, fn) {
        var result = initial;
        for (var i = 0; i < this.count; i = i + 1) {
            result = fn(result, this[i]);
        }
        return result;
    }
}

class Dictionary {
    removeValue(key) {
        return removeValueNative(this, key);
    }
}
"""
