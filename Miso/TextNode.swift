//
//  TextNode.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class TextNode: Node {
    
    public static let TEXT_KEY = "text"
    
    private var _text: String
    
    public init(text: String, baseUri: String?) {
        self._text = text
        super.init(baseUri: baseUri, attributes: Attributes())
        
        attributes.put(string: text, forKey: TextNode.TEXT_KEY)
    }
    
    override open var nodeName: String { return "#text" }
    
    open var text: String {
        get {
            return wholeText.normalizedWhitespace()
        }
        set {
            self._text = newValue
            attributes.put(string: newValue, forKey: TextNode.TEXT_KEY)
        }
    }
    
    open func text(replaceWith newValue: String) {
        self.text = newValue
    }
    
    open var wholeText: String {
        let attributeText = attributes[TextNode.TEXT_KEY]?.value
        return attributeText ?? self.text
    }
    
    open var isBlank: Bool {
        let wholeText = self.wholeText
        
        if wholeText.isEmpty { return true }
        
        if wholeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }
    
    /**
     * Split this text node into two nodes at the specified string offset. After splitting, this node will contain the
     * original text up to the offset, and will have a new text node sibling containing the text after the offset.
     * @param offset string offset point to split node at.
     * @return the newly created text node containing the text after the offset.
     */
    @discardableResult
    open func splitText(atOffset offset: Int) -> TextNode {
        
        let wholeText = self.wholeText
        
        let head = wholeText[0..<offset]
        let tail = wholeText[offset..<wholeText.unicodeScalars.count]
        
        text = head
        let tailNode = TextNode(text: tail, baseUri: baseUri)
        guard siblingIndex != nil else { return tailNode }
        parentNode?.insert(childNode: tailNode, at: siblingIndex! + 1)
        
        return tailNode
    }
    
    open override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        let parentElement = parentNode as? Element
        if outputSettings.prettyPrint && (siblingIndex == 0 && parentElement != nil && parentElement!.tag.formatAsBlock && !isBlank) ||
            (outputSettings.outline && !siblingNodes.isEmpty && !isBlank) {
            indent(accum: accum, depth: depth, settings: outputSettings)
        }
        
        let normalizeWhite = outputSettings.prettyPrint && parentElement != nil && !Element.preserveWhitespace(in: parentElement!)
        Entities.escape(accum: accum,
                        string: wholeText,
                        outputSettings: outputSettings,
                        inAttribute: false,
                        normalizeWhite: normalizeWhite,
                        stripLeadingWhite: false)
    }
    
    open override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        
    }
    
    static func normalizeWhitespace(text: String) -> String {
        return text.normalizedWhitespace(stripLeading: false)
    }
    
    static func stripLeadingWhitespace(text: String) -> String {
        return text.replaceFirst(regex: "^\\s+", by: "")
    }
    
    static func lastCharIsWhitespace(text: String) -> Bool {
        return text.unicodeScalars.last?.isWhitespace ?? false
    }
    
    
}
