//
//  XPathEvaluator.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 17/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class XPathEvaluator: CustomStringConvertible {
    
    public func matches(node: Node) -> [Node] {
        fatalError("\(#function) in \(self.self) must be overriden")
    }
    
    public var description: String {
        return "XPath"
    }
    
    class CurrentNode: XPathEvaluator {
        override func matches(node: Node) -> [Node] {
            return [node]
        }
        
        override var description: String {
            return "."
        }
    }
    
    class Root: XPathEvaluator {
        
        override func matches(node: Node) -> [Node] {
            var rootNode = node
            var nodes = [Node]()
            while rootNode.parentNode != nil {
                rootNode = rootNode.parentNode!
            }
            nodes.append(rootNode)
            return nodes
        }
        
        override var description: String {
            return "/"
        }
    }
    
    class AnyChild: XPathEvaluator {
        
        override func matches(node: Node) -> [Node] {
            return getChild(of: node)
        }
        
        private func getChild(of node: Node) -> [Node] {
            
            guard !node.childNodes.isEmpty else { return [] }
            
            var children = [Node]()
            children.append(contentsOf: node.childNodes)
            children.append(contentsOf: node.childNodes.flatMap { getChild(of: $0) })
            return children
        }
        
        override var description: String {
            return "//"
        }
        
    }
    
    class And: XPathEvaluator {
        
        let evaluators: [XPathEvaluator]
        
        init(_ evaluators: XPathEvaluator...) {
            self.evaluators = evaluators
        }
        
        init(_ evaluators: [XPathEvaluator]) {
            self.evaluators = evaluators
        }
        
        override func matches(node: Node) -> [Node] {
            var nodes = [Node]()
            
            for e in evaluators {
                if !e.matches(node: node).isEmpty {
                    nodes.append(node)
                }
            }
            
            return nodes
        }
        
        override var description: String {
            return " and "
        }
    }
    
    class ImmediateParent: XPathEvaluator {
        
        override func matches(node: Node) -> [Node] {
            var nodes = [Node]()
            
            if let parentNode = node.parentNode {
                nodes.append(parentNode)
            }
            
            return nodes
        }
        
        override var description: String {
            return "/"
        }
    }
    
    class NameIs: XPathEvaluator {
        
        let nodeName: String
        
        init(_ name: String) {
            self.nodeName = name
        }
        
        override func matches(node: Node) -> [Node] {
            return node.nodeName == nodeName ? [node] : []
        }
        
        override var description: String {
            return nodeName
        }
    }
    
    class AllElements: XPathEvaluator {
        
        override func matches(node: Node) -> [Node] {
            let nodes = node.childNodes
            
            return nodes
        }
        
        override var description: String {
            return "*"
        }
        
    }
    
    class Index: XPathEvaluator {
        
        let index: Int
        
        init(_ index: Int) {
            self.index = index
        }
        
        override func matches(node: Node) -> [Node] {
            guard let parentNode = node.parentNode else { return [] }
            
            var nodes = [Node]()
            
            var index = self.index
            
            if index < 0 {
                index += parentNode.childNodes.count
            }
            
            if node.siblingIndex == index {
                nodes.append(node)
            }
            
            return nodes
        }
        
        override var description: String {
            return "[\(index)]"
        }
    }
    
    class ImmediateChildren: XPathEvaluator {
        
        override func matches(node: Node) -> [Node] {
            return node.childNodes
        }
    }
    
    class HasAttribute: XPathEvaluator {
        
        let attributeName: String
        
        init(_ attrName: String) {
            self.attributeName = attrName
        }
        
        override func matches(node: Node) -> [Node] {
            return node.has(attr: attributeName) ? [node] : []
        }
    }
    
    class HasAttributeValue: XPathEvaluator {
        
        let attributeName: String
        let attributeValue: String
        
        init(name: String, value: String) {
            self.attributeName = name
            self.attributeValue = value
        }
        
        override func matches(node: Node) -> [Node] {
            return node.attr(attributeName) == attributeValue ? [node] : []
        }
        
        override var description: String {
            return "@\(attributeName)=\(attributeValue)"
        }
    }
    
    class HasChildrenNamed: XPathEvaluator {
        
        let childName: String
        
        init(_ childName: String) {
            self.childName = childName
        }
        
        override func matches(node: Node) -> [Node] {
            return node.childNodes.filter { $0.nodeName == self.childName }
        }
        
        override var description: String {
            return childName
        }
    }
    
    class HasChildrenWithTextValue: XPathEvaluator {
        
        let textValue: String
        
        init(_ textValue: String) {
            self.textValue = textValue
        }
        
        override func matches(node: Node) -> [Node] {
            return node.childNodes.filter {
                $0.childNodes.cast(to: TextNode.self).first { textNode in textNode.text == self.textValue } != nil
            }
        }
        
        override var description: String {
            return textValue
        }
    }
    
}
