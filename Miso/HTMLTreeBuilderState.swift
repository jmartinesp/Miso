//
//  HTMLTreeBuilderState.swift
//  SwiftSoup
//
//  Created by Nabil ChatreeBuilderi on 24/10/16.
//  Copyright © 2016 Nabil ChatreeBuilderi.. All rights reserved.
//

import Foundation

enum HTMLTreeBuilderState: String, CustomStringConvertible {
    case Initial
    case BeforeHtml
    case BeforeHead
    case InHead
    case InHeadNoscript
    case AfterHead
    case InBody
    case Text
    case InTable
    case InTableText
    case InCaption
    case InColumnGroup
    case InTableBody
    case InRow
    case InCell
    case InSelect
    case InSelectInTable
    case AfterBody
    case InFrameset
    case AfterFrameset
    case AfterAfterBody
    case AfterAfterFrameset
    case ForeignContent
    
    private static let nullString: String = "\u{0000}"
    
    func process(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
        switch self {
        case .Initial:
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                return true // ignore whitespace
            } else if let commentToken = token as? Token.Comment {
                treeBuilder.insert(comment: commentToken)
            } else if let docTypeToken = token as? Token.DocType {
                // todo: parse error check on expected doctypes
                // todo: quirk state check on doctype ids
                let doctype: DocumentType = DocumentType(
                    name: treeBuilder.settings.normalize(tagName: docTypeToken.name),
                    pubSysKey: docTypeToken.pubSysKey,
                    publicId: docTypeToken.publicIdentifier,
                    systemId: docTypeToken.systemIdentifier,
                    baseUri: treeBuilder.baseUri)
                //treeBuilder.settings.normalizeTag(d.getName()), d.getPublicIdentifier(), d.getSystemIdentifier(), treeBuilder.getBaseUri())
                treeBuilder.document.append(childNode: doctype)
                if (docTypeToken.forceQuirks) {
                    treeBuilder.document.quirksMode = .quirks
                }
                treeBuilder.transition(to: .BeforeHtml)
            } else {
                // todo: check not iframe srcdoc
                treeBuilder.transition(to: .BeforeHtml)
                return treeBuilder.process(token: token) // re-process token
            }
            return true
        case .BeforeHtml:
            
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                treeBuilder.insert(startTag: "html")
                treeBuilder.transition(to: .BeforeHead)
                return treeBuilder.process(token: token)
            }
            
            if (token.isDocType) {
                treeBuilder.error(self)
                return false
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (HTMLTreeBuilderState.isWhitespace(token)) {
                return true // ignore whitespace
            } else if let startTag = token as? Token.StartTag, startTag.normalizedName == "html" {
                treeBuilder.insert(startTag: startTag)
                treeBuilder.transition(to: .BeforeHead)
            } else if (token.isEndTag && (["head", "body", "html", "br"].contains((token as! Token.EndTag).normalizedName!))) {
                return anythingElse(token: token, treeBuilder: treeBuilder)
            } else if (token.isEndTag) {
                treeBuilder.error(self)
                return false
            } else {
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .BeforeHead:
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                return true
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (token.isDocType) {
                treeBuilder.error(self)
                return false
            } else if (token.isStartTag && (token as! Token.StartTag).normalizedName == "html") {
                return HTMLTreeBuilderState.InBody.process(token: token, treeBuilder: treeBuilder) // does not transition
            } else if (token.isStartTag && (token as! Token.StartTag).normalizedName == "head") {
                let head: Element = treeBuilder.insert(startTag: token as! Token.StartTag)
                treeBuilder.headElement = head
                treeBuilder.transition(to: .InHead)
            } else if (token.isEndTag && ["head", "body", "html", "br"].contains((token as! Token.EndTag).normalizedName!)) {
                treeBuilder.process(startTag: "head")
                return treeBuilder.process(token: token)
            } else if (token.isEndTag) {
                treeBuilder.error(self)
                return false
            } else {
                treeBuilder.process(startTag: "head")
                return treeBuilder.process(token: token)
            }
            return true
        case .InHead:
            func anythingElse(token: Token, treeBuilder: TreeBuilder)->Bool {
                treeBuilder.process(endTag: "head")
                return treeBuilder.process(token: token)
            }
            
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                treeBuilder.insert(character: token as! Token.Character)
                return true
            }
            switch (token.type) {
            case .Comment:
                treeBuilder.insert(comment: token as! Token.Comment)
                break
            case .Doctype:
                treeBuilder.error(self)
                return false
            case .StartTag:
                let start: Token.StartTag = (token as! Token.StartTag)
                var name: String = start.normalizedName!
                if (name == "html") {
                    return HTMLTreeBuilderState.InBody.process(token: token, treeBuilder: treeBuilder)
                } else if (["base", "basefont", "bgsound", "command", "link"].contains(name)) {
                    let el: Element = treeBuilder.insert(empty: start)
                    // jsoup special: update base the frist time it is seen
                    if (name == "base" && el.has(attr: "href")) {
                        treeBuilder.maybeSetUri(el)
                    }
                } else if (name == "meta") {
                    let meta: Element = treeBuilder.insert(empty: start)
                    // todo: charset switches
                } else if (name == "title") {
                    HTMLTreeBuilderState.handleRcData(startTag: start, treeBuilder: treeBuilder)
                } else if (["noframes", "style"].contains(name)) {
                    HTMLTreeBuilderState.handleRawText(startTag: start, treeBuilder: treeBuilder)
                } else if (name == "noscript") {
                    // else if noscript && scripting flag = true: rawtext (jsoup doesn'token run script, to handle as noscript)
                    treeBuilder.insert(startTag: start)
                    treeBuilder.transition(to: .InHeadNoscript)
                } else if (name == "script") {
                    // skips some script rules as won'token execute them
                    
                    treeBuilder.tokeniser.transition(newState: TokeniserState.ScriptData)
                    treeBuilder.markInsertionMode()
                    treeBuilder.transition(to: .Text)
                    treeBuilder.insert(startTag: start)
                } else if (name == "head") {
                    treeBuilder.error(self)
                    return false
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            case .EndTag:
                let end: Token.EndTag = (token as! Token.EndTag)
                let name = end.normalizedName
                if name == "head" {
                    treeBuilder.pop()
                    treeBuilder.transition(to: .AfterHead)
                } else if (name != nil && ["body", "html", "br"].contains(name!)) {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                } else {
                    treeBuilder.error(self)
                    return false
                }
                break
            default:
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .InHeadNoscript:
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                treeBuilder.error(self)
                treeBuilder.insert(character: build(Token.Character()) { $0.data = token.description })
                return true
            }
            if (token.isDocType) {
                treeBuilder.error(self)
            } else if (token.isStartTag && (token as! Token.StartTag).normalizedName == "html") {
                return treeBuilder.process(token: token, state: .InBody)
            } else if (token.isEndTag && (token as! Token.EndTag).normalizedName == "noscript") {
                treeBuilder.pop()
                treeBuilder.transition(to: .InHead)
            } else if (HTMLTreeBuilderState.isWhitespace(token) || token.isComment || (token.isStartTag && ["basefont", "bgsound", "link", "meta", "noframes", "style"].contains((token as! Token.StartTag).normalizedName!))) {
                return treeBuilder.process(token: token, state: .InHead)
            } else if (token.isEndTag && (token as! Token.EndTag).normalizedName == "br") {
                return anythingElse(token: token, treeBuilder: treeBuilder)
            } else if ((token.isStartTag && ["head", "noscript"].contains((token as! Token.StartTag).normalizedName!)) || token.isEndTag) {
                treeBuilder.error(self)
                return false
            } else {
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .AfterHead:
            @discardableResult
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                treeBuilder.process(startTag: "body")
                treeBuilder.framesetOk = true
                return treeBuilder.process(token: token)
            }
            
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                treeBuilder.insert(character: token as! Token.Character)
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (token.isDocType) {
                treeBuilder.error(self)
            } else if (token.isStartTag) {
                let startTag: Token.StartTag = (token as! Token.StartTag)
                let name: String = startTag.normalizedName!
                if (name == "html") {
                    return treeBuilder.process(token: token, state: .InBody)
                } else if (name == "body") {
                    treeBuilder.insert(startTag: startTag)
                    treeBuilder.framesetOk = false
                    treeBuilder.transition(to: .InBody)
                } else if (name == "frameset") {
                    treeBuilder.insert(startTag: startTag)
                    treeBuilder.transition(to: .InFrameset)
                } else if (["base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "title"].contains(name)) {
                    treeBuilder.error(self)
                    if let head: Element = treeBuilder.headElement {
                        treeBuilder.push(head)
                        treeBuilder.process(token: token, state: .InHead)
                        treeBuilder.removeFromStack(head)
                    }
                } else if (name == "head") {
                    treeBuilder.error(self)
                    return false
                } else {
                    anythingElse(token: token, treeBuilder: treeBuilder)
                }
            } else if (token.isEndTag) {
                if (["body", "html"].contains((token as! Token.EndTag).normalizedName!)) {
                    anythingElse(token: token, treeBuilder: treeBuilder)
                } else {
                    treeBuilder.error(self)
                    return false
                }
            } else {
                anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .InBody:
            func anyOtherEndTag(_ token: Token, _ treeBuilder: HTMLTreeBuilder) -> Bool {
                let name: String? = (token as! Token.EndTag).normalizedName
                let stack: Array<Element> = treeBuilder.stack
                for pos in (0..<stack.count).reversed() {
                    let node: Element = stack[pos]
                    if (name != nil && node.nodeName == name!) {
                        treeBuilder.generateImpliedEndTags(excludeTag: name)
                        if (name != treeBuilder.currentElement?.nodeName) {
                            treeBuilder.error(self)
                        }
                        treeBuilder.popStackToClose(name!)
                        break
                    } else {
                        if (treeBuilder.isSpecial(node)) {
                            treeBuilder.error(self)
                            return false
                        }
                    }
                }
                return true
            }
            
            switch (token.type) {
            case .Character:
                let c: Token.Character = token as! Token.Character
                if (c.data == HTMLTreeBuilderState.nullString) {
                    // todo confirm that check
                    treeBuilder.error(self)
                    return false
                } else if (treeBuilder.framesetOk && HTMLTreeBuilderState.isWhitespace(c)) { // don'token check if whitespace if frames already closed
                    treeBuilder.reconstructFormattingElements()
                    treeBuilder.insert(character: c)
                } else {
                    treeBuilder.reconstructFormattingElements()
                    treeBuilder.insert(character: c)
                    treeBuilder.framesetOk = false
                }
                break
            case .Comment:
                treeBuilder.insert(comment: token as! Token.Comment)
                break
            case .Doctype:
                treeBuilder.error(self)
                return false
            case .StartTag:
                let startTag: Token.StartTag = token as! Token.StartTag
                if let name: String = startTag.normalizedName {
                    if (name == "a") {
                        if (treeBuilder.getActiveFormattingElement("a") != nil) {
                            treeBuilder.error(self)
                            treeBuilder.process(endTag: "a")
                            
                            // still on stack?
                            let remainingA: Element? = treeBuilder.getFromStack("a")
                            if (remainingA != nil) {
                                treeBuilder.removeFromActiveFormattingElements(remainingA!)
                                treeBuilder.removeFromStack(remainingA!)
                            }
                        }
                        treeBuilder.reconstructFormattingElements()
                        let a = treeBuilder.insert(startTag: startTag)
                        treeBuilder.pushActiveFormattingElements(a)
                    } else if (Constants.InBodyStartEmptyFormatters.contains(name)) {
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.insert(empty: startTag)
                        treeBuilder.framesetOk = false
                    } else if Constants.InBodyStartPClosers.contains(name) {
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(startTag: startTag)
                    } else if (name == "span") {
                        // same as final else, but short circuits lots of checks
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.insert(startTag: startTag)
                    } else if (name == "li") {
                        treeBuilder.framesetOk = false
                        let stack: Array<Element> = treeBuilder.stack
                        for i in (0..<stack.count).reversed() {
                            let el: Element = stack[i]
                            if (el.nodeName == "li") {
                                treeBuilder.process(endTag: "li")
                                break
                            }
                            if (treeBuilder.isSpecial(el) && !Constants.InBodyStartLiBreakers.contains(el.nodeName)) {
                                break
                            }
                        }
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(startTag: startTag)
                    } else if (name == "html") {
                        treeBuilder.error(self)
                        // merge attributes onto real html
                        let html: Element = treeBuilder.stack[0]
                        for attribute in startTag.attributes {
                            if (!html.has(attr: attribute.key)) {
                                html.attributes[attribute.key] = attribute.value
                            }
                        }
                    } else if Constants.InBodyStartToHead.contains(name) {
                        return treeBuilder.process(token: token, state: .InHead)
                    } else if (name == "body") {
                        treeBuilder.error(self)
                        let stack: Array<Element> = treeBuilder.stack
                        if (stack.count == 1 || (stack.count > 2 && stack[1].nodeName != "body")) {
                            // only in fragment case
                            return false // ignore
                        } else {
                            treeBuilder.framesetOk = false
                            let body: Element = stack[1]
                            for attribute: Attribute in startTag.attributes.values {
                                if (!body.has(attr: attribute.tag)) {
                                    body.attr(attribute.tag, setValue: attribute.value)
                                }
                            }
                        }
                    } else if (name == "frameset") {
                        treeBuilder.error(self)
                        var stack: Array<Element> = treeBuilder.stack
                        if (stack.count == 1 || (stack.count > 2 && stack[1].nodeName != "body")) {
                            // only in fragment case
                            return false // ignore
                        } else if (!treeBuilder.framesetOk) {
                            return false // ignore frameset
                        } else {
                            let second: Element = stack[1]
                            if (second.parentElement != nil) {
                                second.removeFromParent()
                            }
                            // pop up to html element
                            while (stack.count > 1) {
                                stack.remove(at: stack.count-1)
                            }
                            treeBuilder.insert(startTag: startTag)
                            treeBuilder.transition(to: .InFrameset)
                        }
                    } else if Constants.Headings.contains(name) {
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        if (treeBuilder.currentElement != nil && Constants.Headings.contains(treeBuilder.currentElement!.nodeName)) {
                            treeBuilder.error(self)
                            treeBuilder.pop()
                        }
                        treeBuilder.insert(startTag: startTag)
                    } else if Constants.InBodyStartPreListing.contains(name) {
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(startTag: startTag)
                        // todo: ignore LF if next token
                        treeBuilder.framesetOk = false
                    } else if (name == "form") {
                        if (treeBuilder.formElement != nil) {
                            treeBuilder.error(self)
                            return false
                        }
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(form: startTag, onStack: true)
                    } else if Constants.DdDt.contains(name) {
                        treeBuilder.framesetOk = false
                        let stack: Array<Element> = treeBuilder.stack
                        for i in (1..<stack.count).reversed() {
                            let el: Element = stack[i]
                            if Constants.DdDt.contains(el.nodeName) {
                                treeBuilder.process(endTag: el.nodeName)
                                break
                            }
                            if (treeBuilder.isSpecial(el) && !Constants.InBodyStartLiBreakers.contains(el.nodeName)) {
                                break
                            }
                        }
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(startTag: startTag)
                    } else if (name == "plaintext") {
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.tokeniser.transition(newState: TokeniserState.PLAINTEXT) // once in, never gets out
                    } else if (name == "button") {
                        if (treeBuilder.inButtonScope("button")) {
                            // close and reprocess
                            treeBuilder.error(self)
                            treeBuilder.process(endTag: "button")
                            treeBuilder.process(token: startTag)
                        } else {
                            treeBuilder.reconstructFormattingElements()
                            treeBuilder.insert(startTag: startTag)
                            treeBuilder.framesetOk = false
                        }
                    } else if Constants.Formatters.contains(name) {
                        treeBuilder.reconstructFormattingElements()
                        let el: Element = treeBuilder.insert(startTag: startTag)
                        treeBuilder.pushActiveFormattingElements(el)
                    } else if (name == "nobr") {
                        treeBuilder.reconstructFormattingElements()
                        if (treeBuilder.inScope("nobr")) {
                            treeBuilder.error(self)
                            treeBuilder.process(endTag: "nobr")
                            treeBuilder.reconstructFormattingElements()
                        }
                        let el: Element = treeBuilder.insert(startTag: startTag)
                        treeBuilder.pushActiveFormattingElements(el)
                    } else if Constants.InBodyStartApplets.contains(name) {
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.insertMarkerToFormattingElements()
                        treeBuilder.framesetOk = false
                    } else if (name == "table") {
                        if (treeBuilder.document.quirksMode != .quirks && treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.framesetOk = false
                        treeBuilder.transition(to: .InTable)
                    } else if (name == "input") {
                        treeBuilder.reconstructFormattingElements()
                        let el: Element = treeBuilder.insert(empty: startTag)
                        if (el.attr("type")?.lowercased() != "hidden") {
                            treeBuilder.framesetOk = false
                        }
                    } else if Constants.InBodyStartMedia.contains(name) {
                        treeBuilder.insert(empty: startTag)
                    } else if (name == "hr") {
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.insert(empty: startTag)
                        treeBuilder.framesetOk = false
                    } else if (name == "image") {
                        if (treeBuilder.getFromStack("svg") == nil) {
                            startTag.tagName = "img"
                            return treeBuilder.process(token: startTag) // change <image> to <img>, unless in svg
                        } else {
                            treeBuilder.insert(startTag: startTag)
                        }
                    } else if (name == "isindex") {
                        // how much do we care about the early 90s?
                        treeBuilder.error(self)
                        if (treeBuilder.formElement != nil) {
                            return false
                        }
                        
                        treeBuilder.tokeniser.selfClosingFlagAcknowledged = true
                        treeBuilder.process(startTag: "form")
                        if (startTag.attributes.keys.contains("action")) {
                            if let form: Element = treeBuilder.formElement {
                                form.attr("action", setValue: startTag.attributes["action"]!.value)
                            }
                        }
                        treeBuilder.process(startTag: "hr")
                        treeBuilder.process(startTag: "label")
                        // hope you like english.
                        let prompt: String = startTag.attributes["prompt"]?.value ?? "This is a searchable index. Enter search keywords: "
                        
                        treeBuilder.process(token: build(Token.Character()) { $0.data = prompt })
                        
                        // input
                        let inputAttribs: Attributes = Attributes()
                        for attr in startTag.attributes {
                            if (!Constants.InBodyStartInputAttribs.contains(attr.key)) {
                                inputAttribs[attr.key] = attr.value
                            }
                        }
                        inputAttribs.put(string: "isindex", forKey: "name")
                        treeBuilder .process(startTag: "input", attributes: inputAttribs)
                        treeBuilder.process(endTag: "label")
                        treeBuilder.process(startTag: "hr")
                        treeBuilder.process(endTag: "form")
                    } else if (name == "textarea") {
                        treeBuilder.insert(startTag: startTag)
                        // todo: If the next token is a U+000A LINE FEED (LF) character token, then ignore that token and move on to the next one. (Newlines at the start of textarea elements are ignored as an authoring convenience.)
                        treeBuilder.tokeniser.transition(newState: TokeniserState.Rcdata)
                        treeBuilder.markInsertionMode()
                        treeBuilder.framesetOk = false
                        treeBuilder.transition(to: .Text)
                    } else if (name == "xmp") {
                        if (treeBuilder.inButtonScope("p")) {
                            treeBuilder.process(endTag: "p")
                        }
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.framesetOk = false
                        HTMLTreeBuilderState.handleRawText(startTag: startTag, treeBuilder: treeBuilder)
                    } else if (name == "iframe") {
                        treeBuilder.framesetOk = false
                        HTMLTreeBuilderState.handleRawText(startTag: startTag, treeBuilder: treeBuilder)
                    } else if (name == "noembed") {
                        // also handle noscript if script enabled
                        HTMLTreeBuilderState.handleRawText(startTag: startTag, treeBuilder: treeBuilder)
                    } else if (name == "select") {
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.framesetOk = false
                        
                        let state: HTMLTreeBuilderState = treeBuilder.state
                        if (state == .InTable || state == .InCaption || state == .InTableBody || state == .InRow || state == .InCell) {
                            treeBuilder.transition(to: .InSelectInTable)
                        } else {
                            treeBuilder.transition(to: .InSelect)
                        }
                    } else if Constants.InBodyStartOptions.contains(name) {
                        if (treeBuilder.currentElement != nil && treeBuilder.currentElement!.nodeName == "option") {
                            treeBuilder.process(endTag: "option")
                        }
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.insert(startTag: startTag)
                    } else if Constants.InBodyStartRuby.contains(name) {
                        if (treeBuilder.inScope("ruby")) {
                            treeBuilder.generateImpliedEndTags()
                            if (treeBuilder.currentElement != nil && treeBuilder.currentElement!.nodeName != "ruby") {
                                treeBuilder.error(self)
                                treeBuilder.popStackToBefore("ruby") // i.e. close up to but not include name
                            }
                            treeBuilder.insert(startTag: startTag)
                        }
                    } else if (name == "math") {
                        treeBuilder.reconstructFormattingElements()
                        // todo: handle A start tag whose tag name is "math" (i.e. foreign, mathml)
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.tokeniser.selfClosingFlagAcknowledged = true
                    } else if (name == "svg") {
                        treeBuilder.reconstructFormattingElements()
                        // todo: handle A start tag whose tag name is "svg" (xlink, svg)
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.tokeniser.selfClosingFlagAcknowledged = true
                    } else if Constants.InBodyStartDrop.contains(name) {
                        treeBuilder.error(self)
                        return false
                    } else {
                        treeBuilder.reconstructFormattingElements()
                        treeBuilder.insert(startTag: startTag)
                    }
                } else {
                    treeBuilder.reconstructFormattingElements()
                    treeBuilder.insert(startTag: startTag)
                }
                break
                
            case .EndTag:
                let endTag: Token.EndTag = (token as! Token.EndTag)
                if let name = endTag.normalizedName {
                    if Constants.InBodyEndAdoptionFormatters.contains(name) {
                        // Adoption Agency Algorithm.
                        for i in 0..<8 {
                            let formatEl: Element? = treeBuilder.getActiveFormattingElement(name)
                            if (formatEl == nil) {
                                return anyOtherEndTag(token, treeBuilder)
                            } else if (!treeBuilder.onStack(formatEl!)) {
                                treeBuilder.error(self)
                                treeBuilder.removeFromActiveFormattingElements(formatEl!)
                                return true
                            } else if (!treeBuilder.inScope(formatEl!.nodeName)) {
                                treeBuilder.error(self)
                                return false
                            } else if (treeBuilder.currentElement != formatEl!) {
                                treeBuilder.error(self)
                            }
                            
                            var furthestBlock: Element? = nil
                            var commonAncestor: Element? = nil
                            var seenFormattingElement: Bool = false
                            let stack: Array<Element> = treeBuilder.stack
                            // the spec doesn'token limit to < 64, but in degenerate cases (9000+ stack depth) self prevents
                            // run-aways
                            var stackSize = stack.count
                            if(stackSize > 64) { stackSize = 64 }
                            for si in 0..<stackSize {
                                let el: Element = stack[si]
                                if (el == formatEl) {
                                    commonAncestor = stack[si - 1]
                                    seenFormattingElement = true
                                } else if (seenFormattingElement && treeBuilder.isSpecial(el)) {
                                    furthestBlock = el
                                    break
                                }
                            }
                            if (furthestBlock == nil) {
                                treeBuilder.popStackToClose(formatEl!.nodeName)
                                treeBuilder.removeFromActiveFormattingElements(formatEl!)
                                return true
                            }
                            
                            // todo: Let a bookmark note the position of the formatting element in the list of active formatting elements relative to the elements on either side of it in the list.
                            // does that mean: int pos of format el in list?
                            var node: Element? = furthestBlock
                            var lastNode: Element? = furthestBlock
                            for j in 0..<3 {
                                if (node != nil && treeBuilder.onStack(node!)) {
                                    node = treeBuilder.aboveOnStack(node!)
                                }
                                // note no bookmark check
                                if (node != nil && !treeBuilder.isInActiveFormattingElements(node!)) {
                                    treeBuilder.removeFromStack(node!)
                                    continue
                                } else if (node == formatEl) {
                                    break
                                }
                                
                                let replacement: Element = Element(tag: Tag.valueOf(tagName: node!.nodeName, settings: ParseSettings.preserveCase), baseUri: treeBuilder.baseUri)
                                // case will follow the original node (so honours ParseSettings)
                                treeBuilder.replaceActiveFormattingElement(out: node!, new: replacement)
                                treeBuilder.replaceOnStack(out: node!, new: replacement)
                                node = replacement
                                
                                if (lastNode == furthestBlock) {
                                    // todo: move the aforementioned bookmark to be immediately after the node in the list of active formatting elements.
                                    // not getting how self bookmark both straddles the element above, but is inbetween here...
                                }
                                if (lastNode!.parentElement != nil) {
                                    lastNode?.removeFromParent()
                                }
                                node!.append(childNode: lastNode!)
                                
                                lastNode = node
                            }
                            
                            if Constants.InBodyEndTableFosters.contains(commonAncestor!.nodeName) {
                                if (lastNode!.parentElement != nil) {
                                    lastNode!.removeFromParent()
                                }
                                treeBuilder.insertInFosterParent(lastNode!)
                            } else {
                                if (lastNode!.parentElement != nil) {
                                    lastNode!.removeFromParent()
                                }
                                commonAncestor!.append(childNode: lastNode!)
                            }
                            
                            let adopter: Element = Element(tag: formatEl!.tag, baseUri: treeBuilder.baseUri)
                            adopter.attributes.append(dictionary: formatEl!.attributes)
                            var childNodes: [Node] = furthestBlock!.childNodes
                            for childNode: Node in childNodes {
                                adopter.append(childNode: childNode) // append will reparent. thus the clone to avoid concurrent mod.
                            }
                            furthestBlock?.append(childNode: adopter)
                            treeBuilder.removeFromActiveFormattingElements(formatEl!)
                            // todo: insert the element into the list of active formatting elements at the position of the aforementioned bookmark.
                            treeBuilder.removeFromStack(formatEl!)
                            treeBuilder.insertOnStack(after: furthestBlock!, new: adopter)
                        }
                    } else if Constants.InBodyEndClosers.contains(name) {
                        if (!treeBuilder.inScope(name)) {
                            // nothing to close
                            treeBuilder.error(self)
                            return false
                        } else {
                            treeBuilder.generateImpliedEndTags()
                            if (treeBuilder.currentElement!.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            treeBuilder.popStackToClose(name)
                        }
                    } else if (name == "span") {
                        // same as final fall through, but saves short circuit
                        return anyOtherEndTag(token, treeBuilder)
                    } else if (name == "li") {
                        if (!treeBuilder.inListItemScope(name)) {
                            treeBuilder.error(self)
                            return false
                        } else {
                            treeBuilder.generateImpliedEndTags(excludeTag: name)
                            if (treeBuilder.currentElement?.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            treeBuilder.popStackToClose(name)
                        }
                    } else if (name == "body") {
                        if (!treeBuilder.inScope("body")) {
                            treeBuilder.error(self)
                            return false
                        } else {
                            // todo: error if stack contains something not dd, dt, li, optgroup, option, p, rp, rt, tbody, td, tfoot, th, thead, tr, body, html
                            treeBuilder.transition(to: .AfterBody)
                        }
                    } else if (name == "html") {
                        let notIgnored: Bool = treeBuilder.process(endTag: "body")
                        if (notIgnored) {
                            return treeBuilder.process(token: endTag)
                        }
                    } else if (name == "form") {
                        let currentForm: Element? = treeBuilder.formElement
                        treeBuilder.formElement = nil
                        if (currentForm == nil || !treeBuilder.inScope(name)) {
                            treeBuilder.error(self)
                            return false
                        } else {
                            treeBuilder.generateImpliedEndTags()
                            if (treeBuilder.currentElement?.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            // remove currentForm from stack. will shift anything under up.
                            treeBuilder.removeFromStack(currentForm!)
                        }
                    } else if (name == "p") {
                        if (!treeBuilder.inButtonScope(name)) {
                            treeBuilder.error(self)
                            treeBuilder.process(startTag: name) // if no p to close, creates an empty <p></p>
                            return treeBuilder.process(token: endTag)
                        } else {
                            treeBuilder.generateImpliedEndTags(excludeTag: name)
                            if (treeBuilder.currentElement?.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            treeBuilder.popStackToClose(name)
                        }
                    } else if Constants.DdDt.contains(name) {
                        if (!treeBuilder.inScope(name)) {
                            treeBuilder.error(self)
                            return false
                        } else {
                            treeBuilder.generateImpliedEndTags(excludeTag: name)
                            if (treeBuilder.currentElement?.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            treeBuilder.popStackToClose(name)
                        }
                    } else if Constants.Headings.contains(name) {
                        if (!treeBuilder.inScope(Constants.Headings)) {
                            treeBuilder.error(self)
                            return false
                        } else {
                            treeBuilder.generateImpliedEndTags(excludeTag: name)
                            if (treeBuilder.currentElement?.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            treeBuilder.popStackToClose(Constants.Headings)
                        }
                    } else if (name == "sarcasm") {
                        // *sigh*
                        return anyOtherEndTag(token, treeBuilder)
                    } else if Constants.InBodyStartApplets.contains(name) {
                        if (!treeBuilder.inScope("name")) {
                            if (!treeBuilder.inScope(name)) {
                                treeBuilder.error(self)
                                return false
                            }
                            treeBuilder.generateImpliedEndTags()
                            if (treeBuilder.currentElement?.nodeName != name) {
                                treeBuilder.error(self)
                            }
                            treeBuilder.popStackToClose(name)
                            treeBuilder.clearFormattingElementsToLastMarker()
                        }
                    } else if (name == "br") {
                        treeBuilder.error(self)
                        treeBuilder.process(startTag: "br")
                        return false
                    } else {
                        return anyOtherEndTag(token, treeBuilder)
                    }
                } else {
                    return anyOtherEndTag(token, treeBuilder)
                }
                
                break
            case .EOF:
                // todo: error if stack contains something not dd, dt, li, p, tbody, td, tfoot, th, thead, tr, body, html
                // stop parsing
                break
            }
            return true
        case .Text:
            if (token.isCharacter) {
                treeBuilder.insert(character: token as! Token.Character)
            } else if (token.isEOF) {
                treeBuilder.error(self)
                // if current node is script: already started
                treeBuilder.pop()
                treeBuilder.transition(to: treeBuilder.originalState!)
                return treeBuilder.process(token: token)
            } else if (token.isEndTag) {
                // if: An end tag whose tag name is "script" -- scripting nesting level, if evaluating scripts
                treeBuilder.pop()
                treeBuilder.transition(to: treeBuilder.originalState!)
            }
            return true
        case .InTable:
            func anythingElse(_ token: Token, _ treeBuilder: HTMLTreeBuilder)->Bool {
                treeBuilder.error(self)
                var processed: Bool
                if (treeBuilder.currentElement != nil && ["table", "tbody", "tfoot", "thead", "tr"].contains(treeBuilder.currentElement!.nodeName)) {
                    treeBuilder.fosterInserts = true
                    processed = treeBuilder.process(token: token, state: .InBody)
                    treeBuilder.fosterInserts = false
                } else {
                    processed = treeBuilder.process(token: token, state: .InBody)
                }
                return processed
            }
            
            if (token.isCharacter) {
                treeBuilder.pendingTableCharacters = []
                treeBuilder.markInsertionMode()
                treeBuilder.transition(to: .InTableText)
                return treeBuilder.process(token: token)
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
                return true
            } else if (token.isDocType) {
                treeBuilder.error(self)
                return false
            } else if (token.isStartTag) {
                let startTag: Token.StartTag = (token as! Token.StartTag)
                if let name: String = startTag.normalizedName {
                    if (name == "caption") {
                        treeBuilder.clearStackToTableContext()
                        treeBuilder.insertMarkerToFormattingElements()
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.transition(to: .InCaption)
                    } else if (name == "colgroup") {
                        treeBuilder.clearStackToTableContext()
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.transition(to: .InColumnGroup)
                    } else if (name == "col") {
                        treeBuilder.process(startTag: "colgroup")
                        return treeBuilder.process(token: token)
                    } else if (["tbody", "tfoot", "thead"].contains(name)) {
                        treeBuilder.clearStackToTableContext()
                        treeBuilder.insert(startTag: startTag)
                        treeBuilder.transition(to: .InTableBody)
                    } else if (["td", "th", "tr"].contains(name)) {
                        treeBuilder.process(startTag: "tbody")
                        return treeBuilder.process(token: token)
                    } else if (name == "table") {
                        treeBuilder.error(self)
                        let processed: Bool = treeBuilder.process(endTag: "table")
                        if (processed) // only ignored if in fragment
                        {return treeBuilder.process(token: token)}
                    } else if (["style", "script"].contains(name)) {
                        return treeBuilder.process(token: token, state: .InHead)
                    } else if (name == "input") {
                        if (startTag.attributes.get(byTag: "type")?.value.lowercased() != "hidden") {
                            return anythingElse(token, treeBuilder)
                        } else {
                            treeBuilder.insert(empty: startTag)
                        }
                    } else if (name == "form") {
                        treeBuilder.error(self)
                        if (treeBuilder.formElement != nil) {
                            return false
                        } else {
                            treeBuilder.insert(form: startTag, onStack: false)
                        }
                    } else {
                        return anythingElse(token, treeBuilder)
                    }
                }
                return true // todo: check if should return processed http://www.whatwg.org/specs/web-apps/current-work/multipage/tree-construction.html#parsing-main-intable
            } else if (token.isEndTag) {
                let endTag: Token.EndTag = (token as! Token.EndTag)
                if let name: String = endTag.normalizedName {
                    if (name == "table") {
                        if (!treeBuilder.inTableScope(name)) {
                            treeBuilder.error(self)
                            return false
                        } else {
                            treeBuilder.popStackToClose("table")
                        }
                        treeBuilder.resetInsertionMode()
                    } else if (["body", "caption", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"].contains(name)) {
                        treeBuilder.error(self)
                        return false
                    } else {
                        return anythingElse(token, treeBuilder)
                    }
                } else {
                    return anythingElse(token, treeBuilder)
                }
                return true // todo: as above todo
            } else if (token.isEOF) {
                if (treeBuilder.currentElement != nil && treeBuilder.currentElement!.nodeName == "html") {
                    treeBuilder.error(self)
                }
                return true // stops parsing
            }
            return anythingElse(token, treeBuilder)
        case .InTableText:
            switch (token.type) {
            case .Character:
                let c: Token.Character = token as! Token.Character
                if (c.data != nil && c.data! == HTMLTreeBuilderState.nullString) {
                    treeBuilder.error(self)
                    return false
                } else {
                    treeBuilder.pendingTableCharacters.append(c.data!)
                }
                break
            default:
                // todo - don'token really like the way these table character data lists are built
                if (!treeBuilder.pendingTableCharacters.isEmpty) {
                    for character: String in treeBuilder.pendingTableCharacters {
                        if (!HTMLTreeBuilderState.isWhitespace(character)) {
                            // InTable anything else section:
                            treeBuilder.error(self)
                            if (treeBuilder.currentElement != nil && ["table", "tbody", "tfoot", "thead", "tr"].contains(treeBuilder.currentElement!.nodeName)) {
                                treeBuilder.fosterInserts = true
                                treeBuilder.process(token: build(Token.Character()) { $0.data = character }, state: .InBody)
                                treeBuilder.fosterInserts = false
                            } else {
                                treeBuilder.process(token: build(Token.Character()) { $0.data = character }, state: .InBody)
                            }
                        } else {
                            treeBuilder.insert(character: build(Token.Character()) { $0.data = character })
                        }
                    }
                    treeBuilder.pendingTableCharacters = []
                }
                treeBuilder.transition(to: treeBuilder.originalState!)
                return treeBuilder.process(token: token)
            }
            return true
        case .InCaption:
            if (token.isEndTag && (token as! Token.EndTag).normalizedName! == "caption") {
                let endTag: Token.EndTag = (token as! Token.EndTag)
                let name: String? = endTag.normalizedName
                if (name != nil && !treeBuilder.inTableScope(name!)) {
                    treeBuilder.error(self)
                    return false
                } else {
                    treeBuilder.generateImpliedEndTags()
                    if (treeBuilder.currentElement?.nodeName != "caption") {
                        treeBuilder.error(self)
                    }
                    treeBuilder.popStackToClose("caption")
                    treeBuilder.clearFormattingElementsToLastMarker()
                    treeBuilder.transition(to: .InTable)
                }
            } else if ((
                token.isStartTag && ["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"].contains((token as! Token.StartTag).normalizedName!) ||
                    token.isEndTag && (token as! Token.EndTag).normalizedName! == "table")
                ) {
                treeBuilder.error(self)
                let processed: Bool = treeBuilder.process(endTag: "caption")
                if (processed) {
                    return treeBuilder.process(token: token)
                }
            } else if (token.isEndTag && ["body", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"].contains((token as! Token.EndTag).normalizedName!)) {
                treeBuilder.error(self)
                return false
            } else {
                return treeBuilder.process(token: token, state: .InBody)
            }
            return true
        case .InColumnGroup:
            func anythingElse(token: Token, treeBuilder: TreeBuilder)->Bool {
                let processed: Bool = treeBuilder.process(endTag: "colgroup")
                if (processed) { // only ignored in frag case
                    return treeBuilder.process(token: token)
                }
                return true
            }
            
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                treeBuilder.insert(character: token as! Token.Character)
                return true
            }
            switch (token.type) {
            case .Comment:
                treeBuilder.insert(comment: token as! Token.Comment)
                break
            case .Doctype:
                treeBuilder.error(self)
                break
            case .StartTag:
                let startTag: Token.StartTag = (token as! Token.StartTag)
                let name: String? = startTag.normalizedName
                if ("html" == name) {
                    return treeBuilder.process(token: token, state: .InBody)
                } else if ("col" == name) {
                    treeBuilder.insert(empty: startTag)
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            case .EndTag:
                let endTag: Token.EndTag = (token as! Token.EndTag)
                let name = endTag.normalizedName
                if ("colgroup" == name) {
                    if ("html" == treeBuilder.currentElement?.nodeName) { // frag case
                        treeBuilder.error(self)
                        return false
                    } else {
                        treeBuilder.pop()
                        treeBuilder.transition(to: .InTable)
                    }
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            case .EOF:
                if ("html" == treeBuilder.currentElement?.nodeName) {
                    return true // stop parsing; frag case
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
            default:
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .InTableBody:
            @discardableResult
            func exitTableBody(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                if (!(treeBuilder.inTableScope("tbody") || treeBuilder.inTableScope("thead") || treeBuilder.inScope("tfoot"))) {
                    // frag case
                    treeBuilder.error(self)
                    return false
                }
                treeBuilder.clearStackToTableBodyContext()
                treeBuilder.process(endTag: treeBuilder.currentElement!.nodeName) // tbody, tfoot, thead
                return treeBuilder.process(token: token)
            }
            
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                return treeBuilder.process(token: token, state: .InTable)
            }
            
            switch (token.type) {
            case .StartTag:
                let startTag: Token.StartTag = (token as! Token.StartTag)
                let name: String? = startTag.normalizedName
                if ("tr" == name) {
                    treeBuilder.clearStackToTableBodyContext()
                    treeBuilder.insert(startTag: startTag)
                    treeBuilder.transition(to: .InRow)
                } else if (["th", "td"].contains(name!)) {
                    treeBuilder.error(self)
                    treeBuilder.process(startTag: "tr")
                    return treeBuilder.process(token: startTag)
                } else if ["caption", "col", "colgroup", "tbody", "tfoot", "thead"].contains(name!) {
                    return exitTableBody(token: token, treeBuilder: treeBuilder)
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            case .EndTag:
                let endTag: Token.EndTag = (token as! Token.EndTag)
                let name = endTag.normalizedName
                if (["tbody", "tfoot", "thead"].contains(name!)) {
                    if (!treeBuilder.inTableScope(name!)) {
                        treeBuilder.error(self)
                        return false
                    } else {
                        treeBuilder.clearStackToTableBodyContext()
                        treeBuilder.pop()
                        treeBuilder.transition(to: .InTable)
                    }
                } else if ("table" == name) {
                    return exitTableBody(token: token, treeBuilder: treeBuilder)
                } else if (["body", "caption", "col", "colgroup", "html", "td", "th", "tr"].contains(name!)) {
                    treeBuilder.error(self)
                    return false
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            default:
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .InRow:
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                return treeBuilder.process(token: token, state: .InTable)
            }
            
            func handleMissingTr(token: Token, treeBuilder: TreeBuilder)->Bool {
                let processed: Bool = treeBuilder.process(endTag: "tr")
                if (processed) {
                    return treeBuilder.process(token: token)
                } else {
                    return false
                }
            }
            
            if (token.isStartTag) {
                let startTag: Token.StartTag = (token as! Token.StartTag)
                let name: String? = startTag.normalizedName
                
                if (["th", "td"].contains(name!)) {
                    treeBuilder.clearStackToTableRowContext()
                    treeBuilder.insert(startTag: startTag)
                    treeBuilder.transition(to: .InCell)
                    treeBuilder.insertMarkerToFormattingElements()
                } else if (["caption", "col", "colgroup", "tbody", "tfoot", "thead", "tr"].contains(name!)) {
                    return handleMissingTr(token: token, treeBuilder: treeBuilder)
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
            } else if (token.isEndTag) {
                let endTag: Token.EndTag = (token as! Token.EndTag)
                let name: String? = endTag.normalizedName
                
                if ("tr" == name) {
                    if (!treeBuilder.inTableScope(name!)) {
                        treeBuilder.error(self) // frag
                        return false
                    }
                    treeBuilder.clearStackToTableRowContext()
                    treeBuilder.pop() // tr
                    treeBuilder.transition(to: .InTableBody)
                } else if ("table" == name) {
                    return handleMissingTr(token: token, treeBuilder: treeBuilder)
                } else if (["tbody", "tfoot", "thead"].contains(name!)) {
                    if (!treeBuilder.inTableScope(name!)) {
                        treeBuilder.error(self)
                        return false
                    }
                    treeBuilder.process(endTag: "tr")
                    return treeBuilder.process(token: token)
                } else if (["body", "caption", "col", "colgroup", "html", "td", "th"].contains(name!)) {
                    treeBuilder.error(self)
                    return false
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
            } else {
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .InCell:
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder)->Bool {
                return treeBuilder.process(token: token, state: .InBody)
            }
            
            func closeCell(treeBuilder: HTMLTreeBuilder) {
                if (treeBuilder.inTableScope("td")) {
                    treeBuilder.process(endTag: "td")
                } else {
                    treeBuilder.process(endTag: "th") // only here if th or td in scope
                }
            }
            
            if (token.isEndTag) {
                let endTag: Token.EndTag = (token as! Token.EndTag)
                let name: String? = endTag.normalizedName
                
                if (["td", "th"].contains(name!)) {
                    if (!treeBuilder.inTableScope(name!)) {
                        treeBuilder.error(self)
                        treeBuilder.transition(to: .InRow) // might not be in scope if empty: <td /> and processing fake end tag
                        return false
                    }
                    treeBuilder.generateImpliedEndTags()
                    if (name != treeBuilder.currentElement?.nodeName) {
                        treeBuilder.error(self)
                    }
                    treeBuilder.popStackToClose(name!)
                    treeBuilder.clearFormattingElementsToLastMarker()
                    treeBuilder.transition(to: .InRow)
                } else if (["body", "caption", "col", "colgroup", "html"].contains(name!)) {
                    treeBuilder.error(self)
                    return false
                } else if (["table", "tbody", "tfoot", "thead", "tr"].contains(name!)) {
                    if (!treeBuilder.inTableScope(name!)) {
                        treeBuilder.error(self)
                        return false
                    }
                    closeCell(treeBuilder: treeBuilder)
                    return treeBuilder.process(token: token)
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
            } else if (token.isStartTag &&
                ["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"].contains((token as! Token.StartTag).normalizedName!)) {
                if (!(treeBuilder.inTableScope("td") || treeBuilder.inTableScope("th"))) {
                    treeBuilder.error(self)
                    return false
                }
                closeCell(treeBuilder: treeBuilder)
                return treeBuilder.process(token: token)
            } else {
                return anythingElse(token: token, treeBuilder: treeBuilder)
            }
            return true
        case .InSelect:
            
            func anythingElse(token: Token, treeBuilder: HTMLTreeBuilder) -> Bool {
                treeBuilder.error(self)
                return false
            }
            
            switch (token.type) {
            case .Character:
                let c = token as! Token.Character
                if (HTMLTreeBuilderState.nullString == c.data) {
                    treeBuilder.error(self)
                    return false
                } else {
                    treeBuilder.insert(character: c)
                }
                break
            case .Comment:
                treeBuilder.insert(comment: token as! Token.Comment)
                break
            case .Doctype:
                treeBuilder.error(self)
                return false
            case .StartTag:
                let start: Token.StartTag = (token as! Token.StartTag)
                let name: String? = start.normalizedName
                if ("html" == name) {
                    return treeBuilder.process(token: start, state: .InBody)
                } else if ("option" == name) {
                    treeBuilder.process(endTag: "option")
                    treeBuilder.insert(startTag: start)
                } else if ("optgroup" == name) {
                    if ("option" == treeBuilder.currentElement?.nodeName) {
                        treeBuilder.process(endTag: "option")
                    } else if ("optgroup" == treeBuilder.currentElement?.nodeName) {
                        treeBuilder.process(endTag: "optgroup")
                    }
                    treeBuilder.insert(startTag: start)
                } else if ("select" == name) {
                    treeBuilder.error(self)
                    return treeBuilder.process(endTag: "select")
                } else if (["input", "keygen", "textarea"].contains(name!)) {
                    treeBuilder.error(self)
                    if (!treeBuilder.inSelectScope("select")) {
                        return false // frag
                    }
                    treeBuilder.process(endTag: "select")
                    return treeBuilder.process(token: start)
                } else if ("script" == name) {
                    return treeBuilder.process(token: token, state: .InHead)
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            case .EndTag:
                let end: Token.EndTag = (token as! Token.EndTag)
                let name = end.normalizedName
                if ("optgroup" == name) {
                    if ("option" == treeBuilder.currentElement?.nodeName && treeBuilder.aboveOnStack(treeBuilder.currentElement!) != nil && "optgroup" == treeBuilder.aboveOnStack(treeBuilder.currentElement!)?.nodeName) {
                        treeBuilder.process(endTag: "option")
                    }
                    if ("optgroup" == treeBuilder.currentElement?.nodeName) {
                        treeBuilder.pop()
                    } else {
                        treeBuilder.error(self)
                    }
                } else if ("option" == name) {
                    if ("option" == treeBuilder.currentElement?.nodeName) {
                        treeBuilder.pop()
                    } else {
                        treeBuilder.error(self)
                    }
                } else if ("select" == name) {
                    if (!treeBuilder.inSelectScope(name!)) {
                        treeBuilder.error(self)
                        return false
                    } else {
                        treeBuilder.popStackToClose(name!)
                        treeBuilder.resetInsertionMode()
                    }
                } else {
                    return anythingElse(token: token, treeBuilder: treeBuilder)
                }
                break
            case .EOF:
                if ("html" != treeBuilder.currentElement?.nodeName) {
                    treeBuilder.error(self)
                }
                break
                //            default:
                //                return anythingElse(token, treeBuilder)
            }
            return true
        case .InSelectInTable:
            if (token.isStartTag && ["caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"].contains((token as! Token.StartTag).normalizedName!)) {
                treeBuilder.error(self)
                treeBuilder.process(endTag: "select")
                return treeBuilder.process(token: token)
            } else if (token.isEndTag && ["caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"].contains((token as! Token.EndTag).normalizedName!)) {
                treeBuilder.error(self)
                if ((token as! Token.EndTag).normalizedName != nil &&  treeBuilder.inTableScope((token as! Token.EndTag).normalizedName!)) {
                    treeBuilder.process(endTag: "select")
                    return (treeBuilder.process(token: token))
                } else {
                    return false
                }
            } else {
                return treeBuilder.process(token: token, state: .InSelect)
            }
        case .AfterBody:
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                return treeBuilder.process(token: token, state: .InBody)
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment) // into html node
            } else if (token.isDocType) {
                treeBuilder.error(self)
                return false
            } else if (token.isStartTag && "html" == (token as! Token.StartTag).normalizedName) {
                return treeBuilder.process(token: token, state: .InBody)
            } else if (token.isEndTag && "html" == (token as! Token.EndTag).normalizedName) {
                if (treeBuilder.fragmentParsing) {
                    treeBuilder.error(self)
                    return false
                } else {
                    treeBuilder.transition(to: .AfterAfterBody)
                }
            } else if (token.isEOF) {
                // chillax! we're done
            } else {
                treeBuilder.error(self)
                treeBuilder.transition(to: .InBody)
                return treeBuilder.process(token: token)
            }
            return true
        case .InFrameset:
            
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                treeBuilder.insert(character: token as! Token.Character)
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (token.isDocType) {
                treeBuilder.error(self)
                return false
            } else if (token.isStartTag) {
                let start: Token.StartTag = (token as! Token.StartTag)
                let name: String? = start.normalizedName
                if ("html" == name) {
                    return treeBuilder.process(token: start, state: .InBody)
                } else if ("frameset" == name) {
                    treeBuilder.insert(startTag: start)
                } else if ("frame" == name) {
                    treeBuilder.insert(empty: start)
                } else if ("noframes" == name) {
                    return treeBuilder.process(token: start, state: .InHead)
                } else {
                    treeBuilder.error(self)
                    return false
                }
            } else if (token.isEndTag && "frameset" == (token as! Token.EndTag).normalizedName) {
                if ("html" == treeBuilder.currentElement?.nodeName) { // frag
                    treeBuilder.error(self)
                    return false
                } else {
                    treeBuilder.pop()
                    if (!treeBuilder.fragmentParsing && "frameset" != treeBuilder.currentElement?.nodeName) {
                        treeBuilder.transition(to: .AfterFrameset)
                    }
                }
            } else if (token.isEOF) {
                if ("html" != treeBuilder.currentElement?.nodeName) {
                    treeBuilder.error(self)
                    return true
                }
            } else {
                treeBuilder.error(self)
                return false
            }
            return true
        case .AfterFrameset:
            
            if (HTMLTreeBuilderState.isWhitespace(token)) {
                treeBuilder.insert(character: token as! Token.Character)
            } else if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (token.isDocType) {
                treeBuilder.error(self)
                return false
            } else if (token.isStartTag && "html" == (token as! Token.StartTag).normalizedName) {
                return treeBuilder.process(token: token, state: .InBody)
            } else if (token.isEndTag && "html" == (token as! Token.EndTag).normalizedName) {
                treeBuilder.transition(to: .AfterAfterFrameset)
            } else if (token.isStartTag && "noframes" == (token as! Token.StartTag).normalizedName) {
                return treeBuilder.process(token: token, state: .InHead)
            } else if (token.isEOF) {
                // cool your heels, we're complete
            } else {
                treeBuilder.error(self)
                return false
            }
            return true
        case .AfterAfterBody:
            
            if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (token.isDocType || HTMLTreeBuilderState.isWhitespace(token) || (token.isStartTag && "html" == (token as! Token.StartTag).normalizedName)) {
                return treeBuilder.process(token: token, state: .InBody)
            } else if (token.isEOF) {
                // nice work chuck
            } else {
                treeBuilder.error(self)
                treeBuilder.transition(to: .InBody)
                return treeBuilder.process(token: token)
            }
            return true
        case .AfterAfterFrameset:
            
            if (token.isComment) {
                treeBuilder.insert(comment: token as! Token.Comment)
            } else if (token.isDocType || HTMLTreeBuilderState.isWhitespace(token) || (token.isStartTag && "html" == (token as! Token.StartTag).normalizedName)) {
                return treeBuilder.process(token: token, state: .InBody)
            } else if (token.isEOF) {
                // nice work chuck
            } else if (token.isStartTag && "noframes" == (token as! Token.StartTag).normalizedName) {
                return treeBuilder.process(token: token, state: .InHead)
            } else {
                treeBuilder.error(self)
                return false
            }
            return true
        case .ForeignContent:
            return true
            // todo: implement. Also how do we get here?
        }
        
    }

    var description: String {
        return rawValue
    }
    
    private static func isWhitespace(_ token: Token) -> Bool {
        if (token.isCharacter) {
            let data: String? = (token as? Token.Character)?.data
            return isWhitespace(data)
        }
        return false
    }
    
    private static func isWhitespace(_ data: String?) -> Bool {
        // todo: self checks more than spec - UnicodeScalar.BackslashT, "\n", "\f", "\r", " "
        if let data = data {
            for c in data.unicodeScalars {
                if (!c.isWhitespace) {
                    return false}
            }
        }
        return true
    }
    
    private static func handleRcData(startTag: Token.StartTag, treeBuilder: HTMLTreeBuilder) {
        treeBuilder.insert(startTag: startTag)
        treeBuilder.tokeniser.transition(newState: TokeniserState.Rcdata)
        treeBuilder.markInsertionMode()
        treeBuilder.transition(to: .Text)
    }
    
    private static func handleRawText(startTag: Token.StartTag, treeBuilder: HTMLTreeBuilder) {
        treeBuilder.insert(startTag: startTag)
        treeBuilder.tokeniser.transition(newState: TokeniserState.Rawtext)
        treeBuilder.markInsertionMode()
        treeBuilder.transition(to: .Text)
    }
    
    // lists of tags to search through. A little harder to read here, but causes less GC than dynamic varargs.
    // was contributing around 10% of parse GC load.
    fileprivate final class Constants {
        fileprivate static let InBodyStartToHead: [String] = ["base", "basefont", "bgsound", "command", "link", "meta", "noframes", "script", "style", "title"]
        fileprivate static let InBodyStartPClosers: [String] = ["address", "article", "aside", "blockquote", "center", "details", "dir", "div", "dl",
                                                                "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "menu", "nav", "ol",
                                                                "p", "section", "summary", "ul"]
        fileprivate static let Headings: [String] = ["h1", "h2", "h3", "h4", "h5", "h6"]
        fileprivate static let InBodyStartPreListing: [String] = ["pre", "listing"]
        fileprivate static let InBodyStartLiBreakers: [String] = ["address", "div", "p"]
        fileprivate static let DdDt: [String] = ["dd", "dt"]
        fileprivate static let Formatters: [String] = ["b", "big", "code", "em", "font", "i", "s", "small", "strike", "strong", "tt", "u"]
        fileprivate static let InBodyStartApplets: [String] = ["applet", "marquee", "object"]
        fileprivate static let InBodyStartEmptyFormatters: [String] = ["area", "br", "embed", "img", "keygen", "wbr"]
        fileprivate static let InBodyStartMedia: [String] = ["param", "source", "track"]
        fileprivate static let InBodyStartInputAttribs: [String] = ["name", "action", "prompt"]
        fileprivate static let InBodyStartOptions: [String] = ["optgroup", "option"]
        fileprivate static let InBodyStartRuby: [String] = ["rp", "rt"]
        fileprivate static let InBodyStartDrop: [String] = ["caption", "col", "colgroup", "frame", "head", "tbody", "td", "tfoot", "th", "thead", "tr"]
        fileprivate static let InBodyEndClosers: [String] = ["address", "article", "aside", "blockquote", "button", "center", "details", "dir", "div",
                                                             "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "listing", "menu",
                                                             "nav", "ol", "pre", "section", "summary", "ul"]
        fileprivate static let InBodyEndAdoptionFormatters: [String] = ["a", "b", "big", "code", "em", "font", "i", "nobr", "s", "small", "strike", "strong", "tt", "u"]
        fileprivate static let InBodyEndTableFosters: [String] = ["table", "tbody", "tfoot", "thead", "tr"]
    }
}
