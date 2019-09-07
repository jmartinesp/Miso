//
//  Attributes.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class Attribute: CustomStringConvertible, Equatable, Hashable {
    
    public static let BOOL_ATTRIBUTES = ["allowfullscreen", "async", "autofocus", "checked", "compact", "declare", "default", "defer", "disabled",
                                         "formnovalidate", "hidden", "inert", "ismap", "itemscope", "multiple", "muted", "nohref", "noresize",
                                         "noshade", "novalidate", "nowrap", "open", "readonly", "required", "reversed", "seamless", "selected",
                                         "sortable", "truespeed", "typemustmatch"]
    
    public let tag: String
    public var value: String
    
    public init(tag: String, value: String) {
        self.tag = tag        
        self.value = value
    }
    
    open var html: String {
        let accumulated = StringBuilder()
        html(withAccumulated: accumulated, outputSettings: Document.defaultOutputSettings)
        return accumulated.stringValue
    }
    
    func html(withAccumulated accumulated: StringBuilder, outputSettings: OutputSettings) {
        accumulated += tag
        
        if !shouldCollapseAttribute(settings: outputSettings) {
            accumulated.append("=\"")
            Entities.escape(accum: accumulated, string: value, outputSettings: outputSettings,
                            inAttribute: true, normalizeWhite: false, stripLeadingWhite: false)
            accumulated.append("\"")
        }
    }
    
    private func shouldCollapseAttribute(settings: OutputSettings) -> Bool {
        return (value.isEmpty || value.lowercased() == tag.lowercased())
            && settings.syntax == .html && isBoolAttribute
    }
    
    open var isBoolAttribute: Bool {
        return Attribute.BOOL_ATTRIBUTES.contains(self.tag)
    }
    
    open var description: String {
        return html
    }
    
    public static func ==(lhs: Attribute, rhs: Attribute) -> Bool {
        return lhs.tag == rhs.tag
    }
    
    public static func !=(lhs: Attribute, rhs: Attribute) -> Bool {
        return !(lhs == rhs)
    }
    
    open func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
    }
    
}

open class BooleanAttribute: Attribute {
    
    init(tag: String) {
        super.init(tag: tag, value: "")
    }
    
    override open var isBoolAttribute: Bool { return true }
}

public class Attributes: OrderedDictionary<String, Attribute>, Equatable {
    
    private var attributes: [String : Attribute] {
        set { self.dictionary = newValue }
        get { return dictionary }
    }
    
    public func put(bool: Bool, forKey key: String) {
        let attribute = BooleanAttribute(tag: key)
        if bool {
            self[key] = attribute
        } else {
            self[key] = nil
        }
    }
    
    public func put(string: String, forKey key: String) {
        let attribute = Attribute(tag: key , value: string)
        self[key] = attribute
    }
    
    public func contains(key: String, ignoreCase: Bool) -> Bool {
        if !ignoreCase {
            return self.keys.contains(key)
        } else {
            return self.findLowercasedKey(key: key) != nil
        }
    }
    
    public func get(byTag tag: String, ignoreCase: Bool = true) -> Attribute? {
        if ignoreCase {
            if let realKey = self.findLowercasedKey(key: tag) {
                return self[realKey]
            } else {
                return nil
            }
        } else {
            return self[tag]
        }
    }
    
    public override subscript (key: String) -> Attribute? {
        get {
            return super[key]
        }
        set {
            guard key != "data-" else { return }
            
            super[key] = newValue
        }
    }
    
    func findLowercasedKey(key: String) -> String? {
        let lowercasedKey = (key).lowercased()
        return self.keys.first { ($0).lowercased() == lowercasedKey }
    }
    
    public func hasKeyIgnoreCase(key: String) -> Bool {
        return self.findLowercasedKey(key: key) != nil
    }
    
    func html(withAccumulated accumulated: StringBuilder, outputSettings: OutputSettings) {
        let acc = accumulated
        guard !self.isEmpty else { return }
        
        for value in self.orderedValues {
            (value as Attribute).html(withAccumulated: accumulated, outputSettings: outputSettings)
            accumulated.append(" ")
        }
        
        acc.remove(at: acc.count-1)
    }
    
    public var html: String {
        let accumulated = StringBuilder(string: " ")
        self.html(withAccumulated: accumulated, outputSettings: Document.defaultOutputSettings)
        return accumulated.stringValue
    }
    
    public var dataset : DataSet {
        return DataSet(attributes: self)
    }
    
    public func removeAll() {
        self.attributes.removeAll()
    }
    
    public static func ==(lhs: Attributes, rhs: Attributes) -> Bool {
        return rhs.attributes == lhs.attributes
    }
    
    public static func !=(lhs: Attributes, rhs: Attributes) -> Bool {
        return rhs.attributes != lhs.attributes
    }
    
    public struct DataSet {
        
        weak var attributes: Attributes?
        
        init(attributes: Attributes) {
            self.attributes = attributes
        }
        
        subscript (key: String) -> String? {
            set {
                if newValue != nil {
                    self.attributes?["data-"+key] = Attribute(tag: "data-"+key, value: newValue!)
                } else {
                    self.attributes?["data-"+key] = nil
                }
            }
            get {
                return self.attributes?["data-"+key]?.value
            }
        }
        
        public var keys: Dictionary<String, Attribute>.Keys? {
            return self.attributes?.keys
        }
        
        public var values: Dictionary<String, Attribute>.Values? {
            return self.attributes?.values
        }
        
        public var isEmpty: Bool { return self.attributes?.isEmpty ?? true }
        
        public var count: Int {
            return self.attributes?.keys.filter({(key: String) -> Bool in
                key.hasPrefix("data-") && key.unicodeScalars.count > "data-".unicodeScalars.count
            }).count ?? 0
        }
        
    }
    
}
