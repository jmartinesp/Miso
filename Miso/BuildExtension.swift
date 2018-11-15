//
//  AnyExtension.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 16/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

@discardableResult
public func build<T>(_ receiver: T, closure: ((T) -> Void)) -> T {
    closure(receiver)
    return receiver
}
