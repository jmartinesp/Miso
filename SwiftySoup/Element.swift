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
public class Element: Node {
    
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
    
    public override var nodeName: String {
        return tag.tagName
    }
    
    public var tagName: String {
        set {
            tag = Tag.valueOf(tagName: newValue)
        }
        get {
            return tag.tagName
        }
    }
    
    public var isBlock: Bool {
        return tag.isBlock
    }
    
    public var id: String? {
        return attributes["id"]?.value
    }
    
    @discardableResult
    public func attr(_ name: String, setValue value: Bool) -> Element {
        attributes.put(bool: value, forKey: name)
        return self
    }
    
    @discardableResult
    public override func attr(_ name: String, setValue value: String) -> Element {
        attributes.put(string: value, forKey: name)
        return self
    }
    
    public var dataset: Attributes.DataSet {
        return attributes.dataset
    }
    
    public var parentElement: Element? {
        return parentNode as? Element
    }
    
    public var parents: Elements {
        var elements = Elements()
        
        Element.accumulateParents(element: self, parents: &elements)
        
        return elements
    }
    
    private static func accumulateParents(element: Element, parents: inout Elements) {
        guard let parent = element.parentNode as? Element, parent.tagName != "#root" else { return }
        
        parents.append(parent)
        
        accumulateParents(element: parent, parents: &parents)
    }
    
    public var textNodes: [TextNode] {
        return childNodes.filter { $0 is TextNode }.map { $0 as! TextNode }
    }
    
    public var dataNodes: [DataNode] {
        return childNodes.filter { $0 is DataNode }.map { $0 as! DataNode }
    }
    
    public func select(_ cssSelector: String) -> Elements {
        return Selector.select(using: cssSelector, from: self)
    }
    
    public func matches(query: String) -> Bool {
        do {
            return try matches(evaluator: QueryParser.parse(query: query))
        } catch {
            print(error)
            return false
        }
    }
    
    public func matches(evaluator: EvaluatorProtocol) -> Bool {
        return evaluator.matches(root: (self.root as? Element), and: self)
    }
    
    @discardableResult
    public func append(element tagName: String) -> Element {
        let element = Element(tag: Tag.valueOf(tagName: tagName), baseUri: baseUri)
        append(childNode: element)
        return element
    }
    
    @discardableResult
    public func prepend(element tagName: String) -> Element {
        let element = Element(tag: Tag.valueOf(tagName: tagName), baseUri: baseUri)
        insert(childNode: element, at: 0)
        return element
    }
    
    @discardableResult
    public func append(text: String) -> TextNode {
        let textNode = TextNode(text: text, baseUri: baseUri)
        append(childNode: textNode)
        return textNode
    }
    
    @discardableResult
    public func prepend(text: String) -> TextNode {
        let textNode = TextNode(text: text, baseUri: baseUri)
        insert(childNode: textNode, at: 0)
        return textNode
    }
    
    @discardableResult
    public func append(html: String) -> [Node] {
        let nodes = Parser.parse(fragmentHTML: html, withContext: self, baseUri: baseUri)
        append(children: nodes)
        return nodes
    }
    
    @discardableResult
    public func prepend(html: String) -> [Node] {
        let nodes = Parser.parse(fragmentHTML: html, withContext: self, baseUri: baseUri)
        insert(children: nodes, at: 0)
        return nodes
    }
    
    @discardableResult
    public func prepend(childNode: Node) -> Node {
        insert(childNode: childNode, at: 0)
        return childNode
    }
    
    public func removeAll() {
        self.childNodes.removeAll()
    }
    
    public var cssSelector: String {
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
    
    public var siblingElements: Elements {
        guard parentNode != nil else {
            return Elements()
        }
        
        let elements = Elements()
        let siblings = parentNode!.childNodes.cast(to: Element.self)
        siblings.filter { $0 != self }.forEach { elements.append($0) }
        
        return elements
    }
    
    public var nextSiblingElement: Element? {
        guard let siblingIndex = self.siblingIndex else { return nil }
        
        return parentNode?.childNodes.cast(to: Element.self).first{
            $0.siblingIndex == siblingIndex+1
        }
    }
    
    public var previousSiblingElement: Element? {
        guard let siblingIndex = self.siblingIndex else { return nil }
        
        return parentNode?.childNodes.cast(to: Element.self).first{
            $0.siblingIndex == siblingIndex - 1
        }
    }
    
    public var firstSiblingElement: Element? {
        return siblingElements.first
    }
    
    public var lastSiblingElement: Element? {
        return siblingElements.last
    }
    
    /**
     * Get the list index of this element in its element sibling list. I.e. if this is the first element
     * sibling, returns 0.
     * @return position in element sibling list
     */
    public var elementSiblingIndex: Int? {
        return parentNode?.childNodes.cast(to: Element.self).index(of: self)
    }
    
    public func elements(byTag tagName: String) -> Elements {
        let tagName = tagName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.TagIs(tagName: tagName), root: self)
    }
    
    public func element(byId id: String) -> Element? {
        let id = id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.IdIs(id: id), root: self).first
    }
    
    public func elements(byClass className: String) -> Elements {
        let className = className.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasClass(className: className), root: self)
    }
    
    public func elements(byAttributeName attrName: String) -> Elements {
        let attrName = attrName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttribute(attrName: attrName), root: self)
    }
    
    public func elements(byAttributeStartingWith attrPrefix: String) -> Elements {
        let attrPrefix = attrPrefix.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeStartingWith(attrStart: attrPrefix), root: self)
    }
    
    public func elements(byValue attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValue(key: key, value: attrValue), root: self)
    }
    
    public func elements(byValueNot attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValueNot(key: key, value: attrValue), root: self)
    }
    
    public func elements(byValueStarting attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValueStartingWith(key: key, value: attrValue), root: self)
    }
    
    public func elements(byValueEnding attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValueEndingWith(key: key, value: attrValue), root: self)
    }
    
    public func elements(byValueContaining attrValue: String, key: String) -> Elements {
        let attrValue = attrValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValueContaining(key: key, value: attrValue), root: self)
    }
    
    public func elements(byValueMathing pattern: String, key: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.HasAttributeWithValueMatching(key: key, pattern: pattern), root: self)
    }
    
    //======================================================================
    // MARK: Indexes
    //======================================================================
    
    public func elements(byIndexLessThan index: Int) -> Elements {
        return Collector.collect(evaluator: Evaluator.IndexLessThan(index: index), root: self)
    }
    
    public func elements(byIndexGreaterThan index: Int) -> Elements {
        return Collector.collect(evaluator: Evaluator.IndexGreaterThan(index: index), root: self)
    }
    
    public func elements(byIndexEqualsTo index: Int) -> Elements {
        return Collector.collect(evaluator: Evaluator.IndexEquals(index: index), root: self)
    }
    
    //======================================================================
    // MARK: Containing
    //======================================================================
    
    public func elements(containingText text: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.ContainsText(searchText: text), root: self)
    }
    
    public func elements(containingOwnText text: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.ContainsOwnText(searchOwnText: text), root: self)
    }
    
    //======================================================================
    // MARK: MatchingText
    //======================================================================
    
    public func elements(matchingText pattern: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.MatchesText(pattern: pattern), root: self)
    }
    
    public func elements(matchingOwnText pattern: String) -> Elements {
        return Collector.collect(evaluator: Evaluator.MatchesOwnText(pattern: pattern), root: self)
    }
    
    //======================================================================
    // MARK: Other
    //======================================================================
    
    public var allElements: Elements {
        return Collector.collect(evaluator: Evaluator.AllElements(), root: self)
    }
    
    public var text: String {
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
    
    public var ownText: String {
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
    
    public var hasText: Bool {
        for node in childNodes {
            if let textNode = node as? TextNode, !textNode.isBlank {
                return true
            } else if let element = node as? Element, element.hasText {
                return true
            }
        }
        return false
    }
    
    public var data: String {
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
    
    public var className: String {
        return self.attr("class")?
            .normalizedWhitespace(stripLeading: true)
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").joined(" ")
            .trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    public var classNames: OrderedSet<String> {
        get {
            let set = OrderedSet<String>()
            (attributes.get(byTag: "class")?.value?
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
    
    public func hasClass(_ className: String) -> Bool {
        guard let classAttr = attributes.get(byTag: "class", ignoreCase: true)?.value else { return false }
        
        guard !classAttr.isEmpty && classAttr.unicodeScalars.count >= className.unicodeScalars.count else { return false }
        
        return classAttr.normalizedWhitespace(stripLeading: true).trimmingCharacters(in: .whitespaces).components(separatedBy: " ").contains(className)
    }
    
    public func addClass(_ className: String) -> Element {
        var classes = self.classNames
        classes.insert(className.normalizedWhitespace(stripLeading: true).trimmingCharacters(in: .whitespaces))
        self.classNames = classes
        
        return self
    }
    
    public func removeClass(_ className: String) -> Element {
        var classes = self.classNames
        classes.remove(className)
        self.classNames = classes
        
        return self
    }
    
    public func toggleClass(_ className: String) -> Element {
        var classes = self.classNames
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
    public var val: String? {
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
    
    public override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) throws {
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
    
    public override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) throws {
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
    public func html(replaceWith newValue: String) -> Element {
        self.removeAll()
        self.append(html: newValue)
        return self
    }
    
    public var html: String {
        let accum = StringBuilder()
        html(appendable: accum)
        return outputSettings.prettyPrint ? accum.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) : accum.stringValue
    }
    
    public override func html(appendable: StringBuilder) {
        for node in childNodes {
            node.outerHTML(accum: appendable)
        }
    }
    
    public override var description: String {
        return outerHTML
    }
    
    public override var hashValue: Int {
        return description.hashValue
    }

    public static func ==(lhs: Element, rhs: Element) -> Bool {
        return lhs.outerHTML == rhs.outerHTML
    }

    public static func !=(lhs: Element, rhs: Element) -> Bool {
        return lhs.outerHTML != rhs.outerHTML
    }
    
    public override func hasSameValue(_ other: Node) -> Bool {
        return super.hasSameValue(other)
    }
}
