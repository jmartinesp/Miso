//
//  Node.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class Node: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public static var EMPTY_NODES : [Node] { return [] }
    
    public var parentNode: Node?
    public var childNodes = [Node]()
    public var attributes = Attributes()
    private var _baseUri: String?
    var baseUri: String? {
        get {
            return _baseUri
        }
        set {
            self._baseUri = newValue
            traverse(nodeVisitor: NodeVisitor(head: { node, depth in
                node._baseUri = self.baseUri
            }, tail: { node, depth in
            
            }))
        }
    }
    
    /**
     * Get the list index of this node in its node sibling list. I.e. if this is the first node
     * sibling, returns 0.
     * @return position in node sibling list
     */
    var siblingIndex: Int? = nil
    
    public init(baseUri: String?, attributes: Attributes) {
        self.baseUri = baseUri
        self.attributes = attributes
    }
    
    public convenience init(baseUri: String?) {
        self.init(baseUri: baseUri, attributes: Attributes())
    }
    
    public convenience init() {
        self.init(baseUri: nil, attributes: Attributes())
    }
    
    public var nodeName: String { fatalError("Not implemented") }

    public func attr(_ name: String) -> String? {
        
        if let value = attributes.get(byTag: name)?.value {
            return value
        } else if name.lowercased().hasPrefix("abs:") {
            return self.absUrl(forAttributeKey: name.replacingOccurrences(of: "abs:", with: ""))
        }
        
        return nil
    }
    
    @discardableResult
    public func attr(_ name: String, setValue value: String) -> Node {
        attributes.put(string: value, forKey: name)
        return self
    }
    
    public func has(attr name: String) -> Bool {
        if name.hasPrefix("abs:") {
            let name = name.replacingOccurrences(of: "abs:", with: "")
            if attributes.hasKeyIgnoreCase(key: name) && self.absUrl(forAttributeKey: name) != nil {
                return true
            }
        }
        
        return attributes.hasKeyIgnoreCase(key: name)
    }
    
    @discardableResult
    public func removeAttr(_ name: String) -> Node {
        guard has(attr: name) else { return self }
        
        attributes[name] = nil
        
        return self
    }
    
    public func absUrl(forAttributeKey attrKey: String) -> String? {
        guard has(attr: attrKey) else { return nil }
        
        guard let relURL = attr(attrKey) else { return nil }
        
        guard URL.isValidURL(path: baseUri ?? "") || URL.isValidURL(path: relURL) else { return nil }
        
        let resolved = URL.resolve(basePath: baseUri?.lowercased(), relURL: relURL.lowercased())
        
        return resolved
    }
    
    public func append(childNode: Node) {
        childNode.removeFromParent()
        self.childNodes.append(childNode)
        childNode.siblingIndex = self.childNodes.count - 1
        childNode.parentNode = self
    }
    
    public func append(children: [Node]) {
        children.forEach {
            self.append(childNode: $0)
        }
    }
    
    public func insert(children: [Node], at index: Int) {
        
        let index = index < 0 ? (index + self.childNodes.count+1) : index
        
        for i in (0..<children.count).reversed() {
            self.insert(childNode: children[i], at: index)
        }
        
        reindexChildren(from: index)
    }
    
    public func insert(childNode: Node, at index: Int) {
        guard (0...self.childNodes.count).contains(index) else { return }
        
        childNode.removeFromParent()
        self.childNodes.insert(childNode, at: index)
        childNode.parentNode = self
        
        reindexChildren(from: index)
    }
    
    public func remove(childNode: Node) {
        if let index = childNode.siblingIndex {
            self.childNodes.remove(at: index)
            childNode.parentNode = nil
            reindexChildren(from: index)
        }
    }
    
    private func reindexChildren() {
        reindexChildren(from: 0)
    }
    
    private func reindexChildren(from location: Int) {
        for i in (location..<childNodes.count) {
            childNodes[i].siblingIndex = i
        }
    }
    
    public var root: Node {
        var node = self

        while node.parentNode != nil {
            node = node.parentNode!
        }

        return node
    }
    
    public var ownerDocument: Document? {
        let rootNode = root
        return rootNode as? Document
    }
    
    public func removeFromParent() {
        parentNode?.remove(childNode: self)
    }
    
    public func insertBefore(html: String) {
        guard siblingIndex != nil else { return }
        addSiblingHTML(html: html, index: siblingIndex!)
    }
    
    public func insertBefore(node: Node) {
        guard siblingIndex != nil else { return }
        parentNode?.insert(childNode: node, at: siblingIndex!)
    }
    
    public func insertAfter(html: String) {
        guard siblingIndex != nil else { return }
        addSiblingHTML(html: html, index: siblingIndex!+1)
    }
    
    public func insertAfter(node: Node) {
        guard siblingIndex != nil else { return }
        parentNode?.insert(childNode: node, at: siblingIndex!+1)
    }
    
    public func replace(with newNode: Node) {
        parentNode?.replace(child: self, with: newNode)
    }
    
    public func replace(child: Node, with newNode: Node) {
        guard let index = child.siblingIndex else { return }
        
        child.removeFromParent()
                
        self.insert(childNode: newNode, at: index)
    }
    
    private func addSiblingHTML(html: String, index: Int) {
        let context = parentNode as? Element
        let nodes = Parser.parse(fragmentHTML: html, withContext: context, baseUri: baseUri)
        parentNode?.insert(children: nodes, at: index)
    }
    
    /**
     Wrap the supplied HTML around this node.
     @param html HTML to wrap around this element, e.g. {@code <div class="head"></div>}. Can be arbitrarily deep.
     @return this node, for chaining.
     */
    @discardableResult
    public func wrap(html: String) -> Node? {
        guard !html.isEmpty else { return nil }
        
        let context = parentNode as? Element
        
        var wrapChildren = Parser.parse(fragmentHTML: html, withContext: context, baseUri: baseUri)
        
        guard let wrapNode = wrapChildren.removeFirst() as? Element else { return nil }
        
        let deepest = getDeepChild(element: wrapNode)
        parentNode?.replace(child: self, with: wrapNode)
        deepest.append(childNode: self)
        
        // remainder (unbalanced wrap, like <div></div><p></p> -- The <p> is remainder
        wrapChildren.forEach { remainder in
            remainder.removeFromParent()
            wrapNode.append(childNode: remainder)
        }

        return self
    }
    
    public func unwrap() -> Node? {
        guard siblingIndex != nil else { return nil }
        
        let firstChild = childNodes.first
        
        parentNode?.insert(children: childNodes, at: siblingIndex!)
        self.removeFromParent()
        
        return firstChild
    }
    
    private func getDeepChild(element: Element) -> Element {
        let children = element.children
        
        if children.isEmpty {
            return element
        } else {
            return getDeepChild(element: children[0])
        }
    }
    
    public var siblingNodes: [Node] {
        guard parentNode != nil else { return [] }
        
        return parentNode!.childNodes.filter { $0 != self }
    }
    
    public var nextSibling: Node? {
        guard parentNode != nil && siblingIndex != nil && (siblingIndex!+1) < parentNode!.childNodes.count else { return nil }
        
        return parentNode?.childNodes[siblingIndex! + 1]
    }
    
    public var previousSibling: Node? {
        guard parentNode != nil && siblingIndex != nil && (siblingIndex!-1) > 0 else { return nil }
        
        return parentNode?.childNodes[siblingIndex! - 1]
    }
    
    public func traverse(nodeVisitor: NodeVisitor) {
        NodeTraversor(visitor: nodeVisitor).traverse(root: self)
    }
    
    public var outerHTML: String {        
        let buffer = StringBuilder()
        outerHTML(accum: buffer)
        return buffer.stringValue
    }
    
    public func outerHTML(accum: StringBuilder) {
        NodeTraversor(visitor: OuterHTMLVisitor(accum: accum, settings: self.outputSettings)).traverse(root: self)
    }
    
    public var outputSettings: OutputSettings {
        get {
            return ownerDocument?.outputSettings ?? Document.defaultOutputSettings
        }
        set {
            ownerDocument?.outputSettings = newValue
        }
    }
    
    public func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) throws {
        fatalError("Not implemented")
    }
    
    public func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) throws {
        fatalError("Not implemented")
    }
    
    public func html(appendable: StringBuilder) {
        self.outerHTML(accum: appendable)
    }
    
    public func indent(accum: StringBuilder, depth: Int, settings: OutputSettings) {
        let padding = String.padding(amount: depth * settings.indentAmount)
        accum += "\n\(padding)"
    }
    
    public var description: String {
        return outerHTML
    }
    
    public var debugDescription: String {
        return outerHTML
    }
    
    public static func ==(rhs: Node, lhs: Node) -> Bool {
        return rhs === lhs
    }
    
    public static func !=(rhs: Node, lhs: Node) -> Bool {
        return rhs !== lhs
    }
    
    public static func ~=(rhs: Node, lhs: Node) -> Bool {
        return rhs.outerHTML == lhs.outerHTML
    }
    
    public var hashValue: Int {
        return description.hashValue
    }
    
    public func hasSameValue(_ other: Node) -> Bool {
        return self == other || self.outerHTML == other.outerHTML
    }
    
    class OuterHTMLVisitor: NodeVisitorProtocol {
        var accum: StringBuilder
        var settings: OutputSettings
        
        init(accum: StringBuilder, settings: OutputSettings) {
            self.accum = accum
            self.settings = settings
        }
        
        var head: ((Node, Int) -> Void) {
            return { [unowned self] node, depth in
                do {
                    try node.outerHTMLHead(accum: self.accum, depth: depth, outputSettings: self.settings)
                } catch {
                    // TODO add exception handling
                    print(error)
                }
            }
        }
        var tail: ((Node, Int) -> Void) {
            return { [unowned self] node, depth in
                if node.nodeName != "#text" {
                    do {
                        try node.outerHTMLTail(accum: self.accum, depth: depth, outputSettings: self.settings)
                    } catch {
                        // TODO add exception handling
                        print(error)
                    }
                }
            }
        }
    }
    
}
