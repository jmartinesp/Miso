//
//  Element.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation


/**
 * A HTML element consists of a tag name, attributes, and child nodes (including text nodes and
 * other elements).
 *
 * From an Element, you can extract data, traverse the node graph, and manipulate the HTML.
 *
 * @author Jonathan Hedley, jonathan@hedley.net
 * @author Jorge Martín Espinosa, jorgemartinespinosa@gmail.com
 */
open class Element: Node {
    
    public typealias Safe = _ElementSafe
    
    public override var safe: _ElementSafe { return Safe(element: self) }
    
    public private(set) var tag: Tag
    
    public convenience init(tag: String) {
        self.init(tag: Tag.valueOf(tagName: tag), baseUri: nil, attributes: Attributes())
    }
    
    public init(tag: Tag, baseUri: String?, attributes: Attributes) {
        self.tag = tag
        super.init(baseUri: baseUri, attributes: attributes)
    }
    
    public init (tag: Tag, baseUri: String?) {
        self.tag = tag
        super.init(baseUri: baseUri, attributes: Attributes())
    }
    
    open override var nodeName: String {
        return tag.tagName
    }
    
    open var tagName: String {
        set {
            tag = Tag.valueOf(tagName: newValue)
        }
        get {
            return tag.tagName
        }
    }
    
    open var isBlock: Bool {
        return tag.isBlock
    }
    
    open var id: String? {
        return attributes["id"]?.value
    }
    
    @discardableResult
    open func attr(_ name: String, setValue value: Bool) -> Element {
        attributes.put(bool: value, forKey: name)
        return self
    }
    
    @discardableResult
    open override func attr(_ name: String, setValue value: String) -> Element {
        attributes.put(string: value, forKey: name)
        return self
    }
    
    open var dataset: Attributes.DataSet {
        return attributes.dataset
    }
    
    open var parentElement: Element? {
        return parentNode as? Element
    }
    
    open var parents: Elements {
        var elements = Elements()
        
        Element.accumulateParents(element: self, parents: &elements)
        
        return elements
    }
    
    private static func accumulateParents(element: Element, parents: inout Elements) {
        guard let parent = element.parentNode as? Element, parent.tagName != "#root" else { return }
        
        parents.append(parent)
        
        accumulateParents(element: parent, parents: &parents)
    }
    
    open var textNodes: [TextNode] {
        return childNodes.filter { $0 is TextNode }.map { $0 as! TextNode }
    }
    
    open var dataNodes: [DataNode] {
        return childNodes.filter { $0 is DataNode }.map { $0 as! DataNode }
    }
    
    open func select(_ cssSelector: String) -> Elements {
        return Selector.select(using: cssSelector, from: self)
    }
    
    open func matches(query: String) -> Bool {
        do {
            return try matches(evaluator: QueryParser.parse(query: query))
        } catch {
            print(error)
            return false
        }
    }
    
    open func matches(evaluator: EvaluatorProtocol) -> Bool {
        return evaluator.matches(root: (self.root as? Element), and: self)
    }
    
    @discardableResult
    open func append(element tagName: String) -> Element {
        let element = Element(tag: Tag.valueOf(tagName: tagName), baseUri: baseUri)
        append(childNode: element)
        return element
    }
    
    @discardableResult
    open func prepend(element tagName: String) -> Element {
        let element = Element(tag: Tag.valueOf(tagName: tagName), baseUri: baseUri)
        insert(childNode: element, at: 0)
        return element
    }
    
    @discardableResult
    open func append(text: String) -> TextNode {
        let textNode = TextNode(text: text, baseUri: baseUri)
        append(childNode: textNode)
        return textNode
    }
    
    @discardableResult
    open func prepend(text: String) -> TextNode {
        let textNode = TextNode(text: text, baseUri: baseUri)
        insert(childNode: textNode, at: 0)
        return textNode
    }
    
    @discardableResult
    open func append(html: String) -> [Node] {
        let nodes = Parser.parse(fragmentHTML: html, withContext: self, baseUri: baseUri)
        append(children: nodes)
        return nodes
    }
    
    @discardableResult
    open func prepend(html: String) -> [Node] {
        let nodes = Parser.parse(fragmentHTML: html, withContext: self, baseUri: baseUri)
        insert(children: nodes, at: 0)
        return nodes
    }
    
    @discardableResult
    open func prepend(childNode: Node) -> Node {
        insert(childNode: childNode, at: 0)
        return childNode
    }
    
    open func removeAll() {
        self.childNodes.removeAll()
    }
    
    open var cssSelector: String {
        if id != nil {
            return "#\(id!)"
        }
        
        let tagName = self.tagName.replacingOccurrences(of: ":", with: "|")
        var selector = tagName
        let classes = classNames.joined(separator: ".")
        
        if !classes.isEmpty {
            selector += "." + classes
        }
        guard let parent = parentNode as? Element, !(parent is Document) else {
            return selector
        }
        
        selector = " > " + selector
        
        if parent.select(selector).count > 1 {
            selector += ":nth-child(\(elementSiblingIndex != nil ? elementSiblingIndex! + 1 : -1))"
        }
        
        return parent.cssSelector + selector
    }
    
    var children: Elements {
        return Elements(self.childNodes.cast(to: Element.self))
    }
    
    open var siblingElements: Elements {
        guard parentNode != nil else {
            return Elements()
        }
        
        var elements = Elements()
        let siblings = parentNode!.childNodes.cast(to: Element.self)
        siblings.filter { $0 != self }.forEach { elements.append($0) }
        
        return elements
    }
    
    open var nextSiblingElement: Element? {
        guard let siblingIndex = self.siblingIndex else { return nil }
        
        return parentNode?.childNodes.cast(to: Element.self).first{
            $0.siblingIndex == siblingIndex+1
        }
    }
    
    open var previousSiblingElement: Element? {
        guard let siblingIndex = self.siblingIndex else { return nil }
        
        return parentNode?.childNodes.cast(to: Element.self).first{
            $0.siblingIndex == siblingIndex - 1
        }
    }
    
    open var firstSiblingElement: Element? {
        return siblingElements.first
    }
    
    open var lastSiblingElement: Element? {
        return siblingElements.last
    }
    
    /**
     * Get the list index of this element in its element sibling list. I.e. if this is the first element
     * sibling, returns 0.
     * @return position in element sibling list
     */
    open var elementSiblingIndex: Int? {
        return parentNode?.childNodes.cast(to: Element.self).firstIndex(of: self)
    }
    
    open func elements(byTag tagName: String) -> Elements {
        let tagName = tagName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.TagIs(tagName: tagName), root: self)
    }
    
    open func element(byId id: String) -> Element? {
        let id = id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.IdIs(id: id), root: self).first
    }
    
    open func elements(byClass className: String) -> Elements {
        let className = className.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasClass(className: className), root: self)
    }
    
    open func elements(byAttributeName attrName: String) -> Elements {
        let attrName = attrName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttribute(attrName: attrName), root: self)
    }
    
    open func elements(byAttributeStartingWith attrPrefix: String) -> Elements {
        let attrPrefix = attrPrefix.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeStartingWith(attrStart: attrPrefix), root: self)
    }
    
    open func elements(byValue attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let evaluator = try Evaluator.HasAttributeWithValue(key: key, value: attrValue)
            return Collector.collect(evaluator: evaluator, root: self)
        } catch {
            print(error)
            return Elements()
        }
    }
    
    open func elements(byValueNot attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let evaluator = try Evaluator.HasAttributeWithValueNot(key: key, value: attrValue)
            return Collector.collect(evaluator: evaluator, root: self)
        } catch {
            print(error)
            return Elements()
        }
    }
    
    open func elements(byValueStarting attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let evaluator = try Evaluator.HasAttributeWithValueStartingWith(key: key, value: attrValue)
            return Collector.collect(evaluator: evaluator, root: self)
        } catch {
            print(error)
            return Elements()
        }
    }
    
    open func elements(byValueEnding attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let evaluator = try Evaluator.HasAttributeWithValueEndingWith(key: key, value: attrValue)
            return Collector.collect(evaluator: evaluator, root: self)
        } catch {
            print(error)
            return Elements()
        }
    }
    
    open func elements(byValueContaining attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let evaluator = try Evaluator.HasAttributeWithValueContaining(key: key, value: attrValue)
            return Collector.collect(evaluator: evaluator, root: self)
        } catch {
            print(error)
            return Elements()
        }
    }
    
    open func elements(byValueMathing pattern: String, key: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValueMatching(key: key, pattern: pattern), root: self)
    }
    
    //======================================================================
    // MARK: Indexes
    //======================================================================
    
    open func elements(byIndexLessThan index: Int) -> Elements {
        return Collector.collect(evaluator: Evaluator.IndexLessThan(index: index), root: self)
    }
    
    open func elements(byIndexGreaterThan index: Int) -> Elements {
        return Collector.collect(evaluator: Evaluator.IndexGreaterThan(index: index), root: self)
    }
    
    open func elements(byIndexEqualsTo index: Int) -> Elements {
        return Collector.collect(evaluator: Evaluator.IndexEquals(index: index), root: self)
    }
    
    //======================================================================
    // MARK: Containing
    //======================================================================
    
    open func elements(containingText text: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.ContainsText(searchText: text), root: self)
    }
    
    open func elements(containingOwnText text: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.ContainsOwnText(searchOwnText: text), root: self)
    }
    
    //======================================================================
    // MARK: MatchingText
    //======================================================================
    
    open func elements(matchingText pattern: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.MatchesText(pattern: pattern), root: self)
    }
    
    open func elements(matchingOwnText pattern: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.MatchesOwnText(pattern: pattern), root: self)
    }
    
    //======================================================================
    // MARK: Other
    //======================================================================
    
    open var allElements: Elements {
        return Collector.collect(evaluator: Evaluator.AllElements(), root: self)
    }
    
    open var text: String {
        get{
            let accum = StringBuilder()
            NodeTraversor(visitor: NodeVisitor(head: { node, depth in
                if let textNode = node as? TextNode {
                    Element.appendNormalizedText(accum: accum, textNode: textNode)
                } else if let element = node as? Element {
                    if !accum.isEmpty && (element.isBlock || element.tagName == "br") && !TextNode.lastCharIsWhitespace(text: accum.stringValue) {
                        accum.append(" ")
                    }
                }
            }, tail: { node, depth in })).traverse(root: self)
            
            return accum.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        set {
            removeAll()
            let textNode = TextNode(text: newValue, baseUri: baseUri)
            self.append(childNode: textNode)
        }
    }
    
    @discardableResult
    func text(replaceWith newValue: String) -> Element {
        self.text = newValue
        return self
    }
    
    private static func appendNormalizedText(accum: StringBuilder, textNode: TextNode) {
        let text = textNode.wholeText
        
        if textNode.parentNode != nil && preserveWhitespace(in: textNode.parentNode!) {
            accum.append(text)
        } else {
            accum.appendNormalizedWhitespace(text: text, stripLeading: TextNode.lastCharIsWhitespace(text: accum.stringValue))
        }
    }
        
    static func preserveWhitespace(in node: Node) -> Bool {
        // looks only at this element and one level up, to prevent recursion & needless stack searches
        if let element = node as? Element {
            return element.tag.preserveWhitespace || element.parentElement != nil && element.parentElement!.tag.preserveWhitespace
        }
        return false
    }
    
    open var ownText: String {
        let accum = StringBuilder()
        
        childNodes.forEach { node in
            if let textNode = node as? TextNode {
                accum.appendNormalizedWhitespace(text: textNode.text, stripLeading: TextNode.lastCharIsWhitespace(text: accum.stringValue))
            } else if let element = node as? Element {
                if element.tagName == "br" && !TextNode.lastCharIsWhitespace(text: accum.stringValue) {
                    accum.append(" ")
                }
            }
        }
        return accum.stringValue
    }
    
    open var hasText: Bool {
        for node in childNodes {
            if let textNode = node as? TextNode, !textNode.isBlank {
                return true
            } else if let element = node as? Element, element.hasText {
                return true
            }
        }
        return false
    }
    
    open var data: String {
        let accum = StringBuilder()
        
        for node in childNodes {
            if let dataNode = node as? DataNode {
                accum += dataNode.wholeData
            } else if let commentNode = node as? Comment {
                accum += commentNode.data
            } else if let element = node as? Element {
                accum += element.data
            }
        }
        
        return accum.stringValue
    }
    
    open var className: String {
        return self.attr("class")?
            .normalizedWhitespace(stripLeading: true)
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").joined(" ")
            .trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    open var classNames: OrderedSet<String> {
        get {
            let set = OrderedSet<String>()
            (attributes.get(byTag: "class")?.value
                .normalizedWhitespace(stripLeading: true)
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: " ") ?? [])
                .forEach {
                    set.insert($0)
                }
            return set
            
        }
        set {
            self.attr("class", setValue: newValue.joined(separator: " ").normalizedWhitespace(stripLeading: true).trimmingCharacters(in: .whitespaces))
        }
    }
    
    open func hasClass(_ className: String) -> Bool {
        guard let classAttr = attributes.get(byTag: "class", ignoreCase: true)?.value else { return false }
        
        guard !classAttr.isEmpty && classAttr.unicodeScalars.count >= className.unicodeScalars.count else { return false }
        
        return classAttr.lowercased()
            .normalizedWhitespace(stripLeading: true)
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ")
            .contains(className.lowercased())
    }
    
    @discardableResult
    open func addClass(_ className: String) -> Element {
        let classes = self.classNames
        classes.insert(className.normalizedWhitespace(stripLeading: true).trimmingCharacters(in: .whitespaces))
        self.classNames = classes
        
        return self
    }
    
    @discardableResult
    open func removeClass(_ className: String) -> Element {
        let classes = self.classNames
        classes.remove(className)
        self.classNames = classes
        
        return self
    }
    
    @discardableResult
    open func toggleClass(_ className: String) -> Element {
        let classes = self.classNames
        let correctedClassName = className.normalizedWhitespace(stripLeading: true).trimmingCharacters(in: .whitespaces)
        
        if classes.contains(correctedClassName) {
            classes.remove(correctedClassName)
        } else {
            classes.insert(correctedClassName)
        }
        
        self.classNames = classes
        
        return self
    }
    
    /**
     * Value of a form element (input, textarea, etc).
     */
    open var val: String? {
        get {
            if tagName == "textarea" {
                return text
            } else {
                return attr("value")
            }
        }
        set {
            let value = newValue ?? ""
            if tagName == "textarea" {
                text = value
            } else {
                self.attr("value", setValue: value)
            }
        }
    }
    
    open override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        if outputSettings.prettyPrint && (tag.formatAsBlock || (parentElement != nil && parentElement!.tag.formatAsBlock) || outputSettings.outline) {
            if !accum.isEmpty {
                indent(accum: accum, depth: depth, settings: outputSettings)
            }
        }
        
        accum.append("<").append(tagName)
        
        if !attributes.isEmpty {
            accum.append(" ")
            attributes.html(withAccumulated: accum, outputSettings: outputSettings)
        }
        
        if childNodes.isEmpty && tag.isSelfClosing {
            if outputSettings.syntax == OutputSettings.Syntax.html && tag.isEmpty {
                accum += ">"
            } else {
                accum += " />"
            }
        } else {
            accum += ">"
        }
    }
    
    open override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        if !(childNodes.isEmpty && tag.isSelfClosing) {
            let severalChildOrTextNode = childNodes.count > 1 || (childNodes.count == 1 && !(childNodes.first! is TextNode))
            if outputSettings.prettyPrint && (!childNodes.isEmpty &&
                (tag.formatAsBlock || (outputSettings.outline && severalChildOrTextNode))) {
                    indent(accum: accum, depth: depth, settings: outputSettings)
            }
            
            accum += "</" + tagName + ">"
        }
    }
    
    @discardableResult
    open func html(replaceWith newValue: String) -> Element {
        self.removeAll()
        self.append(html: newValue)
        return self
    }
    
    open var html: String {
        let accum = StringBuilder()
        html(appendable: accum)
        return outputSettings.prettyPrint ? accum.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) : accum.stringValue
    }
    
    open override func html(appendable: StringBuilder) {
        for node in childNodes {
            node.outerHTML(accum: appendable)
        }
    }
    
    open override var description: String {
        return outerHTML
    }

    public static func ==(lhs: Element, rhs: Element) -> Bool {
        return lhs.outerHTML == rhs.outerHTML
    }

    public static func !=(lhs: Element, rhs: Element) -> Bool {
        return lhs.outerHTML != rhs.outerHTML
    }
    
    open override func hasSameValue(_ other: Node) -> Bool {
        return super.hasSameValue(other)
    }
}

open class _ElementSafe: Node.Safe {
    
    private let element: Element
    
    init(element: Element) {
        self.element = element
        super.init(node: element)
    }
    
    @discardableResult
    open func append(html: String) throws -> [Node] {
        let nodes = try Parser.Safe.parse(fragmentHTML: html, withContext: element, baseUri: element.baseUri)
        element.append(children: nodes)
        return nodes
    }
    
    @discardableResult
    open func prepend(html: String) throws -> [Node] {
        let nodes = try Parser.Safe.parse(fragmentHTML: html, withContext: element, baseUri: element.baseUri)
        element.insert(children: nodes, at: 0)
        return nodes
    }
    
    @discardableResult
    open func html(replaceWith newValue: String) throws -> Element {
        element.removeAll()
        try self.append(html: newValue)
        return element
    }
}
