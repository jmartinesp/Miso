//
//  Comment.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 16/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

/**
 A comment node.
 @author Jonathan Hedley, jonathan@hedley.net */

public class Comment: Node {
    private static let COMMENT_KEY: String = "comment"
    
    /**
     Create a new comment node.
     @param data The contents of the comment
     @param baseUri base URI
     */
    public init(data: String, baseUri: String?) {
        super.init(baseUri: baseUri, attributes: Attributes())
        
        attributes.put(string: data, forKey: Comment.COMMENT_KEY)
    }
    
    public override var nodeName: String {
        return "#comment"
    }
    
    public var data: String {
        get {
            return attributes.get(byTag: Comment.COMMENT_KEY)!.value
        }
        set {
            attributes.put(string: newValue, forKey: Comment.COMMENT_KEY)
        }
    }
    
    public override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        if outputSettings.prettyPrint {
            indent(accum: accum, depth: depth, settings: outputSettings)
        }
        
        accum.append("<!--").append(data).append("-->")
    }
    
    public override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {}
    
    public override var description: String {
        return outerHTML
    }
    
}
