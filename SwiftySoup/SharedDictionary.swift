//
//  SharedDictionary.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class SharedDictionary<Key: Hashable, Value>: Sequence {
    
    public typealias Iterator = DictionaryIterator<Key, Value>
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
    
    public var keys: LazyMapCollection<Dictionary<Key, Value>, Key> {
        return self.dictionary.keys
    }
    
    public var values: LazyMapCollection<Dictionary<Key, Value>, Value> {
        return self.dictionary.values
    }
    
    public var isEmpty: Bool { return self.dictionary.isEmpty }
    
    public var count: Int { return self.dictionary.count }
    
    public func append(dictionary: SharedDictionary<Key, Value>) {
        for (key, value) in dictionary.dictionary {
            self[key] = value
        }
    }
    
    public func makeIterator() -> Iterator {
        return dictionary.makeIterator()
    }
    
    public var underestimatedCount: Int {
        return dictionary.underestimatedCount
    }
    
    public func drop(while predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> SharedDictionary<Key, Value> {
        return SharedDictionary(slice: try dictionary.drop(while: predicate))
    }
    
    public func dropFirst(_ n: Int) -> SharedDictionary<Key, Value> {
        return SharedDictionary(slice: try dictionary.dropFirst(n))
    }
    
    public func dropLast(_ n: Int) -> SharedDictionary<Key, Value> {
        return SharedDictionary(slice: try dictionary.dropLast(n))
    }
    
    public func filter(_ isIncluded: ((key: Key, value: Value)) throws -> Bool) rethrows -> [(key: Key, value: Value)] {
        return try dictionary.filter(isIncluded)
    }
    
    public func forEach(_ body: ((key: Key, value: Value)) throws -> Void) rethrows {
        try dictionary.forEach(body)
    }

    public func map<T>(_ transform: ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        return try dictionary.map(transform)
    }
    
    public func prefix(_ maxLength: Int) -> SharedDictionary<Key, Value> {
        return SharedDictionary(slice: try dictionary.prefix(maxLength))
    }
    
    public func prefix(while predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> SharedDictionary<Key, Value> {
        return SharedDictionary(slice: try dictionary.prefix(while: predicate))
    }
    
    public func split(maxSplits: Int, omittingEmptySubsequences: Bool, whereSeparator isSeparator: ((key: Key, value: Value)) throws -> Bool) rethrows -> [SharedDictionary<Key, Value>] {
        return (try dictionary.split(maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences, whereSeparator: isSeparator)).map {
            SharedDictionary(slice: $0)
        }
    }
    
    public func suffix(_ maxLength: Int) -> SharedDictionary<Key, Value> {
        return SharedDictionary(slice: try dictionary.suffix(maxLength))
    }
    
    
}
