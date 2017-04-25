//
//  SequenceExtension.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

extension Sequence {
    
    func cast<T>(to: T.Type) -> [T] {
        return self.flatMap { $0 as? T }
    }
    
    func joined(_ separator: String? = nil) -> String {
        let result = StringBuilder()
        for element in self {
            result.append("\(element)")
            if separator != nil {
                result.append(separator!)
            }
        }
        if separator != nil {
            result.remove(at: result.count-separator!.unicodeScalars.count)
        }
        return result.stringValue
    }
}

extension Sequence where Iterator.Element: Equatable {
    
    func lastIndex(of element: Iterator.Element) -> Int? {
        guard underestimatedCount != 0 else { return nil }
        
        var index = underestimatedCount - 1
        for e in self {
            if e == element {
                return index
            }
            index -= 1
        }
        return nil
    }
    
}
