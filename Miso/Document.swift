//
//  Document.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class Document: Element {
    
    public static var defaultOutputSettings : OutputSettings { return OutputSettings() }
    
    public var quirksMode: QuirksMode = .noQuirks
    public var location: String? {
        set { self.baseUri = newValue }
        get { return self.baseUri }
    }
    public var updateMetaCharset = false
    private var _outputSettings: OutputSettings = Document.defaultOutputSettings
    open override var outputSettings: OutputSettings {
        get {
            return _outputSettings
        }
        set {
            _outputSettings = newValue
        }
    }
    
    public var errors: ParseErrorList = ParseErrorList.noTracking()
    
    public init(baseUri: String?) {
        super.init(tag: Tag.valueOf(tagName: "#root", settings: ParseSettings.htmlDefault), baseUri: baseUri)
        self.location = baseUri
    }
    
    public static func createEmpty(baseUri: String?) -> Document {
        let document = Document(baseUri: baseUri)
        
        let html = document.append(element: "html")
        html.append(element: "head")
        html.append(element: "body")
        return document
    }
    
    open var head: Element? {
        return firstElement(byTagName: "head", from: self)
    }
    
    open var body: Element? {
        return firstElement(byTagName: "body", from: self)
    }
    
    open var title: String? {
        get {
            return elements(byTag: "title").first?.text.normalizedWhitespace()
        }
        set {
            if let titleElement = elements(byTag: "title").first {
                titleElement.text = newValue ?? ""
            } else {
                let titleElement = head?.append(element: "title")
                titleElement?.text = newValue ?? ""
            }
        }
    }
    
    open func create(element tagName: String) -> Element {
        return Element(tag: Tag.valueOf(tagName: tagName, settings: ParseSettings.preserveCase), baseUri: baseUri)
    }
    
    /**
     Normalise the document. This happens after the parse phase so generally does not need to be called.
     Moves any text content that is not in the body element into the body.
     @return this document after normalisation
     */
    @discardableResult
    open func normalize() -> Document {
        let htmlElement = firstElement(byTagName: "html", from: self) ?? self.append(element: "html")

        if head == nil {
            htmlElement.append(element: "head")
        }
        
        if body == nil {
            htmlElement.append(element: "body")
        }
        
        // pull text nodes out of root, html, and head els, and push into body. non-text nodes are already taken care
        // of. do in inverse order to maintain text order.
        normalizeTextNodes(of: head!)
        normalizeTextNodes(of: htmlElement)
        normalizeTextNodes(of: self)
        
        normalizeStructure(of: "head", from: htmlElement)
        normalizeStructure(of: "body", from: htmlElement)
        
        ensureMetaCharsetElement()
        
        return self
    }
    
    func normalizeTextNodes(of element: Element) {
        let toMove = childNodes.cast(to: TextNode.self).filter { $0.isBlank }
        
        toMove.reversed().forEach { node in
            element.remove(childNode: node)
            body?.prepend(childNode: TextNode(text: " ", baseUri: nil))
            body?.prepend(childNode: node)
        }
    }
    
    // merge multiple <head> or <body> contents into one, delete the remainder, and ensure they are owned by <html>
    func normalizeStructure(of tag: String, from root: Element) {
        let elements = self.elements(byTag: tag)
        let master = elements.first
        
        var toMove = [Node]()
        
        let dupes = elements[1..<elements.count]
        dupes.forEach { dupe in
            dupe.childNodes.forEach { node in
                toMove.append(node)
            }
            dupe.removeFromParent()
        }
        
        toMove.forEach { node in
            master?.append(childNode: node)
        }
        
        // ensure parented by <html>
        if master != nil && master!.parentNode != root {
            root.append(childNode: master!)
        }
    }

    // fast method to get first by tag name, used for html, head, body finders
    private func firstElement(byTagName tagName: String, from root: Element) -> Element? {
        if root.nodeName == tagName {
            return root
        }
        
        for element in root.children {
            let found = firstElement(byTagName: tagName, from: element)
            if found != nil {
                return found
            }
        }
        
        return nil
    }
 
    /**
     Set the text of the {@code body} of this document. Any existing nodes within the body will be cleared.
     @param text unencoded text
     @return this document
     */
    open override var text: String {
        get {
            return super.text
        }
        set {
            body?.text = newValue
        }
    }
    
    open override var nodeName: String {
        return "#document"
    }
    
    /**
     * Sets the charset used in this document. This method is equivalent
     * to {@link OutputSettings#charset(java.nio.charset.Charset)
     * OutputSettings.charset(Charset)} but in addition it updates the
     * charset / encoding element within the document.
     *
     * <p>This enables
     * {@link #updateMetaCharsetElement(boolean) meta charset update}.</p>
     *
     * <p>If there's no element with charset / encoding information yet it will
     * be created. Obsolete charset / encoding definitions are removed!</p>
     *
     * <p><b>Elements used:</b></p>
     *
     * <ul>
     * <li><b>Html:</b> <i>&lt;meta charset="CHARSET"&gt;</i></li>
     * <li><b>Xml:</b> <i>&lt;?xml version="1.0" encoding="CHARSET"&gt;</i></li>
     * </ul>
     *
     * @param charset Charset
     *
     * @see #updateMetaCharsetElement(boolean)
     * @see OutputSettings#charset(java.nio.charset.Charset)
     */
    open var charset: String.Encoding {
        set {
            updateMetaCharset = true
            outputSettings.charset = newValue
            ensureMetaCharsetElement()
        }
        get {
            return outputSettings.charset
        }
    }
    
    /**
     * Ensures a meta charset (html) or xml declaration (xml) with the current
     * encoding used. This only applies with
     * {@link #updateMetaCharsetElement(boolean) updateMetaCharset} set to
     * <tt>true</tt>, otherwise this method does nothing.
     *
     * <ul>
     * <li>An existing element gets updated with the current charset</li>
     * <li>If there's no element yet it will be inserted</li>
     * <li>Obsolete elements are removed</li>
     * </ul>
     *
     * <p><b>Elements used:</b></p>
     *
     * <ul>
     * <li><b>Html:</b> <i>&lt;meta charset="CHARSET"&gt;</i></li>
     * <li><b>Xml:</b> <i>&lt;?xml version="1.0" encoding="CHARSET"&gt;</i></li>
     * </ul>
     */
    private func ensureMetaCharsetElement() {
        if updateMetaCharset {
            let syntax = outputSettings.syntax
            
            switch syntax {
            case .html:
                if let metaCharset = select("meta[charset]").first {
                    metaCharset.attr("charset", setValue: charset.displayName)
                } else {
                    let metaCharset = self.head?.append(element: "meta")
                    metaCharset?.attr("charset", setValue: charset.displayName)
                }
                
                // Remove obsolete elements
                select("meta[name=charset]").removeFromParent()
                break
            case .xml:
                if let declaration = childNodes.first as? XmlDeclaration {
                    if declaration.name == "xml" {
                        declaration.attr("encoding", setValue: charset.displayName)
                    
                        if declaration.attr("version") != nil {
                            declaration.attr("version", setValue: "1.0")
                        }
                        
                    } else {
                        let declaration = XmlDeclaration(name: "xml", baseUri: baseUri, isProcessingInstruction: false)
                        declaration.attr("version", setValue: "1.0")
                        declaration.attr("encoding", setValue: charset.displayName)
                        
                        prepend(childNode: declaration)
                    }
                } else {
                    let declaration = XmlDeclaration(name: "xml", baseUri: baseUri, isProcessingInstruction: false)
                    declaration.attr("version", setValue: "1.0")
                    declaration.attr("encoding", setValue: charset.displayName)
                    
                    prepend(childNode: declaration)
                }
                break
            }
        }
    }
    
    open override var outerHTML: String {
        return super.html
    }
    
}

public class OutputSettings {
    public var indentAmount = 1
    public var escapeMode: Entities.EscapeMode = .base
    public var prettyPrint = true
    public var outline = false
    public var syntax: Syntax = .html
    public var charset: String.Encoding = .utf8
    
    public enum Syntax {
        case html
        case xml
    }
}

public enum QuirksMode {
    case noQuirks, quirks, limitedQuirks
}
