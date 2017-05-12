//
//  HTTPResponseValidator.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 8/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public protocol ResponseParserProtocol {
    associatedtype ResponseType: ResponseProtocol
    func parseResponse(error: Error?, urlResponse: URLResponse?, data: Data?) -> ResponseType
}

open class HTTPResponseParser: ResponseParserProtocol {
    
    public typealias ResponseType = HTTPConnection.Response
    
    private var validContentTypeRegex = try! NSRegularExpression(pattern: "^(application/json|text)/.*?(; charset=(.+?))?$", options: [])
    let request: HTTPConnection.Request
    
    public init(request: HTTPConnection.Request) {
        self.request = request
    }
    
    open func parseResponse(error: Error?, urlResponse: URLResponse?, data: Data?) -> HTTPConnection.Response {
        var error = error
        let httpResponse = urlResponse as? HTTPURLResponse
        var decodingCharset: String.Encoding = .utf8
        
        // HTTP replied, there is no error
        guard urlResponse != nil && error == nil else {
            return HTTPConnection.Response(document: nil, error: error, data: nil, rawResponse: httpResponse)
        }
        
        // Status code is 20X, we have data
        let statusCode = httpResponse!.statusCode
        guard self.requestDidSucceed(withCode: statusCode) && data != nil else {
            error = HTTPError(errorCode: statusCode)
            return HTTPConnection.Response(document: nil, error: error, data: nil, rawResponse: httpResponse)
        }
        
        // Valid Content-Type
        let contentType = httpResponse!.allHeaderFields[HTTPConnection.CONTENT_TYPE] as? String
        guard request.ignoreContentType || (contentType != nil && contentType!.matches(self.validContentTypeRegex)) else {
            error = InvalidContentTypeError(contentType: contentType)
            return HTTPConnection.Response(document: nil, error: error, data: nil, rawResponse: httpResponse)
        }
        
        if let match = validContentTypeRegex.firstMatch(in: contentType!, options: [.anchored], range: NSRange(location: 0, length: contentType!.unicodeScalars.count)) {
            if match.numberOfRanges == 4, match.rangeAt(3).location != Int.max,
                let encoding = String.Encoding.from(literal: contentType![match.rangeAt(3).toRange()!]) {
                decodingCharset = encoding
            }
        }
        
        // Can parse String
        if let htmlData = String(data: data!, encoding: decodingCharset) {
            let document = request.parser.parseInput(html: htmlData, baseUri: httpResponse!.url!.absoluteString)
            return HTTPConnection.Response(document: document, error: error, data: htmlData, rawResponse: httpResponse)
        } else if let asciiData = String(data: data!, encoding: .ascii) {
            // Fallback for 'exotic' encodings
            let document = request.parser.parseInput(html: asciiData, baseUri: httpResponse!.url!.absoluteString)
            return HTTPConnection.Response(document: document, error: error, data: asciiData, rawResponse: httpResponse)
        } else {
            error = StringEncodingError(encoding: .utf8)
            return HTTPConnection.Response(document: nil, error: error, data: nil, rawResponse: httpResponse)
        }
    }
    
    func requestDidSucceed(withCode statusCode: Int) -> Bool {
        return request.ignoreHTTPErrors || (statusCode >= 200 && statusCode < 300)
    }
    
}
