//
//  Reference.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 07/09/2019.
//  Copyright © 2019 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class Reference<C: Collection> {
    
    public var collection: C
    
    public init(collection: C) {
        self.collection = collection
    }
    
}
