public class List<T>: Sequence {
        
    public final var elements: Array<T>
    
    public func makeIterator() -> ListIterator<T> {
        return ListIterator<T>(self)
    }
    
    public init(_ elements: Array<T>) {
        self.elements = elements
    }
    
    public convenience init() {
        self.init([])
    }
    
    public convenience init(_ elements: T...) {
        self.init(elements)
    }
    
    public subscript(index: Int) -> T {
        get {
            return elements[index]
        }
        set {
            elements[index] = newValue
        }
    }
    
    public subscript(subRange: Range<Int>) -> ArraySlice<T> {
        get {
            return elements[subRange]
        }
        set {
            elements[subRange] = newValue
        }
    }
    
    public func append(_ newElement: T) {
        elements.append(newElement)
    }
    
    public func insert(_ newElement: T, atIndex index: Int) {
        elements.insert(newElement, at: index)
    }
    
    public func remove(at index: Int) -> T {
        return elements.remove(at: index)
    }
    
    public func removeLast() -> T {
        return elements.removeLast()
    }
    
    public func removeAll(keepCapacity: Bool = false) {
        elements.removeAll(keepingCapacity: keepCapacity)
    }
    
    public func reserveCapacity(minimumCapacity: Int) {
        elements.reserveCapacity(minimumCapacity)
    }
    
    public var count: Int {
        get {
            return elements.count
        }
    }
    
    public var isEmpty: Bool {
        get {
            return elements.isEmpty
        }
    }
    
    public var capacity: Int {
        get {
            return elements.capacity
        }
    }
    
    public func sort(isOrderedBefore: (T, T) -> Bool) {
        self.elements = elements.sorted(by: isOrderedBefore)
    }
    
    public func reverse() -> Array<T> {
        return elements.reversed()
    }
    
    public func filter(includeElement: (T) -> Bool) -> List<T> {
        return List(elements.filter(includeElement))
    }
    
    public func map<U>(transform: (T) -> U) -> List<U> {
        return List<U>(elements.map(transform))
    }
    
    public func reduce<U>(initial: U, combine: (U, T) -> U) -> U {
        return elements.reduce(initial, combine)
    }
    
    public var first: T? {
        return elements.isEmpty ? nil : elements[0]
    }
    
    public var last: T? {
        return elements.isEmpty ? nil : elements[elements.count-1]
    }
}

extension List where Iterator.Element: Equatable {
    
    public static func ==(lhs: List, rhs: List) -> Bool {
        return lhs.elements == rhs.elements
    }
    
    public static func !=(lhs: List, rhs: List) -> Bool {
        return lhs.elements != rhs.elements
    }
    
}

public func += <T>(lhs: inout List<T>, rhs: T) {
    lhs.elements.append(rhs)
}

public func += <T>(lhs: inout List<T>, rhs: List<T>) {
    lhs.elements += rhs.elements
}

public func += <T>(lhs: inout List<T>, rhs: Array<T>) {
    lhs.elements += rhs
}

public struct ListIterator<T> : IteratorProtocol {
    
    public typealias Element = T
    
    public let list : List<T>
    public var index : Int
    
    public init(_ list: List<T>) {
        self.list = list
        index = 0
    }
    
    public mutating func next() -> T? {
        if index >= list.count { return nil }
        index += 1
        return list[index - 1]
    }
}
