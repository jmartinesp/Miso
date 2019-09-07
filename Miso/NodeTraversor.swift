//
//  NodeTraversor.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class NodeTraversor {
    
    private let nodeVisitor: NodeVisitorProtocol
    
    public init(visitor: NodeVisitorProtocol) {
        self.nodeVisitor = visitor
    }
    
    /**
     * Start a depth-first traverse of the root and all of its descendants.
     * @param root the root node point to traverse.
     */
    open func traverse(root: Node) {
        var node: Node? = root
        
        var depth = 0
        
        while node != nil {
            nodeVisitor.head(node!, depth)
            if !node!.childNodes.isEmpty {
                node = node?.childNodes.first
                depth += 1
            } else {
                while node?.nextSibling == nil && depth > 0 {
                    nodeVisitor.tail(node!, depth)
                    node = node?.parentNode
                    depth -= 1
                }
                
                if node != nil {
                    nodeVisitor.tail(node!, depth)
                }
                
                if node === root {
                    break
                }
                
                node = node?.nextSibling
            }
        }
    }
}
