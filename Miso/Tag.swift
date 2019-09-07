//
//  Tag.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class Tag: Equatable, Hashable, CustomStringConvertible {
    
    private static let blockTags = [
        "html", "head", "body", "frameset", "script", "noscript", "style", "meta", "link", "title", "frame",
        "noframes", "section", "nav", "aside", "hgroup", "header", "footer", "p", "h1", "h2", "h3", "h4", "h5", "h6",
        "ul", "ol", "pre", "div", "blockquote", "hr", "address", "figure", "figcaption", "form", "fieldset", "ins",
        "del", "dl", "dt", "dd", "li", "table", "caption", "thead", "tfoot", "tbody", "colgroup", "col", "tr", "th",
        "td", "video", "audio", "canvas", "details", "menu", "plaintext", "template", "article", "main",
        "svg", "math"
        ]
    private static let inlineTags = [
        "object", "base", "font", "tt", "i", "b", "u", "big", "small", "em", "strong", "dfn", "code", "samp", "kbd",
        "var", "cite", "abbr", "time", "acronym", "mark", "ruby", "rt", "rp", "a", "img", "br", "wbr", "map", "q",
        "sub", "sup", "bdo", "iframe", "embed", "span", "input", "select", "textarea", "label", "button", "optgroup",
        "option", "legend", "datalist", "keygen", "output", "progress", "meter", "area", "param", "source", "track",
        "summary", "command", "device", "area", "basefont", "bgsound", "menuitem", "param", "source", "track",
        "data", "bdi", "s"
        ]
    private static let emptyTags = [
        "meta", "link", "base", "frame", "img", "br", "wbr", "embed", "hr", "input", "keygen", "col", "command",
        "device", "area", "basefont", "bgsound", "menuitem", "param", "source", "track"
        ]
    private static let formatAsInlineTags = [
        "title", "a", "p", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "address", "li", "th", "td", "script", "style",
        "ins", "del", "s"
        ]
    private static let preserveWhitespaceTags = [
        "pre", "plaintext", "title", "textarea"
        // script is not here as it is a data node, which always preserve whitespace
        ]
    // todo: I think we just need submit tags, and can scrub listed
    private static let formListedTags = [
        "button", "fieldset", "input", "keygen", "object", "output", "select", "textarea"
        ]
    private static let formSubmitTags = [
        "input", "keygen", "object", "select", "textarea"
        ]
    
    private static var tags: [String : Tag] = {
        var tags = [String : Tag]()
            
        // Create
        blockTags.forEach {
            let tag = Tag(tagName: $0)
            tags[tag.tagName] = tag
        }
        
        inlineTags.forEach {
            let tag = Tag(tagName: $0)
            tag.isBlock = false
            tag.formatAsBlock = false
            tags[tag.tagName] = tag
        }
        
        // Modify
        emptyTags.forEach {
            guard let tag = tags[$0] else { return }
            tag.canContainInline = false
            tag.isEmpty = true
            tags[tag.tagName] = tag
        }
        
        formatAsInlineTags.forEach {
            guard let tag = tags[$0] else { return }
            tag.formatAsBlock = false
            tags[tag.tagName] = tag
        }
        
        preserveWhitespaceTags.forEach {
            guard let tag = tags[$0] else { return }
            tag.preserveWhitespace = true
            tags[tag.tagName] = tag
        }
        
        formListedTags.forEach {
            guard let tag = tags[$0] else { return }
            tag.isFormListed = true
            tags[tag.tagName] = tag
        }
        
        formSubmitTags.forEach {
            guard let tag = tags[$0] else { return }
            tag.isFormSubmittable = true
            tags[tag.tagName] = tag
        }
        
        return tags
    }()
    
    let tagName: String
    open var isBlock = true              // block or line
    open var formatAsBlock = true        // should be formatted as a block
    open var canContainInline = true     // only pcdata if not
    open var isEmpty = false             // can hold nothing; e.g. img
    var selfClosing = false                // can self close (<foo />). used for unknown tags that self close, without forcing them as empty.
    open var preserveWhitespace = false  // for pre, textarea, script etc
    open var isFormListed = false        // a control that appears in forms: input, textarea, output etc
    open var isFormSubmittable = false   // a control that can be submitted in a form: input etc
    
    init(tagName: String) {
        self.tagName = tagName
    }
    
    open var isInline: Bool { return !isBlock }
    open var isData: Bool { return !canContainInline && !isEmpty }
    open var isSelfClosing: Bool { return isEmpty || selfClosing }
    open var isKnownTag: Bool { return Tag.isKnownTag(tagName: tagName) }
    
    public static func isKnownTag(tagName: String) -> Bool {
        return Tag.tags.keys.contains(tagName)
    }
    
    public static func ==(lhs: Tag, rhs: Tag) -> Bool {
        if lhs === rhs { return true }
        
        if lhs.tagName != rhs.tagName { return false }
        if lhs.canContainInline != rhs.canContainInline { return false }
        if lhs.isEmpty != rhs.isEmpty { return false }
        if lhs.formatAsBlock != rhs.formatAsBlock { return false }
        if lhs.isBlock != rhs.isBlock { return false }
        if lhs.preserveWhitespace != rhs.preserveWhitespace { return false }
        if lhs.selfClosing != rhs.selfClosing { return false }
        if lhs.isFormListed != rhs.isFormListed { return false }
        if lhs.isFormSubmittable != rhs.isFormSubmittable { return false }
        
        return true
    }
    
    public static func !=(lhs: Tag, rhs: Tag) -> Bool {
        return !(lhs == rhs)
    }
    
    open func hash(into hasher: inout Hasher) {
        hasher.combine(tagName)
        hasher.combine(isBlock)
        hasher.combine(formatAsBlock)
        hasher.combine(canContainInline)
        hasher.combine(isEmpty)
        hasher.combine(selfClosing)
        hasher.combine(preserveWhitespace)
        hasher.combine(isFormListed)
        hasher.combine(isFormSubmittable)
    }
    
    open var description: String {
        return tagName
    }
    
    public static func valueOf(tagName: String, settings: ParseSettings) -> Tag {
        var tagName = tagName
        var tag: Tag
        
        if tags.keys.contains(tagName) {
            tag = tags[tagName]!
        } else {
            tagName = settings.normalize(tagName: tagName)
            
            if let tagFound = tags[tagName] {
                tag = tagFound
            } else {
                tag = Tag(tagName: tagName)
                tag.isBlock = false
            }
        }
        
        return tag
    }
    
    public static func valueOf(tagName: String) -> Tag {
        return Tag.valueOf(tagName: tagName, settings: ParseSettings.preserveCase)
    }
    
    public static func register(tag: Tag) {
        Tag.tags[tag.tagName] = tag
    }
}
