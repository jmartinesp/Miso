//
//  OrderedSet.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 18/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class OrderedSet<T: Hashable> {
    
    public typealias Element = T
    
    private var lastIndex = 0
    var orderedItems = [T]()
    var stored = [T: Int]()
    
    init() {}
    
    public required init(arrayLiteral elements: OrderedSet.Element...) {
        for element in elements {
            self.insert(element)
        }
    }
    
    public func insert(_ element: T) {
        let index = self.orderedItems.count
        
        if !stored.keys.contains(element) {
            orderedItems.append(element)
            stored[element] = index
        }
    }
    
    public func remove(_ element: T) {
        if let index = stored.removeValue(forKey: element) {
            orderedItems.remove(at: index)
            
            // Reindex other items
            for i in (index..<self.orderedItems.count) {
                let key = orderedItems[i]
                stored[key] = i
            }
        }
    }
    
    public func contains(_ element: T) -> Bool {
        return stored.keys.contains(element)
    }
    
    public func index(of element: T) -> Int? {
        return stored[element]
    }
    
    public var count: Int {
        return self.orderedItems.count
    }
    
    public var isEmpty: Bool {
        return self.count == 0
    }
    
}

extension OrderedSet: ExpressibleByArrayLiteral {}

extension OrderedSet: Sequence {
    
    public typealias Iterator = OrderedSetIterator<OrderedSet.Element>
    
    public func makeIterator() -> OrderedSetIterator<T> {
        return OrderedSetIterator(orderedSet: self)
    }
}

extension OrderedSet: Equatable {
    
    public static func ==(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool {
        guard lhs.orderedItems.count == rhs.orderedItems.count else { return false }
        for item in lhs.orderedItems {
            if lhs.stored[item] != rhs.stored[item] {
                return false
            }
        }
        return true
    }
    
}

public struct OrderedSetIterator<T: Hashable>: IteratorProtocol {
    public typealias Element = T
    
    private var iterator: IndexingIterator<Array<T>>
    
    public init(orderedSet: OrderedSet<T>) {
        self.iterator = orderedSet.orderedItems.makeIterator()
    }
    
    public mutating func next() -> T? {
        return iterator.next()
    }
    
}
