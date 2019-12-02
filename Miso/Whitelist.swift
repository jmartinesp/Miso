//
// Created by Jorge Martín Espinosa on 17/4/17.
// Copyright (c) 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

/**
 Whitelists define what HTML (elements and attributes) to allow through the cleaner. Everything else is removed.
 <p>
 Start with one of the defaults:
 </p>
 <ul>
 <li>{@link #none}
 <li>{@link #simpleText}
 <li>{@link #basic}
 <li>{@link #basicWithImages}
 <li>{@link #relaxed}
 </ul>
 <p>
 If you need to allow more through (please be careful!), tweak a base whitelist with:
 </p>
 <ul>
 <li>{@link #addTags}
 <li>{@link #addAttributes}
 <li>{@link #addEnforcedAttribute}
 <li>{@link #addProtocols}
 </ul>
 <p>
 You can remove any setting from an existing whitelist with:
 </p>
 <ul>
 <li>{@link #removeTags}
 <li>{@link #removeAttributes}
 <li>{@link #removeEnforcedAttribute}
 <li>{@link #removeProtocols}
 </ul>

 <p>
 The cleaner and these whitelists assume that you want to clean a <code>body</code> fragment of HTML (to add user
 supplied HTML into a templated page), and not to clean a full HTML document. If the latter is the case, either wrap the
 document HTML around the cleaned body HTML, or create a whitelist that allows <code>html</code> and <code>head</code>
 elements as appropriate.
 </p>
 <p>
 If you are going to extend a whitelist, please be very careful. Make sure you understand what attributes may lead to
 XSS attack vectors. URL attributes are particularly vulnerable and require careful validation. See
 http://ha.ckers.org/xss.html for some XSS attack examples.
 </p>
 @author Jonathan Hedley
 */
open class Whitelist {
    private var tagNames: Set<String> // tags allowed, lower case. e.g. [p, br, span]
    private var attributes: [String : Set<AttributeKey>] // tag -> attribute[]. allowed attributes [href] for a tag.
    private var enforcedAttributes: [String : [AttributeKey : AttributeValue]]  // always set these attribute values
    private var protocols: [String : [AttributeKey : Set<Protocol>]] // allowed URL protocols for attributes
    private var preserveRelativeLinks: Bool // option to preserve relative links

    /**
     This whitelist allows only text nodes: all HTML will be stripped.
     @return whitelist
     */
    public static var none: Whitelist {
        return Whitelist()
    }

    /**
     This whitelist allows only simple text formatting: <code>b, em, i, strong, u</code>. All other HTML (tags and
     attributes) will be removed.
     @return whitelist
     */
    public static let simpleText: Whitelist = {
        return Whitelist().add(tags: "b", "em", "i", "strong", "u")
    }()

    /**
     <p>
     This whitelist allows a fuller range of text nodes: <code>a, b, blockquote, br, cite, code, dd, dl, dt, em, i, li,
     ol, p, pre, q, small, span, strike, strong, sub, sup, u, ul</code>, and appropriate attributes.
     </p>
     <p>
     Links (<code>a</code> elements) can point to <code>http, https, ftp, mailto</code>, and have an enforced
     <code>rel=nofollow</code> attribute.
     </p>
     <p>
     Does not allow images.
     </p>
     @return whitelist
     */
    public static var basic: Whitelist {
        return Whitelist().add(tags: "a", "b", "blockquote", "br", "cite", "code", "dd", "dl", "dt", "em",
                "i", "li", "ol", "p", "pre", "q", "small", "span", "strike", "strong", "sub",
                "sup", "u", "ul")

                .add(to: "a", attributes: "href")
                .add(to: "blockquote", attributes: "cite")
                .add(to: "q", attributes: "cite")

                .add(to: "a", attr: "href", protocols: "ftp", "http", "https", "mailto")
                .add(to: "blockquote", attr: "cite", protocols: "http", "https")
                .add(to: "cite", attr: "cite", protocols: "http", "https")
                .add(to: "a", attr: "rel", enforcedValue: "nofollow")
    }

    /**
     This whitelist allows the same text tags as {@link #basic}, and also allows <code>img</code> tags, with appropriate
     attributes, with <code>src</code> pointing to <code>http</code> or <code>https</code>.
     @return whitelist
     */
    public static var basicWithImages: Whitelist {
        return basic.add(tags: "img")
                .add(to: "img", attributes: "align", "alt", "height", "src", "title", "width")
                .add(to: "img", attr: "src", protocols: "http", "https")
    }

    /**
     This whitelist allows a full range of text and structural body HTML: <code>a, b, blockquote, br, caption, cite,
     code, col, colgroup, dd, div, dl, dt, em, h1, h2, h3, h4, h5, h6, i, img, li, ol, p, pre, q, small, span, strike, strong, sub,
     sup, table, tbody, td, tfoot, th, thead, tr, u, ul</code>
     <p>
     Links do not have an enforced <code>rel=nofollow</code> attribute, but you can add that if desired.
     </p>
     @return whitelist
     */
    public static var relaxed: Whitelist {
        return Whitelist().add(tags: "a", "b", "blockquote", "br", "caption", "cite", "code", "col",
                "colgroup", "dd", "div", "dl", "dt", "em", "h1", "h2", "h3", "h4", "h5", "h6",
                "i", "img", "li", "ol", "p", "pre", "q", "small", "span", "strike", "strong",
                "sub", "sup", "table", "tbody", "td", "tfoot", "th", "thead", "tr", "u", "ul")
                .add(to: "a", attributes: "href", "title", "blockquote", "cite", "col", "span", "width", "colgroup", "span", "width")
                .add(to: "img", attributes: "align", "alt", "height", "src", "title", "width")
                .add(to: "ol", attributes: "start", "type")
                .add(to: "q", attributes: "cite")
                .add(to: "table", attributes: "summary", "width")
                .add(to: "td", attributes: "abbr", "axis", "colspan", "rowspan", "width")

                .add(to: "a", attr: "href", protocols: "ftp", "http", "https", "mailto")
                .add(to: "blockquote", attr: "cite", protocols: "http", "https")
                .add(to: "cite", attr: "cite", protocols: "http", "https")
                .add(to: "img", attr: "src", protocols: "http", "https")
                .add(to: "q", attr: "cite", protocols: "http", "https")
    }

    /**
     Create a new, empty whitelist. Generally it will be better to start with a default prepared whitelist instead.
     @see #basic()
     @see #basicWithImages()
     @see #simpleText()
     @see #relaxed()
     */
    public init() {
        tagNames = Set<String>();
        attributes = [String : Set<AttributeKey>]()
        enforcedAttributes = [String : [AttributeKey : AttributeValue]]()
        protocols = [String : [AttributeKey: Set<Protocol>]]()
        preserveRelativeLinks = false
    }

    /**
     Add a list of allowed elements to a whitelist. (If a tag is not allowed, it will be removed from the HTML.)
     @param tags tag names to allow
     @return this (for chaining)
     */
    open func add(tags: String...) -> Whitelist {
        for tagName in tags {
            tagNames.insert(tagName)
        }
        return self
    }

    /**
     Add a list of allowed elements to a whitelist. (If a tag is not allowed, it will be removed from the HTML.)
     @param tags tag names to allow
     @return this (for chaining)
     */
    open func add(to tag: String, attributes: String...) -> Whitelist {
        tagNames.insert(tag)

        var attrSet = self.attributes[tag]
        if attrSet == nil {
            attrSet = Set()
        }

        for attr in attributes {
            attrSet!.insert(AttributeKey.value(of: attr))
        }

        self.attributes[tag] = attrSet

        return self
    }

    /**
     Remove a list of allowed attributes from a tag. (If an attribute is not allowed on an element, it will be removed.)
     <p>
     E.g.: <code>removeAttributes("a", "href", "class")</code> disallows <code>href</code> and <code>class</code>
     attributes on <code>a</code> tags.
     </p>
     <p>
     To make an attribute invalid for <b>all tags</b>, use the pseudo tag <code>:all</code>, e.g.
     <code>removeAttributes(":all", "class")</code>.
     </p>
     @param tag  The tag the attributes are for.
     @param attributes List of invalid attributes for the tag
     @return this (for chaining)
     */
    open func remove(from tag: String, attributes: String...) -> Whitelist {
        tagNames.insert(tag)

        if var attrSet = self.attributes[tag] {
            for attr in attributes {
                attrSet.remove(AttributeKey.value(of: attr))
            }
            self.attributes[tag] = attrSet
        }

        return self
    }

    /**
     Add an enforced attribute to a tag. An enforced attribute will always be added to the element. If the element
     already has the attribute set, it will be overridden with this value.
     <p>
     E.g.: <code>addEnforcedAttribute("a", "rel", "nofollow")</code> will make all <code>a</code> tags output as
     <code><a href="..." rel="nofollow"></code>
     </p>
     @param tag   The tag the enforced attribute is for. The tag will be added to the allowed tag list if necessary.
     @param attribute   The attribute name
     @param value The enforced attribute value
     @return this (for chaining)
     */
    open func add(to tag: String, attr: String, enforcedValue: String) -> Whitelist {
        tagNames.insert(tag)

        let attrKey = AttributeKey.value(of: attr)
        let attrValue = AttributeValue.value(of: enforcedValue)

        var enforcedAttrs = self.enforcedAttributes[tag]
        if enforcedAttrs == nil {
            enforcedAttrs = [:]
        }

        enforcedAttrs![attrKey] = attrValue

        self.enforcedAttributes[tag] = enforcedAttrs!

        return self
    }

    /**
     Remove a previously configured enforced attribute from a tag.
     @param tag   The tag the enforced attribute is for.
     @param attribute   The attribute name
     @return this (for chaining)
     */
    open func remove(from tag: String, attrEnforced: String) -> Whitelist {
        tagNames.insert(tag)

        let attrKey = AttributeKey.value(of: attrEnforced)

        if var enforcedAttrs = self.enforcedAttributes[tag] {
            enforcedAttrs[attrKey] = nil
            self.enforcedAttributes[tag] = enforcedAttrs
        }

        return self
    }

    open func preserveRelativeLinks(_ value: Bool) -> Whitelist {
        self.preserveRelativeLinks = value
        return self
    }

    /**
     Add allowed URL protocols for an element's URL attribute. This restricts the possible values of the attribute to
     URLs with the defined protocol.
     <p>
     E.g.: <code>addProtocols("a", "href", "ftp", "http", "https")</code>
     </p>
     <p>
     To allow a link to an in-page URL anchor (i.e. <code><a href="#anchor"></code>, add a <code>#</code>:<br>
     E.g.: <code>addProtocols("a", "href", "#")</code>
     </p>
     @param tag       Tag the URL protocol is for
     @param attribute       Attribute name
     @param protocols List of valid protocols
     @return this, for chaining
     */
    open func add(to tag: String, attr: String, protocols: String...) -> Whitelist {
        tagNames.insert(tag)

        var protocolMap = self.protocols[tag]
        if protocolMap == nil {
            protocolMap = [:]
        }

        let attrKey = AttributeKey.value(of: attr)

        for prot in protocols {
            var protocolSet = protocolMap![attrKey] ?? Set()
            protocolSet.insert(Protocol.value(of: prot))
            protocolMap![attrKey] = protocolSet
        }

        self.protocols[tag] = protocolMap

        return self
    }

    /**
     Remove allowed URL protocols for an element's URL attribute. If you remove all protocols for an attribute, that
     attribute will allow any protocol.
     <p>
     E.g.: <code>removeProtocols("a", "href", "ftp")</code>
     </p>
     @param tag Tag the URL protocol is for
     @param attribute Attribute name
     @param removeProtocols List of invalid protocols
     @return this, for chaining
     */
    open func remove(from tag: String, attr: String, protocols: String...) -> Whitelist {
        tagNames.insert(tag)

        let attrKey = AttributeKey.value(of: attr)

        if var attrsMap = self.protocols[tag] {
            if var protocolSet = attrsMap[attrKey] {
                for prot in protocols {
                    protocolSet.remove(Protocol.value(of: prot))
                }
                attrsMap[attrKey] = protocolSet
                self.protocols[tag] = attrsMap
            }
        }

        return self
    }
    
    open func remove(tags: String...) -> Whitelist {
        for tag in tags {
            if tagNames.remove(tag) != nil {
                attributes.removeValue(forKey: tag)
                enforcedAttributes.removeValue(forKey: tag)
                protocols.removeValue(forKey: tag)
            }
        }
        return self
    }

    /**
     * Test if the supplied tag is allowed by this whitelist
     * @param tag test tag
     * @return true if allowed
     */
    func isSafeTag(_ tag: String) -> Bool {
        return tagNames.contains(tag)
    }

    /**
     * Test if the supplied attribute is allowed by this whitelist for this tag
     * @param tagName tag to consider allowing the attribute in
     * @param el element under test, to confirm protocol
     * @param attr attribute under test
     * @return true if allowed
     */
    func isSafeAttribute(_ attr: Attribute, in element: Element, forTag tag: String) -> Bool {
        let tagName = tag.lowercased()
        let key = AttributeKey.value(of: attr.tag.lowercased())

        if let okSet = self.attributes[tagName], okSet.contains(key) {
            if let attrProts = protocols[tagName] {
                // ok if not defined protocol; otherwise test
                return attrProts[key] == nil || testValidProtocol(element: element, attr: attr, protocols: attrProts[key]!)
            } else {
                return true
            }
        }

        // might be an enforced attribute?
        if self.enforcedAttributes[tagName] != nil {
            let expect: Attributes = getEnforcedAttributes(forTag: tag)
            let attrKey = attr.tag

            if expect.hasKeyIgnoreCase(key: attrKey) {
                return expect.get(byTag: attrKey, ignoreCase: true)?.value == attr.value
            }
        }

        // no attributes defined for tag, try :all tag
        return tag != ":all" && isSafeAttribute(attr, in: element, forTag: ":all")
    }

    private func testValidProtocol(element: Element, attr: Attribute, protocols: Set<Protocol>) -> Bool {
        // try to resolve relative urls to abs, and optionally update the attribute so output html has abs.
        // rels without a baseuri get removed
        let value = element.absUrl(forAttributeKey: attr.tag) ?? attr.value
        
        if !preserveRelativeLinks {
            attr.value = value
        }

        for p in protocols {
            var prot = p.description

            if prot == "#" { // allows anchor links
                if isValidAnchor(value) {
                    return true
                } else {
                    continue
                }
            }

            prot += ":"

            if value.lowercased().hasPrefix(prot) {
                return true
            }
        }

        return false
    }

    private func isValidAnchor(_ value: String) -> Bool {
        do {
            let match = try NSRegularExpression(pattern: ".*\\s.*").firstMatch(in: value, range: NSRange(location: 0, length: value.unicodeScalars.count))
            return value.hasPrefix("#") && match == nil
        } catch {
            return false
        }
    }

    func getEnforcedAttributes(forTag tag: String) -> Attributes {
        let attrs = Attributes()

        if let keyVals = enforcedAttributes[tag] {
            for (key, val) in keyVals {
                attrs.put(string: val.value, forKey: key.value)
            }
        }

        return attrs
    }

}

open class AttributeKey: TypedValue {
    override init(value: String) {
        super.init(value: value)
    }

    static func value(of value: String) -> AttributeKey {
        return AttributeKey(value: value)
    }

}

open class AttributeValue: TypedValue {
    override init(value: String) {
        super.init(value: value)
    }

    static func value(of value: String) -> AttributeValue {
        return AttributeValue(value: value)
    }

}

open class Protocol: TypedValue {
    override init(value: String) {
        super.init(value: value)
    }

    static func value(of value: String) -> Protocol {
        return Protocol(value: value)
    }

}

open class TypedValue: Hashable, Equatable, CustomStringConvertible {
    let value: String

    init(value: String) {
        self.value = value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public static func ==(lhs: TypedValue, rhs: TypedValue) -> Bool {
        return lhs.value == rhs.value
    }

    public var description: String {
        return value
    }
}

