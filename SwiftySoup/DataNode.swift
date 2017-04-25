//
//  DataNode.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class DataNode: Node {
    
    static let DATA_KEY = "data"
    
    public init(data: String, baseUri: String?) {
        super.init(baseUri: baseUri, attributes: Attributes())
        self.attributes.put(string: data, forKey: DataNode.DATA_KEY)
    }
    
    public override var nodeName: String { return "#data" }
    
    public var wholeData: String {
        get { return attributes.get(byTag: DataNode.DATA_KEY)!.value! }
        set { self.attributes.put(string: newValue, forKey: DataNode.DATA_KEY) }
    }
    
    public override func outerHTMLHead(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) throws {
        accum.append(wholeData)
    }
    
    public override func outerHTMLTail(accum: StringBuilder, depth: Int, outputSettings: OutputSettings) throws {}
    
    public static func create(fromEncoded encodedData: String, baseUri: String?) -> DataNode {
        let data = Entities.unescape(encodedData)
        return DataNode(data: data, baseUri: baseUri)
    }
}
