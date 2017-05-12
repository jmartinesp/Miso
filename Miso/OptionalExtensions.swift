//
//  OptionalExtensions.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public extension Optional {
    
    public func `let`(transform: ((Wrapped) -> Void)) {
        guard self != nil else { return }
        
        transform(self.unsafelyUnwrapped)
    }
    
}
