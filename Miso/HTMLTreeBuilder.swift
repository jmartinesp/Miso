//
//  HTMLTreeBuilder.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 15/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

class HTMLTreeBuilder: TreeBuilder, CustomStringConvertible {
    
    // tag searches
    public static let TagsSearchInScope = ["applet", "caption", "html", "table", "td", "th", "marquee", "object"]
    private static let TagSearchList = ["ol", "ul"]
    private static let TagSearchButton = ["button"]
    private static let TagSearchTableScope = ["html", "table"]
    private static let TagSearchSelectScope = ["optgroup", "option"]
    private static let TagSearchEndTags = ["dd", "dt", "li", "option", "optgroup", "p", "rp", "rt"]
    private static let TagSearchSpecial = ["address", "applet", "area", "article", "aside", "base", "basefont", "bgsound",
                                           "blockquote", "body", "br", "button", "caption", "center", "col", "colgroup", "command", "dd",
                                           "details", "dir", "div", "dl", "dt", "embed", "fieldset", "figcaption", "figure", "footer", "form",
                                           "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html",
                                           "iframe", "img", "input", "isindex", "li", "link", "listing", "marquee", "menu", "meta", "nav",
                                           "noembed", "noframes", "noscript", "object", "ol", "p", "param", "plaintext", "pre", "script",
                                           "section", "select", "style", "summary", "table", "tbody", "td", "textarea", "tfoot", "th", "thead",
                                           "title", "tr", "ul", "wbr", "xmp"]
    
    private(set) var state: HTMLTreeBuilderState = .Initial // current state
    var originalState: HTMLTreeBuilderState? = nil // original / marked state
    
    var baseUriSetFromDoc = false
    var headElement: Element? // the current head element
    var formElement: FormElement? // the current form element
    var contextElement: Element? // fragment parse context -- could be null even if fragment parsing
    var formattingElements = [Element?]() // active (open) formatting elements
    var pendingTableCharacters = [String]() // chars in table to be shifted out
    let emptyEnd = Token.EndTag() // reused empty end tag
    
    var framesetOk = true; // if ok to go into frameset
    var fosterInserts = false; // if next inserts should be fostered
    var fragmentParsing = false; // if parsing a fragment of html
    
    override init() {}
    
    public override var defaultSettings: ParseSettings {
        return ParseSettings.htmlDefault
    }
    
    override func parse(input: String, baseUri: String?, errors: ParseErrorList, settings: ParseSettings) -> Document {
        state = .Initial
        baseUriSetFromDoc = false
        return super.parse(input: input, baseUri: baseUri, errors: errors, settings: settings)
    }
    
    func parse(fragment: String, context: Element?, baseUri: String?, errors: ParseErrorList, settings: ParseSettings) -> [Node] {
        state = .Initial
        initializeParse(input: fragment, baseUri: baseUri, errors: errors, settings: settings)
        self.contextElement = context
        self.fragmentParsing = true
        
        var root: Element? = nil
        
        if context != nil {
            if context!.ownerDocument != nil {
                document.quirksMode = context!.ownerDocument!.quirksMode
            }
            
            // initialise the tokeniser state:
            let contextTag = context!.tagName
            if ["title", "textarea"].contains(contextTag) {
                tokeniser.transition(newState: .Rcdata)
            } else if ["iframe", "noembed", "noframes", "style", "xmp"].contains(contextTag) {
                tokeniser.transition(newState: .Rawtext)
            } else if contextTag == "script" {
                tokeniser.transition(newState: .ScriptData)
            } else if contextTag == "noscript" || contextTag == "plaintext" {
                tokeniser.transition(newState: .Data)
            } else {
                tokeniser.transition(newState: .Data)
            }
            
            root = Element(tag: Tag.valueOf(tagName: "html", settings: settings), baseUri: baseUri)
            document.append(childNode: root!)
            stack.append(root!)
            resetInsertionMode()
            
            /*  setup form element to nearest form on context (up ancestor chain). ensures form controls are associated
                with form correctly */
            
            var contextChains = context!.parents
            contextChains.insert(context!, at: 0)
            
            for parent in contextChains {
                if let formElement = parent as? FormElement {
                    self.formElement = formElement
                    break
                }
            }
        }
        
        runParser()
        
        if context != nil && root != nil {
            return root!.childNodes
        } else  {
            return document.childNodes
        }
    }

    @discardableResult
    override func process(token: Token) -> Bool {
        self.currentToken = token
        return state.process(token: token, treeBuilder: self)
    }

    @discardableResult
    func process(token: Token, state: HTMLTreeBuilderState) -> Bool {
        self.currentToken = token
        return state.process(token: token, treeBuilder: self)
    }
    
    func transition(to newState: HTMLTreeBuilderState) {
        self.state = newState
    }
    
    func markInsertionMode() {
        self.originalState = state
    }
    
    func maybeSetUri(_ base: Element) {
        if baseUriSetFromDoc { // only listen to the first <base href> in parse
            return
        }
        
        if let href = base.absUrl(forAttributeKey: "href"), !href.isEmpty {
            baseUri = href
            baseUriSetFromDoc = true
            document.baseUri = href
        }
    }
    
    func error(_ state: HTMLTreeBuilderState) {
        if errors.canAddError {
            errors.append(ParseError(pos: characterReader.pos, message: "Unexpected token [\(currentToken!.type)] when in state [\(state)]"))
        }
    }

    @discardableResult
    func insert(startTag: Token.StartTag) -> Element {
        // handle empty unknown tags
        // when the spec expects an empty tag, will directly hit insertEmpty, so won't generate this fake end tag.
        if startTag.selfClosing {
            let element = insert(empty: startTag)
            stack.append(element)
            tokeniser.transition(newState: .Data)
            
            let emptyEnd = self.emptyEnd.reset() as! Token.EndTag
            emptyEnd.tagName = element.tagName
            tokeniser.emit(emptyEnd)
            return element
        }
        
        let element = Element(tag: Tag.valueOf(tagName: startTag.tagName ?? "", settings: settings),
                              baseUri: baseUri, attributes: settings.normalize(attributes: startTag.attributes))
        insert(element)
        return element
    }

    @discardableResult
    func insert(startTag: String) -> Element {
        let element = Element(tag: Tag.valueOf(tagName: startTag, settings: settings), baseUri: baseUri)
        insert(element)
        return element
    }

    @discardableResult
    func insert(_ element: Element) -> Element {
        insert(node: element)
        stack.append(element)
        return element
    }

    @discardableResult
    func insert(empty startTag: Token.StartTag) -> Element {
        let tag = Tag.valueOf(tagName: startTag.tagName ?? "", settings: settings)
        let element = Element(tag: tag, baseUri: baseUri, attributes: startTag.attributes)
        insert(node: element)
        
        if startTag.selfClosing {
            if tag.isKnownTag {
                if tag.isSelfClosing { tokeniser.selfClosingFlagAcknowledged = true } // if not acked, promulagates error
            } else {
                // unknown tag, remember this is self closing for output
                tag.selfClosing = true
                tokeniser.selfClosingFlagAcknowledged = true // not an distinct error
            }
        }
        
        return element
    }

    @discardableResult
    func insert(form startTag: Token.StartTag, onStack: Bool) -> Element {
        let tag = Tag.valueOf(tagName: startTag.tagName ?? "", settings: settings)
        let formElement = FormElement(tag: tag, baseUri: baseUri, attributes: startTag.attributes)
        self.formElement = formElement
        
        insert(node: formElement)
        
        if onStack {
            stack.append(formElement)
        }
        
        return formElement
    }

    func insert(comment commentToken: Token.Comment) {
        let comment = Comment(data: commentToken.data, baseUri: baseUri)
        insert(node: comment)
    }

    func insert(character characterToken: Token.Character) {
        // characters in script and style go in as datanodes, not text nodes
        let node: Node
        let tagName = currentElement?.tagName
        
        if tagName == "script" || tagName == "style" {
            node = DataNode(data: characterToken.data ?? "", baseUri: baseUri)
        } else {
            node = TextNode(text: characterToken.data ?? "", baseUri: baseUri)
        }
        
        // doesn't use insertNode, because we don't foster these; and will always have a stack.
        currentElement?.append(childNode: node)
    }

    private func insert(node: Node) {
        // if the stack hasn't been set up yet, elements (doctype, comments) go into the doc
        if stack.isEmpty {
            document.append(childNode: node)
        } else if fosterInserts {
            insertInFosterParent(node)
        } else {
            currentElement?.append(childNode: node)
        }
        
        // connect form controls to their form element
        if let element = node as? Element, element.tag.isFormListed {
            formElement?.append(element)
        }
    }

    @discardableResult
    func pop() -> Element? {
        return stack.popLast()
    }
    
    func push(_ element: Element) {
        stack.append(element)
    }
    
    func onStack(_ element: Element) -> Bool {
        return isInQueue(queue: stack, element: element)
    }
    
    private func isInQueue(queue: [Element], element: Element) -> Bool {
        return queue.contains(element)
    }
    
    func getFromStack(_ name: String) -> Element? {
        return stack.reversed().first { $0.tagName == name }
    }

    @discardableResult
    func removeFromStack(_ element: Element) -> Element? {
        guard let found = stack.reversed().first(where: { $0 == element }),
            let index = stack.firstIndex(of: found)
            else { return nil }
        
        stack.remove(at: index)
        return found
    }
    
    func popStackToClose(_ name: String) {
        while let nextNode = stack.last {
            stack.removeLast()
            if nextNode.nodeName == name {
                break
            }
        }
    }
    
    func popStackToClose(_ names: String...) {
        self.popStackToClose(names)
    }
    
    func popStackToClose(_ names: [String]) {
        while let nextNode = stack.last {
            stack.removeLast()
            if names.contains(nextNode.nodeName) {
                break
            }
        }
    }
    
    func popStackToBefore(_ name: String) {
        while let nextNode = stack.last {
            if nextNode.nodeName == name {
                break
            } else {
                stack.removeLast()
            }
        }
    }
    
    func clearStackToTableContext() {
        clearStack(toContext: "table")
    }
    
    func clearStackToTableBodyContext() {
        clearStack(toContext: "tbody", "tfoot", "thead")
    }
    
    func clearStackToTableRowContext() {
        clearStack(toContext: "tr")
    }
    
    func clearStack(toContext nodeNames: String...) {
        let names = nodeNames + ["html"]
        while let last = stack.last {
            if names.contains(last.tagName) {
                break
            } else {
                stack.removeLast()
            }
        }
    }
    
    func aboveOnStack(_ element: Element) -> Element? {
        for i in (0..<stack.count).reversed() {
            if element == stack[i] {
                return stack[i-1]
            }
        }
        return nil
    }
    
    func insertOnStack(after: Element, new: Element) {
        if let i = stack.lastIndex(of: after) {
            stack.insert(new, at: i+1)
        }
    }
    
    func replaceOnStack(out: Element, new: Element) {
        if let i = stack.lastIndex(of: out) {
            stack[i] = new
        }
    }

    func replaceIn(queue: [Element], out: Element, new: Element) -> [Element] {
        var queue = queue

        if let i = queue.lastIndex(of: out) {
            queue[i] = new
        }

        return queue
    }
    
    func resetInsertionMode() {
        var last = false
        for i in (0..<stack.count).reversed() {
            var node: Element? = stack[i]
            
            if i == 0 {
                last = true
                node = contextElement
            }
            
            let name = node?.nodeName ?? ""
            
            if name == "select" {
                transition(to: .InSelect)
                break
            } else if "td" == name || ("th" == name && !last) {
                transition(to: .InCell)
                break
            } else if "tr" == name {
                transition(to: .InRow)
                break
            } else if ["tbody", "thead", "tfoot"].contains(name) {
                transition(to: .InTableBody)
                break
            } else if "caption" == name {
                transition(to: .InCaption)
                break
            } else if "colgroup" == name {
                transition(to: .InColumnGroup)
                break
            } else if "table" == name {
                transition(to: .InTable)
                break
            } else if "head" == name || "body" == name {
                transition(to: .InBody)
                break
            } else if "frameset" == name {
                transition(to: .InFrameset)
                break
            } else if "html" == name {
                transition(to: .BeforeHead)
                break
            } else if last {
                transition(to: .InBody)
                break
            }
        }
    }
    
    private func inSpecificScope(_ targetName: String, baseTypes: [String], extraTypes: [String]) -> Bool {
        let specificScopeTarget = [targetName]
        return inSpecificScope(specificScopeTarget, baseTypes: baseTypes, extraTypes: extraTypes)
    }
    
    private func inSpecificScope(_ targetNames: [String], baseTypes: [String], extraTypes: [String]) -> Bool {
        for i in (0..<stack.count).reversed() {
            let element = stack[i]
            let elementName = element.nodeName
            
            if targetNames.contains(elementName) {
                return true
            } else if baseTypes.contains(elementName) {
                return false
            } else if extraTypes.contains(elementName) {
                return false
            }
        }
        return false
    }
    
    func inScope(_ targetNames: [String]) -> Bool {
        return inSpecificScope(targetNames, baseTypes: HTMLTreeBuilder.TagsSearchInScope, extraTypes: [])
    }
    
    func inScope(_ targetName: String) -> Bool {
        return inScope([targetName])
    }
    
    func inScope(_ targetName: String, extras: [String]) -> Bool {
        // todo: in mathml namespace: mi, mo, mn, ms, mtext annotation-xml
        // todo: in svg namespace: forignOjbect, desc, title
        return inSpecificScope(targetName, baseTypes: HTMLTreeBuilder.TagsSearchInScope, extraTypes: extras)
    }
    
    func inListItemScope(_ targetName: String) -> Bool {
        return inScope(targetName, extras: HTMLTreeBuilder.TagSearchList)
    }
    
    func inButtonScope(_ targetName: String) -> Bool {
        return inScope(targetName, extras: HTMLTreeBuilder.TagSearchButton)
    }
    
    func inTableScope(_ targetName: String) -> Bool {
        return inSpecificScope(targetName, baseTypes: HTMLTreeBuilder.TagSearchTableScope, extraTypes: [])
    }
    
    func inSelectScope(_ targetName: String) -> Bool {
        for i in (0..<stack.count).reversed() {
            let element = stack[i]
            let elementName = element.nodeName
            
            if elementName == targetName {
                return true
            } else if !HTMLTreeBuilder.TagSearchSelectScope.contains(elementName) {
                return false
            }
        }
        return false
    }
    
    /**
     11.2.5.2 Closing elements that have implied end tags<p/>
     When the steps below require the UA to generate implied end tags, then, while the current node is a dd element, a
     dt element, an li element, an option element, an optgroup element, a p element, an rp element, or an rt element,
     the UA must pop the current node off the stack of open elements.
     @param excludeTag If a step requires the UA to generate implied end tags but lists an element to exclude from the
     process, then the UA must perform the above steps as if that element was not in the above list.
     */
    func generateImpliedEndTags(excludeTag: String?) {
        while (excludeTag != nil && currentElement != nil && currentElement?.nodeName != excludeTag) &&
            HTMLTreeBuilder.TagSearchEndTags.contains(currentElement!.nodeName) {
                pop()
        }
    }
    
    func generateImpliedEndTags() {
        return generateImpliedEndTags(excludeTag: nil)
    }
    
    func isSpecial(_ element: Element) -> Bool {
        // todo: mathml's mi, mo, mn
        // todo: svg's foreigObject, desc, title
        let name = element.nodeName
        return HTMLTreeBuilder.TagSearchSpecial.contains(name)
    }
    
    var lastFormattingElement: Element? {
        return formattingElements.last ?? nil
    }
    
    func removeLastFormattingElement() -> Element? {
        return formattingElements.popLast() ?? nil
    }
    
    // active formatting elements
    func pushActiveFormattingElements(_ new: Element) {
        var numSeen = 0
        for i in (0..<formattingElements.count).reversed() {
            let element = formattingElements[i] ?? nil
            
            if isSameFormattingElement(new, element) {
                numSeen += 1
            }
            
            if numSeen == 3 {
                formattingElements.remove(at: i)
                break
            }
        }
        
        formattingElements.append(new)
    }
    
    func isSameFormattingElement(_ a: Element?, _ b: Element?) -> Bool {
        // same if: same namespace, tag, and attributes. Element.equals only checks tag, might in future check children
        return a?.nodeName == b?.nodeName && a?.attributes == b?.attributes
        // todo namespaces
    }
    
    func reconstructFormattingElements() {
        let last = lastFormattingElement
        if last == nil || (last != nil && onStack(last!)) {
            return
        }
        
        var entry = last
        let count = formattingElements.count
        var pos = count - 1
        var skip = false
        
        while true {
            if pos == 0 { // step 4. if none before, skip to 8
                skip = true
                break
            }
            
            pos -= 1
            entry = formattingElements[pos] // step 5. one earlier than entry
            if entry == nil || (entry != nil && onStack(entry!)) { // step 6 - neither marker nor on stack
                break // jump to 8, else continue back to 4
            }
        }
        
        while true {
            if !skip { // step 7: on later than entry
                pos += 1
                entry = formattingElements[pos]
            }
            
            // 8. create new element from element, 9 insert into current node, onto stack
            skip = false // can only skip increment from 4.
            let newElement = insert(startTag: entry!.nodeName) // todo: avoid fostering here?
            // newEl.namespace(entry.namespace()); // todo: namespaces
            newElement.attributes.append(dictionary: entry!.attributes)
            
            // 10. replace entry with new entry
            formattingElements[pos] = newElement
            
            // 11
            if pos == count - 1 { // if not last entry in list, jump to 7
                break
            }
        }
    }
    
    func clearFormattingElementsToLastMarker() {
        while !formattingElements.isEmpty {
            let element = removeLastFormattingElement()
            if element == nil {
                break
            }
        }
    }
    
    func removeFromActiveFormattingElements(_ element: Element) {
        for pos in (0..<formattingElements.count).reversed() {
            let next = formattingElements[pos]
            if next == element {
                formattingElements.remove(at: pos)
                break
            }
        }
    }
    
    func isInActiveFormattingElements(_ element: Element) -> Bool {
        return isInQueue(queue: formattingElements.compactMap { $0 }, element: element)
    }
    
    func getActiveFormattingElement(_ nodeName: String) -> Element? {
        for i in (0..<formattingElements.count).reversed() {
            let next = formattingElements[i]
            
            if next?.nodeName == nodeName {
                return next
            }
        }
        return nil
    }
    
    func replaceActiveFormattingElement(out: Element, new: Element) {
        self.formattingElements = replaceIn(queue: formattingElements as! [Element], out: out, new: new)
    }
    
    func insertMarkerToFormattingElements() {
        formattingElements.append(nil)
    }
    
    func insertInFosterParent(_ new: Node) {
        var fosterParent: Element? = nil
        let lastTable = getFromStack("table")
        var isLastTableParent = false
        if lastTable != nil {
            if lastTable?.parentNode != nil {
                fosterParent = lastTable?.parentElement
                isLastTableParent = true
            } else {
                fosterParent = aboveOnStack(lastTable!)
            }
        } else { // no table == frag
            fosterParent = stack[0]
        }
        
        if isLastTableParent && lastTable != nil {
            lastTable?.insertBefore(node: new)
        } else {
            fosterParent?.append(childNode: new)
        }
    }
    
    var description: String {
        return "TreeBuilder{ currentToken=\(String(describing: currentToken)), state=\(state), currentElement=\(String(describing: currentElement))}"
    }
}
