//
//  Node.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class Node: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    
    public typealias Safe = _NodeSafe
    
    public static var EMPTY_NODES : [Node] { return [] }
    
    public var safe: Safe { return Safe(node: self) }
    
    public weak var parentNode: Node?
    public var childNodes = [Node]()
    public var attributes = Attributes()
    private var _baseUri: String?
    var baseUri: String? {
        get {
            return _baseUri
        }
        set {
            self._baseUri = newValue
            traverse(nodeVisitor: NodeVisitor(head: { [weak self] node, depth in
                node._baseUri = self?.baseUri
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
    
    open var nodeName: String { fatalError("\(#function) in \(self.self) must be overriden") }
    
    open func xpath(_ xPathSelector: String) -> Nodes {
        return XPathSelector.select(using: xPathSelector, from: self)
    }

    open func attr(_ name: String) -> String? {
        
        if let value = attributes.get(byTag: name)?.value {
            return value
        } else if name.lowercased().hasPrefix("abs:") {
            return self.absUrl(forAttributeKey: name.replacingOccurrences(of: "abs:", with: ""))
        }
        
        return nil
    }
    
    @discardableResult
    open func attr(_ name: String, setValue value: String) -> Node {
        attributes.put(string: value, forKey: name)
        return self
    }
    
    open func has(attr name: String) -> Bool {
        if name.hasPrefix("abs:") {
            let name = name.replacingOccurrences(of: "abs:", with: "")
            if attributes.hasKeyIgnoreCase(key: name) && self.absUrl(forAttributeKey: name) != nil {
                return true
            }
        }
        
        return attributes.hasKeyIgnoreCase(key: name)
    }
    
    @discardableResult
    open func removeAttr(_ name: String) -> Node {
        guard has(attr: name) else { return self }
        
        attributes[name] = nil
        
        return self
    }
    
    open func absUrl(forAttributeKey attrKey: String) -> String? {
        guard has(attr: attrKey) else { return nil }
        
        guard let relURL = attr(attrKey) else { return nil }
        
        guard URL.isValidURL(path: baseUri ?? "") || URL.isValidURL(path: relURL) else { return nil }
        
        let resolved = URL.resolve(basePath: baseUri?.lowercased(), relURL: relURL.lowercased())
        
        return resolved
    }
    
    open func append(childNode: Node) {
        childNode.removeFromParent()
        self.childNodes.append(childNode)
        childNode.siblingIndex = self.childNodes.count - 1
        childNode.parentNode = self
    }
    
    open func append(children: [Node]) {
        children.forEach {
            self.append(childNode: $0)
        }
    }
    
    open func insert(children: [Node], at index: Int) {
        
        let index = index < 0 ? (index + self.childNodes.count+1) : index
        
        for i in (0..<children.count).reversed() {
            self.insert(childNode: children[i], at: index)
        }
        
        reindexChildren(from: index)
    }
    
    open func insert(childNode: Node, at index: Int) {
        guard (0...self.childNodes.count).contains(index) else { return }
        
        childNode.removeFromParent()
        self.childNodes.insert(childNode, at: index)
        childNode.parentNode = self
        
        reindexChildren(from: index)
    }
    
    open func remove(childNode: Node) {
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
    
    open var root: Node {
        var node = self

        while node.parentNode != nil {
            node = node.parentNode!
        }

        return node
    }
    
    open var ownerDocument: Document? {
        let rootNode = root
        return rootNode as? Document
    }
    
    open func removeFromParent() {
        parentNode?.remove(childNode: self)
    }
    
    open func insertBefore(html: String) {
        guard siblingIndex != nil else { return }
        addSiblingHTML(html: html, index: siblingIndex!)
    }
    
    open func insertBefore(node: Node) {
        guard siblingIndex != nil else { return }
        parentNode?.insert(childNode: node, at: siblingIndex!)
    }
    
    open func insertAfter(html: String) {
        guard siblingIndex != nil else { return }
        addSiblingHTML(html: html, index: siblingIndex!+1)
    }
    
    open func insertAfter(node: Node) {
        guard siblingIndex != nil else { return }
        parentNode?.insert(childNode: node, at: siblingIndex!+1)
    }
    
    open func replace(with newNode: Node) {
        parentNode?.replace(child: self, with: newNode)
    }
    
    open func replace(child: Node, with newNode: Node) {
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
    open func wrap(html: String) -> Node? {
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
    
    open func unwrap() -> Node? {
        guard siblingIndex != nil else { return nil }
        
        let firstChild = childNodes.first
        
        parentNode?.insert(children: childNodes, at: siblingIndex!)
        self.removeFromParent()
        
        return firstChild
    }
    
    fileprivate func getDeepChild(element: Element) -> Element {
        let children = element.children
        
        if children.isEmpty {
            return element
        } else {
            return getDeepChild(element: children[0])
        }
    }
    
    open var siblingNodes: [Node] {
        guard parentNode != nil else { return [] }
        
        return parentNode!.childNodes.filter { $0 != self }
    }
    
    open var nextSibling: Node? {
        guard parentNode != nil && siblingIndex != nil && (siblingIndex!+1) < parentNode!.childNodes.count else { return nil }
        
        return parentNode?.childNodes[siblingIndex! + 1]
    }
    
    open var previousSibling: Node? {
        guard parentNode != nil && siblingIndex != nil && (siblingIndex!-1) > 0 else { return nil }
        
        return parentNode?.childNodes[siblingIndex! - 1]
    }
    
    open func traverse(nodeVisitor: NodeVisitor) {
        NodeTraversor(visitor: nodeVisitor).traverse(root: self)
    }
    
    open var outerHTML: String {
        let buffer = StringBuilder()
        outerHTML(accum: buffer)
        return buffer.stringValue
    }
    
    open func outerHTML(accum: StringBuilder) {
        NodeTraversor(visitor: OuterHTMLVisitor(accum: accum, settings: self.outputSettings)).traverse(root: self)
    }
    
    open var outputSettings: OutputSettings {
        get {
            return ownerDocument?.outputSettings ?? Document.defaultOutputSettings
        }
        set {
            ownerDocument?.outputSettings = newValue
        }
    }
    
    open func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        fatalError("\(#function) in \(self.self) must be overriden")
    }
    
    open func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        fatalError("\(#function) in \(self.self) must be overriden")
    }
    
    open func html(appendable: StringBuilder) {
        self.outerHTML(accum: appendable)
    }
    
    open func indent(accum: StringBuilder, depth: Int, settings: OutputSettings) {
        let padding = String.padding(amount: depth * settings.indentAmount)
        accum += "\n\(padding)"
    }
    
    open var description: String {
        return outerHTML
    }
    
    open var debugDescription: String {
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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    open func hasSameValue(_ other: Node) -> Bool {
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
                node.outerHTMLHead(accum: self.accum, depth: depth, outputSettings: self.settings)
            }
        }
        var tail: ((Node, Int) -> Void) {
            return { [unowned self] node, depth in
                if node.nodeName != "#text" {
                    node.outerHTMLTail(accum: self.accum, depth: depth, outputSettings: self.settings)
                }
            }
        }
    }
}

open class _NodeSafe {
    private let node: Node
    
    init(node: Node) {
        self.node = node
    }
    
    open func insertBefore(html: String) throws {
        guard node.siblingIndex != nil else { return }
        try addSiblingHTML(html: html, index: node.siblingIndex!)
    }
    
    open func insertAfter(html: String) throws {
        guard node.siblingIndex != nil else { return }
        try addSiblingHTML(html: html, index: node.siblingIndex!+1)
    }
    
    private func addSiblingHTML(html: String, index: Int) throws {
        let context = node.parentNode as? Element
        let nodes = try Parser.Safe.parse(fragmentHTML: html, withContext: context, baseUri: node.baseUri)
        node.parentNode?.insert(children: nodes, at: index)
    }
    
    @discardableResult
    open func wrap(html: String) throws -> Node? {
        guard !html.isEmpty else { return nil }
        
        let context = node.parentNode as? Element
        
        var wrapChildren = try Parser.Safe.parse(fragmentHTML: html, withContext: context, baseUri: node.baseUri)
        
        guard let wrapNode = wrapChildren.removeFirst() as? Element else { return nil }
        
        let deepest = node.getDeepChild(element: wrapNode)
        node.parentNode?.replace(child: node, with: wrapNode)
        deepest.append(childNode: node)
        
        // remainder (unbalanced wrap, like <div></div><p></p> -- The <p> is remainder
        wrapChildren.forEach { remainder in
            remainder.removeFromParent()
            wrapNode.append(childNode: remainder)
        }
        
        return node
    }
    
}
