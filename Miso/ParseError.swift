//
//  ParseError.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class ParseError: LocalizedError {
    
    public let pos: Int
    public let errorMessage: String
    
    public init(pos: Int, message: String) {
        self.pos = pos
        self.errorMessage = message
    }
    
    public var errorDescription: String? {
        return "\(pos): \(errorMessage)"
    }
    
}

public class ParseErrorList: LocalizedError {
    
    public static let DEFAULT_MAX_SIZE = 16
    public private(set) var maxSize: Int
    
    public private(set) var errors: [LocalizedError]
    
    public init() {
        self.maxSize = ParseErrorList.DEFAULT_MAX_SIZE
        self.errors = []
    }
    
    public init(maxSize: Int) {
        self.maxSize = maxSize
        self.errors = []
    }
    
    public func append(_ newElement: LocalizedError) {
        if (canAddError) {
            self.errors.append(newElement)
        }
    }
    
    public var count: Int {
        return errors.count
    }
    
    public var canAddError: Bool {
        return errors.count < maxSize
    }
    
    public var isEmpty: Bool {
        return errors.isEmpty
    }
    
    public subscript(_ index: Int) -> LocalizedError {
        return errors[index]
    }
    
    public static func noTracking() -> ParseErrorList {
        return ParseErrorList(maxSize: 0)
    }
    
    public static func tracking(maxSize: Int) -> ParseErrorList {
        return ParseErrorList(maxSize: maxSize)
    }
    
    public static func tracking() -> ParseErrorList {
        return ParseErrorList()
    }
    
    public var errorDescription: String? {
        return errors.compactMap { $0.errorDescription }.joined("\n")
    }
    
}
