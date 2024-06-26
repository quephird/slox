//
//  StandardLibrary.swift
//  slox
//
//  Created by Danielle Kefford on 3/26/24.
//

let standardLibrary = """
class String {
    chars {
        return charsNative(this);
    }
}

class Enum {
    class allCases {
        return allCasesNative(this);
    }
}

class List {
    clone() {
        return this + [];
    }

    contains(element) {
        return containsNative(this, element);
    }

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

    firstIndex(element) {
        return firstIndexNative(this, element);
    }
}

class Dictionary {
    clone() {
        var newDict = [:];
        newDict.merge(this);
        return newDict;
    }

    keys {
        return keysNative(this);
    }

    values {
        return valuesNative(this);
    }

    removeValue(key) {
        return removeValueNative(this, key);
    }

    merge(other) {
        var otherKeys = other.keys;
        for (var i = 0; i < otherKeys.count; i = i + 1) {
            var otherKey = otherKeys[i];
            var otherValue = other[otherKey];
            this[otherKey] = otherValue;
        }
    }
}
"""
