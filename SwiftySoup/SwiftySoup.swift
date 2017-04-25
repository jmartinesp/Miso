//
// Created by Jorge Martín Espinosa on 17/4/17.
// Copyright (c) 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class SwiftySoup {

    /**
     Parse HTML into a Document. The parser will make a sensible, balanced document tree out of any HTML.
     @param html    HTML to parse
     @param baseUri The URL where the HTML was retrieved from. Used to resolve relative URLs to absolute URLs, that occur
     before the HTML declares a {@code <base href>} tag.
     @return sane HTML
     */
    public static func parse(html: String, baseUri: String?) -> Document {
        return Parser.parse(html: html, baseUri: baseUri)
    }

    /**
     Parse HTML into a Document, using the provided Parser. You can provide an alternate parser, such as a simple XML
     (non-HTML) parser.
     @param html    HTML to parse
     @param baseUri The URL where the HTML was retrieved from. Used to resolve relative URLs to absolute URLs, that occur
     before the HTML declares a {@code <base href>} tag.
     @param parser alternate {@link Parser#xmlParser() parser} to use.
     @return sane HTML
     */
    public static func parse(html: String, baseUri: String?, parser: Parser) -> Document {
        return parser.parseInput(html: html, baseUri: baseUri)
    }

    /**
     Parse HTML into a Document. As no base URI is specified, absolute URL detection relies on the HTML including a
     {@code <base href>} tag.
     @param html HTML to parse
     @return sane HTML
     @see #parse(String, String)
     */
    public static func parse(html: String) -> Document {
        return Parser.parse(html: html, baseUri: nil)
    }

    // TODO add Connection methods

    /**
     Parse the contents of a file as HTML.
     @param in          file to load HTML from
     @param charsetName (optional) character set of file contents. Set to {@code null} to determine from {@code http-equiv} meta tag, if
     present, or fall back to {@code UTF-8} (which is often safe to do).
     @param baseUri     The URL where the HTML was retrieved from, to resolve relative links against.
     @return sane HTML
     @throws IOException if the file could not be found, or read, or if the charsetName is invalid.
     */
    public static func parse(fromFile filePath: String, encoding: String.Encoding, baseUri: String? = nil) throws -> Document {
        let contents = try String(contentsOfFile: filePath, encoding: encoding)
        return Parser.parse(html: contents, baseUri: baseUri)
    }

    /**
     Read an input stream, and parse it to a Document. You can provide an alternate parser, such as a simple XML
     (non-HTML) parser.
     @param in          input stream to read. Make sure to close it after parsing.
     @param charsetName (optional) character set of file contents. Set to {@code null} to determine from {@code http-equiv} meta tag, if
     present, or fall back to {@code UTF-8} (which is often safe to do).
     @param baseUri     The URL where the HTML was retrieved from, to resolve relative links against.
     @param parser alternate {@link Parser#xmlParser() parser} to use.
     @return sane HTML
     @throws IOException if the file could not be found, or read, or if the charsetName is invalid.
     */
    public static func parse(data: Data, encoding: String.Encoding, baseUri: String? = nil) -> Document? {
        if let contents = String(data: data, encoding: encoding) {
            return Parser.parse(html: contents, baseUri: baseUri)
        } else {
            return nil
        }
    }

    /**
     Read an input stream, and parse it to a Document. You can provide an alternate parser, such as a simple XML
     (non-HTML) parser.
     @param in          input stream to read. Make sure to close it after parsing.
     @param charsetName (optional) character set of file contents. Set to {@code null} to determine from {@code http-equiv} meta tag, if
     present, or fall back to {@code UTF-8} (which is often safe to do).
     @param baseUri     The URL where the HTML was retrieved from, to resolve relative links against.
     @param parser alternate {@link Parser#xmlParser() parser} to use.
     @return sane HTML
     @throws IOException if the file could not be found, or read, or if the charsetName is invalid.
     */
    public static func parse(data: Data, encoding: String.Encoding, baseUri: String?, parser: Parser) -> Document? {
        if let contents = String(data: data, encoding: encoding) {
            return parser.parseInput(html: contents, baseUri: baseUri)
        } else {
            return nil
        }
    }

    /**
     Parse a fragment of HTML, with the assumption that it forms the {@code body} of the HTML.
     @param bodyHtml body HTML fragment
     @param baseUri  URL to resolve relative URLs against.
     @return sane HTML document
     @see Document#body()
     */
    public static func parse(bodyFragment: String, baseUri: String? = nil) -> Document {
        return Parser.parse(bodyFragment: bodyFragment, baseUri: baseUri)
    }

    /**
     Get safe HTML from untrusted input HTML, by parsing input HTML and filtering it through a white-list of permitted
     tags and attributes.
     @param bodyHtml  input untrusted HTML (body fragment)
     @param baseUri   URL to resolve relative URLs against
     @param whitelist white-list of permitted HTML elements
     @return safe HTML (body fragment)
     @see Cleaner#clean(Document)
     */
    public static func clean(bodyHtml: String, whitelist: Whitelist, baseUri: String?) -> String {
        let dirty = parse(bodyFragment: bodyHtml, baseUri: baseUri)
        let cleaner = Cleaner(whitelist: whitelist)
        let clean = cleaner.clean(document: dirty)
        return clean.body!.html
    }

    /**
    * Get safe HTML from untrusted input HTML, by parsing input HTML and filtering it through a white-list of
    * permitted tags and attributes.
    * <p>The HTML is treated as a body fragment; it's expected the cleaned HTML will be used within the body of an
    * existing document. If you want to clean full documents, use {@link Cleaner#clean(Document)} instead, and add
    * structural tags (<code>html, head, body</code> etc) to the whitelist.
    *
    * @param bodyHtml input untrusted HTML (body fragment)
    * @param baseUri URL to resolve relative URLs against
    * @param whitelist white-list of permitted HTML elements
    * @param outputSettings document output settings; use to control pretty-printing and entity escape modes
    * @return safe HTML (body fragment)
    * @see Cleaner#clean(Document)
    */
    public static func clean(bodyHtml: String, whitelist: Whitelist, outputSettings: OutputSettings, baseUri: String?) -> String {
        let dirty = parse(bodyFragment: bodyHtml, baseUri: baseUri)
        let cleaner = Cleaner(whitelist: whitelist)
        let clean = cleaner.clean(document: dirty)
        clean.outputSettings = outputSettings
        return clean.body!.html
    }

    /**
     Test if the input body HTML has only tags and attributes allowed by the Whitelist. Useful for form validation.
     <p>The input HTML should still be run through the cleaner to set up enforced attributes, and to tidy the output.
     <p>Assumes the HTML is a body fragment (i.e. will be used in an existing HTML document body.)
     @param bodyHtml HTML to test
     @param whitelist whitelist to test against
     @return true if no tags or attributes were removed; false otherwise
     @see #clean(String, org.jsoup.safety.Whitelist)
     */
    public static func isValid(bodyHtml: String, whitelist: Whitelist) -> Bool {
        return Cleaner(whitelist: whitelist).isValid(bodyHtml: bodyHtml)
    }

}
