//
//  XMLTreeBuilder.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 16/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

/**
 * Use the {@code XMLTreeBuilder} when you want to parse XML without any of the HTML DOM rules being applied to the
 * document.
 * <p>Usage example: {@code Document xmlDoc = Jsoup.parse(html, baseUrl, Parser.xmlParser());}</p>
 *
 * @author Jonathan Hedley
 */
public class XMLTreeBuilder: TreeBuilder {
    
    override var defaultSettings: ParseSettings {
        return .preserveCase
    }
    
    func parse(input: String, baseUri: String?) -> Document {
        return parse(input: input, baseUri: baseUri, errors: ParseErrorList.noTracking(), settings: ParseSettings.preserveCase)
    }
    
    override func initializeParse(input: String, baseUri: String?, errors: ParseErrorList, settings: ParseSettings) {
        super.initializeParse(input: input, baseUri: baseUri, errors: errors, settings: settings)
        
        stack.append(document) // place the document onto the stack. differs from HtmlTreeBuilder (not on stack)
        document.outputSettings.syntax = .xml
    }
    
    override func process(token: Token) -> Bool {
        // start tag, end tag, doctype, comment, character, eof
        switch (token.type) {
        case .StartTag:
            insert(startTag: token as! Token.StartTag)
            break;
        case .EndTag:
            popStackToClose(token as! Token.EndTag)
            break;
        case .Comment:
            insert(comment: token as! Token.Comment)
            break;
        case .Character:
            insert(character: token as! Token.Character)
            break;
        case .Doctype:
            insert(docType: token as! Token.DocType)
            break
        case .EOF: // could put some normalisation here if desired
            break
        }
        return true
    }
    
    func insert(node: Node) {
        currentElement?.append(childNode: node)
    }
    
    @discardableResult
    func insert(startTag: Token.StartTag) -> Element {
        let tag = Tag.valueOf(tagName: startTag.tagName!, settings: settings)
        // todo: wonder if for xml parsing, should treat all tags as unknown? because it's not html.
        let element = Element(tag: tag, baseUri: baseUri, attributes: settings.normalize(attributes: startTag.attributes))
        insert(node: element)
        
        if startTag.selfClosing {
            tokeniser.selfClosingFlagAcknowledged = true
            if !tag.isKnownTag { // unknown tag, remember this is self closing for output. see above.
                tag.selfClosing = true
            }
        } else {
            stack.append(element)
        }
        
        return element
    }
    
    func insert(comment commentToken: Token.Comment) {
        let comment = Comment(data: commentToken.data, baseUri: baseUri)
        
        var toInsert: Node = comment
        if commentToken.bogus {// xml declarations are emitted as bogus comments (which is right for html, but not xml)
            // so we do a bit of a hack and parse the data as an element to pull the attributes out
            let data = comment.data
            
            if data.unicodeScalars.count > 1 && (data.hasPrefix("!") || data.hasPrefix("?")) {
                let validData = data[1..<data.unicodeScalars.count-2]
                let document = Miso.parse(html: "<" + validData + ">", baseUri: baseUri, parser: Parser.xmlParser)
                if let element = document.children.first {
                    toInsert = XmlDeclaration(name: settings.normalize(tagName: element.tagName), baseUri: comment.baseUri, isProcessingInstruction: data.hasPrefix("!"))
                    toInsert.attributes.append(dictionary: element.attributes)
                }
            }
        }
        self.insert(node: toInsert)
    }
    
    func insert(character characterToken: Token.Character) {
        let node = TextNode(text: characterToken.data ?? "", baseUri: baseUri)
        insert(node: node)
    }
    
    func insert(docType docTypeToken: Token.DocType) {
        let documentType = DocumentType(name: settings.normalize(tagName: docTypeToken.name), pubSysKey: docTypeToken.pubSysKey, publicId: docTypeToken.publicIdentifier, systemId: docTypeToken.systemIdentifier, baseUri: baseUri)
        insert(node: documentType)        
    }
    
    /**
     * If the stack contains an element with this tag's name, pop up the stack to remove the first occurrence. If not
     * found, skips.
     *
     * @param endTag
     */
    func popStackToClose(_ endTag: Token.EndTag) {
        let elementName = endTag.tagName
        
        let firstFound = stack.reversed().first(where: { $0.nodeName == elementName })
        
        if firstFound == nil {
            return // not found, skip
        }
        
        for i in (0..<stack.count).reversed() {
            let next = stack[i]
            stack.remove(at: i)
            if next == firstFound {
                break
            }
        }
    }
    
    func parse(fragment: String, baseUri: String?, errors: ParseErrorList, settings: ParseSettings) -> [Node] {
        initializeParse(input: fragment, baseUri: baseUri, errors: errors, settings: settings)
        runParser()
        return document.childNodes
    }
}
