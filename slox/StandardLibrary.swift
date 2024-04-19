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

class List {
    clone() {
        return this + [];
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
