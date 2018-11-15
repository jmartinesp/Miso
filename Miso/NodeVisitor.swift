//
//  NodeVisitor.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public protocol NodeVisitorProtocol {
    var head : ((Node, Int) -> Void) { get }
    var tail : ((Node, Int) -> Void) { get }
}

public struct NodeVisitor: NodeVisitorProtocol {
    public private(set) var head : ((Node, Int) -> Void)
    public private(set) var tail : ((Node, Int) -> Void)
    
    public init(head: @escaping ((Node, Int) -> Void), tail: @escaping ((Node, Int) -> Void)) {
        self.head = head
        self.tail = tail
    }

}
