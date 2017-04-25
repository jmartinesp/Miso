//
//  Parser.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class Parser {
    
    var treeBuilder: TreeBuilder
    var settings: ParseSettings
    public var errors: ParseErrorList = ParseErrorList.tracking()
    
    public init(treeBuilder: TreeBuilder) {
        self.treeBuilder = treeBuilder
        settings = treeBuilder.defaultSettings
    }
    
    public func parseInput(html: String, baseUri: String?) -> Document {
        return treeBuilder.parse(input: html, baseUri: baseUri, errors: errors, settings: settings)
    }
    
    @discardableResult
    public func trackErrors(count: Int) -> Parser {
        errors = ParseErrorList(maxSize: count)
        return self
    }
    
    /**
     * Parse HTML into a Document.
     *
     * @param html HTML to parse
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return parsed Document
     */
    public static func parse(html: String, baseUri: String?) -> Document {
        let htmlTreeBuilder = HTMLTreeBuilder()
        return htmlTreeBuilder.parse(input: html, baseUri: baseUri, errors: ParseErrorList.noTracking(), settings: htmlTreeBuilder.defaultSettings)
    }
    
    /**
     * Parse a fragment of HTML into a list of nodes. The context element, if supplied, supplies parsing context.
     *
     * @param fragmentHtml the fragment of HTML to parse
     * @param context (optional) the element that this HTML fragment is being parsed for (i.e. for inner HTML). This
     * provides stack context (for implicit element creation).
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return list of nodes parsed from the input HTML. Note that the context element, if supplied, is not modified.
     */
    public static func parse(fragmentHTML: String, withContext context: Element?, baseUri: String?) -> [Node] {
        let htmlTreeBuilder = HTMLTreeBuilder()
        return htmlTreeBuilder.parse(fragment: fragmentHTML, context: context, baseUri: baseUri, errors: ParseErrorList.noTracking(), settings: htmlTreeBuilder.defaultSettings)
    }

    /**
     * Parse a fragment of HTML into a list of nodes. The context element, if supplied, supplies parsing context.
     *
     * @param fragmentHtml the fragment of HTML to parse
     * @param context (optional) the element that this HTML fragment is being parsed for (i.e. for inner HTML). This
     * provides stack context (for implicit element creation).
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     * @param errorList list to add errors to
     *
     * @return list of nodes parsed from the input HTML. Note that the context element, if supplied, is not modified.
     */
    public static func parse(fragmentHTML: String, withContext context: Element?, baseUri: String?, errors: ParseErrorList) -> [Node] {
        let htmlTreeBuilder = HTMLTreeBuilder()
        return htmlTreeBuilder.parse(fragment: fragmentHTML, context: context, baseUri: baseUri, errors: errors, settings: htmlTreeBuilder.defaultSettings)
    }
    
    /**
     * Parse a fragment of XML into a list of nodes.
     *
     * @param fragmentXml the fragment of XML to parse
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     * @return list of nodes parsed from the input XML.
     */
    public static func parse(fragmentXML: String, baseUri: String?) -> [Node] {
        let xmlTreeBuilder = XMLTreeBuilder()
        return xmlTreeBuilder.parse(fragment: fragmentXML, baseUri: baseUri, errors: ParseErrorList.noTracking(), settings: xmlTreeBuilder.defaultSettings)
    }
    
    /**
     * Parse a fragment of HTML into the {@code body} of a Document.
     *
     * @param bodyHtml fragment of HTML
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return Document, with empty head, and HTML parsed into body
     */
    public static func parse(bodyFragment: String, baseUri: String?) -> Document {
        let document = Document.createEmpty(baseUri: baseUri)
        
        let body = document.body
        
        let nodeList = parse(fragmentHTML: bodyFragment, withContext: body, baseUri: baseUri)
        
        for i in (0..<nodeList.count).reversed() {
            nodeList[i].removeFromParent()
        }
        
        for node in nodeList {
            body?.append(childNode: node)
        }
        
        return document
    }
    
    /**
     * Utility method to unescape HTML entities from a string
     * @param string HTML escaped string
     * @param inAttribute if the string is to be escaped in strict mode (as attributes are)
     * @return an unescaped string
     */
    public static func unescape(entities: String, inAttributes: Bool) -> String {
        let tokeniser = Tokeniser(reader: CharacterReader(input: entities), errors: ParseErrorList.noTracking())
        return tokeniser.unescapeEntities(inAttributes: inAttributes)
    }
    
    /**
     * Create a new HTML parser. This parser treats input as HTML5, and enforces the creation of a normalised document,
     * based on a knowledge of the semantics of the incoming tags.
     * @return a new HTML parser.
     */
    public static var htmlParser: Parser {
        return Parser(treeBuilder: HTMLTreeBuilder())
    }
    
    /**
     * Create a new XML parser. This parser assumes no knowledge of the incoming tags and does not treat it as HTML,
     * rather creates a simple tree directly from the input.
     * @return a new simple XML parser.
     */
    public static var xmlParser: Parser {
        return Parser(treeBuilder: XMLTreeBuilder())
    }
    
    
    
}
