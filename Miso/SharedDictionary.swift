//
//  SharedDictionary.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class SharedDictionary<Key: Hashable, Value>: Sequence, CustomStringConvertible {
    
    public typealias Iterator = SharedDictionaryIterator<Key, Value>
    public typealias SubSequence = SharedDictionary<Key, Value>
    
    init() {
    }
    
    init(dictionary: Dictionary<Key, Value>) {
        self.dictionary = dictionary
    }
    
    private init(slice: Slice<Dictionary<Key, Value>>) {
        for (key, value) in slice {
            self.dictionary[key] = value
        }
    }
    
    var dictionary = [Key: Value]()
    
    public subscript(key: Key) -> Value? {
        set {
            self.dictionary[key] = newValue
        }
        get {
            return self.dictionary[key]
        }
    }
    
    public var keys: Dictionary<Key, Value>.Keys {
        return self.dictionary.keys
    }
    
    public var values: Dictionary<Key, Value>.Values {
        return self.dictionary.values
    }
    
    public var isEmpty: Bool { return self.dictionary.isEmpty }
    
    public var count: Int { return self.dictionary.count }
    
    public func append(dictionary: SharedDictionary<Key, Value>) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }
    
    public func makeIterator() -> SharedDictionaryIterator<Key, Value> {
        return SharedDictionaryIterator(dictionary: self)
    }
    
    public var underestimatedCount: Int {
        return dictionary.underestimatedCount
    }
    
    public func drop(while predicate: (Iterator.Element) throws -> Bool) rethrows -> SharedDictionary<Key, Value> {
        let result = SharedDictionary<Key, Value>()
        
        for item in self {
            if try !predicate(item) {
                result[item.key] = item.value
            }
        }
        
        return result
    }
    
    public func dropFirst(_ n: Int) -> SharedDictionary<Key, Value> {
        let result = SharedDictionary<Key, Value>()
        
        var count = 0
        
        for item in self {
            if count >= n {
                result[item.key] = item.value
            }
            count += 1
        }
        
        return result
    }
    
    public func dropLast(_ n: Int) -> SharedDictionary<Key, Value> {
        let result = SharedDictionary<Key, Value>()
        
        var count = 0
        
        for item in self {
            if count == n { break }
            result[item.key] = item.value
            count += 1
        }
        
        return result
    }
    
    public func filter(_ isIncluded: (Iterator.Element) throws -> Bool) rethrows -> [Iterator.Element] {
        var result = Array<Iterator.Element>()
        
        for item in self {
            if try isIncluded(item) {
                result.append(item)
            }
        }
        
        return result
    }
    
    public func forEach(_ body: (Iterator.Element) throws -> Void) rethrows {
        for item in self {
            try body(item)
        }
    }

    public func map<T>(_ transform: (Iterator.Element) throws -> T) rethrows -> [T] {
        var result = [T]()
        for item in self {
            result.append(try transform(item))
        }
        return result
    }
    
    public func prefix(_ maxLength: Int) -> SharedDictionary<Key, Value> {
        let result = SharedDictionary<Key, Value>()
        
        var count = 0
        
        for item in self {
            if count == maxLength { break }
            result[item.key] = item.value
            count += 1
        }
        
        return result
    }
    
    public func prefix(while predicate: (Iterator.Element) throws -> Bool) rethrows -> SharedDictionary<Key, Value> {
        let result = SharedDictionary<Key, Value>()
        
        for item in self {
            if try predicate(item) {
                result[item.key] = item.value
            }
        }
        
        return result
    }
    
    public func split(maxSplits: Int, omittingEmptySubsequences: Bool, whereSeparator isSeparator: (Iterator.Element) throws -> Bool) rethrows -> [SharedDictionary<Key, Value>] {
        var results = [SharedDictionary<Key, Value>]()
        
        var current = SharedDictionary<Key, Value>()
        for item in self {
            if try isSeparator(item) {
                if !(current.isEmpty && omittingEmptySubsequences) {
                    results.append(current)
                    current = SharedDictionary<Key, Value>()
                }
            } else {
                current[item.key] = item.value
            }
        }
        return results
    }
    
    public func suffix(_ maxLength: Int) -> SharedDictionary<Key, Value> {
        let result = SharedDictionary<Key, Value>()
        
        var index = 0
        
        for item in self {
            if index < dictionary.count - maxLength { continue }
            result[item.key] = item.value
            index += 1
        }
        return result
    }
    
    
    public var description: String {
        let pairs = (0..<count).map {
                let index = self.keys.index(self.keys.startIndex, offsetBy: $0)
                let key = self.keys[index]
            return "\t\(key): \(String(describing: self[key]!))"
            }
            .joined(separator: ",\n")
        
        return "[\n\(pairs)\n]"
    }
}

public class SharedDictionaryIterator<Key: Hashable, Value>: IteratorProtocol {
    
    public typealias Element = (key: Key, value: Value)
    
    var index: Dictionary<Key, Value>.Index
    let dictionary: SharedDictionary<Key, Value>
    
    init(dictionary: SharedDictionary<Key, Value>) {
        self.dictionary = dictionary
        self.index = dictionary.keys.startIndex
    }
    
    public func next() -> (key: Key, value: Value)? {
        
        guard dictionary.keys.endIndex > index else { return nil }
        
        let key = dictionary.keys[index]
        let value = dictionary[key]
        
        index = dictionary.keys.index(after: index)
        
        if value != nil {
            return (key: key, value: value!)
        } else {
            return nil
        }
    }
}
