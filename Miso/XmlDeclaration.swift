//
//  XmlDeclaration.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 14/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class XmlDeclaration: Node {
    public let name: String
    public let isProcessingInstruction: Bool
    
    init(name: String, baseUri: String?, isProcessingInstruction: Bool) {
        self.name = name
        self.isProcessingInstruction = isProcessingInstruction
        super.init(baseUri: baseUri, attributes: Attributes())
    }
    
    public override var nodeName: String {
        return "#declaration"
    }
    
    public var wholeDeclaration: String {
        return attributes.html.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        accum.append("<").append(isProcessingInstruction ? "!" : "?").append(name).append(" ")
        attributes.html(withAccumulated: accum, outputSettings: outputSettings)
        accum.append(isProcessingInstruction ? "!" : "?").append(">")
    }
    
    public override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {}
    
    public override var description: String {
        return outerHTML
    }
}
