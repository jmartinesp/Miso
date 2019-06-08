public class List<T>: Collection {
    
    public func index(after i: Int) -> Int {
        return i+1
    }
    
    public subscript(position: Int) -> T {
        return elements[position]
    }
    
    public subscript(safe position: Int) -> T? {
        guard (0..<elements.count).contains(position) else { return nil }
        return elements[position]
    }
    
    public var startIndex: Int = 0
    
    public var endIndex: Int {
        return elements.count > 0 ? elements.count - 1 : 0
    }
        
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
    
    public subscript(subRange: Range<Int>) -> List<T> {
        get {
            return List(elements[subRange].map { $0 })
        }
        set {
            elements[subRange] = newValue.elements[0...]
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
    
    public func dropFirst() -> ArraySlice<T> {
        return ArraySlice(elements.dropFirst())
    }
    
    public func dropFirst(_ k: Int) -> ArraySlice<T> {
        return ArraySlice(elements.dropFirst(k))
    }
    
    public func dropLast() -> ArraySlice<T> {
        return ArraySlice(elements.dropLast())
    }
    
    public func dropLast(_ k: Int) -> ArraySlice<T> {
        return ArraySlice(elements.dropLast(k))
    }
    
    public func drop(while predicate: (T) throws -> Bool) rethrows -> ArraySlice<T> {
        while elements.count != 0 {
            if try predicate(elements.first!) {
                elements.removeFirst()
            }
        }
        return ArraySlice(elements)
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
    
    public func map<Result>(_ transform: (T) throws -> Result) rethrows -> [Result] {
        return try elements.map(transform)
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, T) throws -> Result) rethrows -> Result {
        return try elements.reduce(initialResult, nextPartialResult)
    }
    
    public var first: T? {
        return elements.isEmpty ? nil : elements[0]
    }
    
    public var last: T? {
        return elements.isEmpty ? nil : elements[elements.count-1]
    }
    
    public func first(where condition: (T) throws -> Bool) rethrows ->  T? {
        return try elements.first(where: condition)
    }
    
    public func last(where condition: (T) throws -> Bool) rethrows ->  T? {
        return try elements.last(where: condition)
    }
    
    public func flatMap<SegmentOfResult>(_ transform: (T) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence {
        return try elements.flatMap(transform)
    }
    
    public func compactMap<ElementOfResult>(_ transform: (T) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        return try elements.compactMap(transform)
    }
}

extension List where Iterator.Element: Equatable {
    
    public static func ==(lhs: List, rhs: List) -> Bool {
        return lhs.elements == rhs.elements
    }
    
    public static func !=(lhs: List, rhs: List) -> Bool {
        return lhs.elements != rhs.elements
    }
    
    public func index(of element: T) -> Int? {
        return elements.index(of: element)
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
        index = -1
    }
    
    public mutating func next() -> T? {
        guard index + 1 < list.count else { return nil }
        index += 1
        return list[index]
    }
}
