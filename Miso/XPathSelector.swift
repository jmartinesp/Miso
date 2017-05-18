//
//  XPathSelector.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 17/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

class XPathSelector {
    
    public static func select(using query: String, from root: Node) -> Nodes {
        return XPathSelector(xpath: query, root: root).select()
    }
    
    let root: Node
    let evaluators: [XPathEvaluator]
    
    private init(xpath: String, root: Node) {
        let query = xpath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.evaluators = try! XPathParser.parse(query: query)
        self.root = root
    }
    
    func select() -> Nodes {
        var nodes = [root]
        
        for e in evaluators {
            nodes = nodes.flatMap { e.matches(node: $0) }
        }
        
        return Nodes(nodes)
    }
    
}
