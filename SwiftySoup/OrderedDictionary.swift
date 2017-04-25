//
//  OrderedDictionary.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 18/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class OrderedDictionary<Key: Hashable, Value: Equatable>: SharedDictionary<Key, Value> {
    
    private var orderedSet = OrderedSet<Key>()
    
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
        return self.orderedKeys.flatMap { self[$0] }
    }
    
    public override var count: Int {
        return orderedSet.count
    }
    
    public override var isEmpty: Bool {
        return self.count == 0
    }
    
}
