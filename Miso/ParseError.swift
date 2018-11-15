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

public class ParseErrorList: List<LocalizedError>, LocalizedError {
    
    public static let DEFAULT_MAX_SIZE = 16
    public let maxSize: Int
    
    public init() {
        self.maxSize = ParseErrorList.DEFAULT_MAX_SIZE
        super.init([])
    }
    
    public init(maxSize: Int) {
        self.maxSize = maxSize
        super.init([])
    }
    
    public override func append(_ newElement: LocalizedError) {
        if (canAddError) {
            self.elements.append(newElement)
        }
    }
    
    public var canAddError: Bool {
        return count < maxSize
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
        return elements.compactMap { $0.errorDescription }.joined("\n")
    }
    
}
