//
//  DocumentType.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 15/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

/**
 * A {@code <!DOCTYPE>} node.
 */
public class DocumentType: Node {
    public static let PUBLIC_KEY = "PUBLIC"
    public static let SYSTEM_KEY = "SYSTEM"
    private static let NAME = "name"
    private static let PUB_SYS_KEY = "pubSysKey" // PUBLIC or SYSTEM
    private static let PUBLIC_ID = "publicId"
    private static let SYSTEM_ID = "systemId"
    // todo: quirk mode from publicId and systemId
    
    /**
     * Create a new doctype element.
     * @param name the doctype's name
     * @param publicId the doctype's public ID
     * @param systemId the doctype's system ID
     * @param baseUri the doctype's base URI
     */
    public init(name: String, publicId: String, systemId: String, baseUri: String?) {
        super.init(baseUri: baseUri, attributes: Attributes())
        
        attr(DocumentType.NAME, setValue: name)
        attr(DocumentType.PUBLIC_ID, setValue: publicId)
        
        if has(attr: DocumentType.PUBLIC_ID) {
            attr(DocumentType.PUB_SYS_KEY, setValue: DocumentType.PUBLIC_KEY)
        }
        
        attr(DocumentType.SYSTEM_ID, setValue: systemId)
    }
    
    public init(name: String, pubSysKey: String?, publicId: String, systemId: String, baseUri: String?) {
        super.init(baseUri: baseUri, attributes: Attributes())
        
        attr(DocumentType.NAME, setValue: name)
        attr(DocumentType.PUBLIC_ID, setValue: publicId)
        if pubSysKey != nil {
            attr(DocumentType.PUB_SYS_KEY, setValue: pubSysKey!)
        }
        attr(DocumentType.SYSTEM_ID, setValue: systemId)
    }
    
    public override var nodeName: String {
        return "#doctype"
    }
    
    public override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        if outputSettings.syntax == .html && !has(attr: DocumentType.PUBLIC_ID) && !has(attr: DocumentType.SYSTEM_ID) {
            // looks like a html5 doctype, go lowercase for aesthetics
            accum.append("<!doctype")
        } else {
            accum.append("<!DOCTYPE")
        }
        
        if has(attr: DocumentType.NAME) {
            accum.append(" ").append(attr(DocumentType.NAME) ?? "")
        }
        
        if has(attr: DocumentType.PUB_SYS_KEY) {
            accum.append(" ").append(attr(DocumentType.PUB_SYS_KEY) ?? "")
        }
        
        if has(attr: DocumentType.PUBLIC_ID) {
            accum.append(" \"").append(attr(DocumentType.PUBLIC_ID) ?? "").append("\"")
        }
        
        if has(attr: DocumentType.SYSTEM_ID) {
            accum.append(" \"").append(attr(DocumentType.SYSTEM_ID) ?? "").append("\"")
        }
        
        accum.append(">")
    }
    
    public override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {}
    
    public override func has(attr name: String) -> Bool {
        let attr = self.attr(name)
        return attr != nil && !attr!.isEmpty
    }
    
    
 
}
