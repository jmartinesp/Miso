//
//  StringExtension.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 19/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
@testable import Miso

extension String {
    
    public var strippedNewLines: String {
        return self.replaceAll(regex: "\n\\s*", by: "")
    }
    
}
