//
//  DataNode.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class DataNode: Node {
    
    static let DATA_KEY = "data"
    
    public init(data: String, baseUri: String?) {
        super.init(baseUri: baseUri)
        attr(DataNode.DATA_KEY, setValue: data)
    }
    
    open override var nodeName: String { return "#data" }
    
    open var wholeData: String {
        get { return attributes?.get(byTag: DataNode.DATA_KEY)?.value ?? "" }
        set { self.attr(DataNode.DATA_KEY, setValue: newValue) }
    }
    
    open override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {
        accum.append(wholeData)
    }
    
    open override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) {}
    
    public static func create(fromEncoded encodedData: String, baseUri: String?) -> DataNode {
        let data = Entities.unescape(encodedData)
        return DataNode(data: data, baseUri: baseUri)
    }
}
