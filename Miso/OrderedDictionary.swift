//
//  OrderedDictionary.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 18/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class OrderedDictionary<Key: Hashable, Value: Equatable>: SharedDictionary<Key, Value> {
    
    public typealias Iterator = OrderedDictionaryIterator<Key, Value>
    public typealias SubSequence = OrderedDictionary<Key, Value>
    
    private var orderedSet = OrderedSet<Key>()
    
    override init() {
        super.init()
    }
    
    override init(dictionary: Dictionary<Key, Value>) {
        super.init(dictionary: dictionary)
    }
    
    private init(slice: Slice<Dictionary<Key, Value>>) {
        super.init()
        for (key, value) in slice {
            self.dictionary[key] = value
        }
    }
    
    public override subscript(key: Key) -> Value? {
        get {
            return super[key]
        }
        set {
            if newValue != nil {
                orderedSet.insert(key)
                super[key] = newValue
            } else {
                orderedSet.remove(key)
                super[key] = nil
            }
        }
    }
    
    public var orderedKeys: [Key] {
        return orderedSet.orderedItems
    }
    
    public var orderedValues: [Value] {
        return self.orderedKeys.compactMap { self[$0] }
    }
    
    public override var count: Int {
        return orderedSet.count
    }
    
    public override var isEmpty: Bool {
        return self.count == 0
    }
    
    public override func makeIterator() -> SharedDictionaryIterator<Key, Value> {
        return OrderedDictionaryIterator(dictionary: self)
    }

}

public class OrderedDictionaryIterator<Key: Hashable, Value: Equatable>: SharedDictionaryIterator<Key, Value> {
    
    var i = 0
    var orderedDictionary: OrderedDictionary<Key, Value>
    
    init(dictionary: OrderedDictionary<Key, Value>) {
        self.orderedDictionary = dictionary
        super.init(dictionary: dictionary)
    }
    
    public override func next() -> Element? {
        guard i >= 0 && i < orderedDictionary.count else { return nil }
        
        defer {
            i += 1
        }
        
        return (orderedDictionary.orderedKeys[i], orderedDictionary.orderedValues[i])
    }
}
