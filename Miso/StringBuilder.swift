/**
 Supports creation of a String from pieces
 https://gist.github.com/kristopherjohnson/1fc55e811d944a430289
 */
open class StringBuilder: CustomStringConvertible, CustomDebugStringConvertible {
    public typealias StringLiteralType = String
    
    fileprivate var buffer: String
    
    public var stringValue: String { return buffer }
    
    /**
     Construct with initial String contents
     
     :param: string Initial value; defaults to empty string
     */
    public init(string: String = "") {
        self.buffer = string
        self.buffer.reserveCapacity(string.count + 512)
    }
    
    public init() {
        self.buffer = ""
        self.buffer.reserveCapacity(1024)
    }
    
    /**
     Return the current count of the String object
     */
    open var count: Int {
        return self.buffer.count
        //return countElements(buffer)
    }
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    /**
     Append a String to the object
     
     :param: string String
     
     :return: reference to this StringBuilder instance
     */
    @discardableResult
    open func append(_ string: String) -> StringBuilder {
        buffer.append(contentsOf: string)
        return self
    }

    @discardableResult
    open func appendCodePoint(_ chr: Character) -> StringBuilder {
        buffer.append(chr)
        return self
    }

    @discardableResult
    open func appendCodePoints(_ chr: [Character]) -> StringBuilder {
        buffer.append(contentsOf: chr)
        return self
    }

    @discardableResult
    open func appendCodePoint(_ ch: Int) -> StringBuilder {
        buffer.append(UnicodeScalar(ch)!)
        return self
    }

    @discardableResult
    open func appendCodePoint(_ ch: UnicodeScalar) -> StringBuilder {
        buffer.append(ch)
        return self
    }

    @discardableResult
    open func appendCodePoints(_ chr: [UnicodeScalar]) -> StringBuilder {
        for c in chr {
            appendCodePoint(c)
        }
        return self
    }
    
    /**
     Append a Printable to the object
     
     :param: value a value supporting the Printable protocol
     
     :return: reference to this StringBuilder instance
     */
    @discardableResult
    open func append<T: CustomStringConvertible>(_ value: T) -> StringBuilder {
        buffer.append(contentsOf: value.description)
        return self
    }
    
    @discardableResult
    open func insert<T: CustomStringConvertible>(_ offset: Int, _ value: T) -> StringBuilder {
        let index = buffer.index(buffer.startIndex, offsetBy: offset)
        buffer.insert(contentsOf: value.description, at: index)
        return self
    }
    
    /**
     Append a String and a newline to the object
     
     :param: string String
     
     :return: reference to this StringBuilder instance
     */
    @discardableResult
    open func appendLine(_ string: String) -> StringBuilder {
        buffer.append(contentsOf: "\n")
        return self
    }
    
    /**
     Append a Printable and a newline to the object
     
     :param: value a value supporting the Printable protocol
     
     :return: reference to this StringBuilder instance
     */
    @discardableResult
    open func appendLine<T: CustomStringConvertible>(_ value: T) -> StringBuilder {
        buffer.append(contentsOf: value.description)
        buffer.append(contentsOf: "\n")
        return self
    }
    
    /**
     Reset the object to an empty string
     
     :return: reference to this StringBuilder instance
     */
    @discardableResult
    open func removeAll() -> StringBuilder {
        buffer = ""
        buffer.reserveCapacity(1024)
        return self
    }
    
    @discardableResult
    open func remove(at index: Int) -> StringBuilder {
        buffer.remove(at: buffer.index(buffer.startIndex, offsetBy: index))
        return self
    }
    
    @discardableResult
    open func remove(in range: Range<Int>) -> StringBuilder {
        let start = buffer.index(buffer.startIndex, offsetBy: range.lowerBound)
        let end = buffer.index(buffer.startIndex, offsetBy: range.upperBound)
        buffer.removeSubrange(start..<end)
        return self
    }
    
    open var description: String {
        return stringValue
    }
    
    open var debugDescription: String {
        return stringValue
    }
    
    open subscript(index: Int) -> UnicodeScalar {
        return buffer.unicodeScalars[index]
    }
    
    open subscript(range: Range<Int>) -> String {
        return String(buffer[range])
    }

    open func contains(_ string: String, ignoreCase: Bool = false) -> Bool {
        if ignoreCase {
            return stringValue.lowercased().contains(string.lowercased())
        } else {
            return stringValue.contains(string)
        }
    }

    open func contains(_ char: Character) -> Bool {
        return buffer.contains(where: { $0 == char })
    }

    open func contains(_ scalar: UnicodeScalar) -> Bool {
        let char = Character(scalar)
        return contains(char)
    }
}

/**
 Append a String to a StringBuilder using operator syntax
 
 :param: lhs StringBuilder
 :param: rhs String
 */
public func += (lhs: StringBuilder, rhs: String) {
    lhs.append(rhs)
}

/**
 Append a Printable to a StringBuilder using operator syntax
 
 :param: lhs Printable
 :param: rhs String
 */
public func += <T: CustomStringConvertible>(lhs: StringBuilder, rhs: T) {
    lhs.append(rhs.description)
}

/**
 Create a StringBuilder by concatenating the values of two StringBuilders
 
 :param: lhs first StringBuilder
 :param: rhs second StringBuilder
 
 :result StringBuilder
 */
public func +(lhs: StringBuilder, rhs: StringBuilder) -> StringBuilder {
    return StringBuilder(string: lhs.stringValue).append(rhs.stringValue)
}

extension StringBuilder {
    
    /**
     * After normalizing the whitespace within a string, appends it to a string builder.
     * @param string string to normalize whitespace within
     * @param stripLeading set to true if you wish to remove any leading whitespace
     */
    func appendNormalizedWhitespace(text: String, stripLeading: Bool) {
        self.append(text.normalizedWhitespace(stripLeading: stripLeading))
    }
    
}
