//
// Created by Jorge Martín Espinosa on 17/4/17.
// Copyright (c) 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

/**
 The whitelist based HTML cleaner. Use to ensure that end-user provided HTML contains only the elements and attributes
 that you are expecting; no junk, and no cross-site scripting attacks!
 <p>
 The HTML cleaner parses the input as HTML and then runs it through a white-list, so the output HTML can only contain
 HTML that is allowed by the whitelist.
 </p>
 <p>
 It is assumed that the input HTML is a body fragment; the clean methods only pull from the source's body, and the
 canned white-lists only allow body contained tags.
 </p>
 <p>
 Rather than interacting directly with a Cleaner object, generally see the {@code clean} methods in {@link org.jsoup.Jsoup}.
 </p>
 */
open class Cleaner {

    private let whitelist: Whitelist

    /**
     Create a new cleaner, that sanitizes documents using the supplied whitelist.
     @param whitelist white-list to clean with
     */
    public init(whitelist: Whitelist) {
        self.whitelist = whitelist
    }

    /**
     Creates a new, clean document, from the original dirty document, containing only elements allowed by the whitelist.
     The original document is not modified. Only elements from the dirt document's <code>body</code> are used.
     @param dirtyDocument Untrusted base document to clean.
     @return cleaned document.
     */
    open func clean(document dirty: Document) -> Document {
        let cleanDoc = Document.createEmpty(baseUri: dirty.baseUri)

        if dirty.body != nil {
            _ = copySafeNodes(from: dirty.body!, to: cleanDoc.body!)
        }

        return cleanDoc
    }

    /**
     Determines if the input document <b>body</b>is valid, against the whitelist. It is considered valid if all the tags and attributes
     in the input HTML are allowed by the whitelist, and that there is no content in the <code>head</code>.
     <p>
     This method can be used as a validator for user input. An invalid document will still be cleaned successfully
     using the {@link #clean(Document)} document. If using as a validator, it is recommended to still clean the document
     to ensure enforced attributes are set correctly, and that the output is tidied.
     </p>
     @param dirtyDocument document to test
     @return true if no tags or attributes need to be removed; false if they do
     */
    open func isValid(document dirty: Document) -> Bool {
        let clean = Document.createEmpty(baseUri: dirty.baseUri)
        let numDiscarded = copySafeNodes(from: dirty.body!, to: clean.body!)

        // because we only look at the body, but we start from a shell, make sure there's nothing in the head
        return numDiscarded == 0 && dirty.head!.childNodes.count == 0
    }

    open func isValid(bodyHtml: String) -> Bool {
        let clean = Document.createEmpty(baseUri: nil)
        let dirty = Document.createEmpty(baseUri: nil)

        let errorList = ParseErrorList.tracking(maxSize: 1)
        if let nodes = try? Parser.Safe.parse(fragmentHTML: bodyHtml, withContext: dirty.body, baseUri: nil, errors: errorList) {
            dirty.body?.insert(children: nodes, at: 0)
            let numDiscarded = copySafeNodes(from: dirty.body!, to: clean.body!)
            return numDiscarded == 0 && errorList.isEmpty
        } else {
            return false
        }
    }

    private func copySafeNodes(from source: Element, to dest: Element) -> Int {
        let cleaningVisitor = CleaningVisitor(cleaner: self, root: source, dest: dest)
        let traversor = NodeTraversor(visitor: cleaningVisitor)
        traversor.traverse(root: source)
        return cleaningVisitor.numDiscarded
    }

    private func createSafeElement(_ element: Element) -> ElementMeta {
        let sourceTag = element.tagName
        let destAttrs = Attributes()
        let dest = Element(tag: Tag.valueOf(tagName: sourceTag), baseUri: element.baseUri, attributes: destAttrs)
        var numDiscarded = 0

        let sourceAttrs = element.attributes
        for (key, attribute) in sourceAttrs {
            if whitelist.isSafeAttribute(attribute, in: element, forTag: sourceTag) {
                destAttrs.put(string: attribute.value, forKey: key)
            } else {
                numDiscarded += 1
            }
        }

        let enforcedAttrs = whitelist.getEnforcedAttributes(forTag: sourceTag)
        destAttrs.append(dictionary: enforcedAttrs)

        return ElementMeta(element: dest, numDiscarded: numDiscarded)
    }

    private struct ElementMeta {
        let element: Element
        let numDiscarded: Int
    }

    /**
     Iterates the input and copies trusted nodes (tags, attributes, text) into the destination.
     */
    private class CleaningVisitor: NodeVisitorProtocol {

        var numDiscarded = 0
        weak var cleaner: Cleaner!
        var root: Element?
        var destination: Element?

        init(cleaner: Cleaner, root: Element?, dest: Element?) {
            self.cleaner = cleaner
            self.root = root
            self.destination = dest
        }

        var head : ((Node, Int) -> Void) {
            return { [unowned self] node, depth in
                if let sourceElement = node as? Element {
                    if self.cleaner.whitelist.isSafeTag(sourceElement.tagName) { // safe, clone and copy safe attrs
                        let meta = self.cleaner.createSafeElement(sourceElement)
                        let destChild = meta.element
                        self.destination?.append(childNode: destChild)

                        self.numDiscarded += meta.numDiscarded
                        self.destination = destChild
                    } else if sourceElement != self.root { // not a safe tag, so don't add. don't count root against discarded.
                        self.numDiscarded += 1
                    }
                } else if let sourceText = node as? TextNode {
                    let destText = TextNode(text: sourceText.wholeText, baseUri: sourceText.baseUri)
                    self.destination?.append(childNode: destText)
                } else if let dataNode = node as? DataNode, self.cleaner.whitelist.isSafeTag(node.parentNode!.nodeName) {
                    let destData = DataNode(data: dataNode.wholeData, baseUri: dataNode.baseUri)
                    self.destination?.append(childNode: destData)
                } else { // else, we don't care about comments, xml proc instructions, etc
                    self.numDiscarded += 1
                }
            }
        }

        var tail : ((Node, Int) -> Void) {
            return { [unowned self] node, depth in
                if node is Element && self.cleaner.whitelist.isSafeTag(node.nodeName) {
                    self.destination = self.destination?.parentElement
                }
            }
        }
    }
}
