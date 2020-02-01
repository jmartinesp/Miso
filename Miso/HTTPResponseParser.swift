//
//  HTTPResponseValidator.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 8/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import AsyncHTTPClient

public protocol ResponseParserProtocol {
    associatedtype ResponseType: ResponseProtocol
    func parseResponse(error: Error?, response: HTTPClient.Response?, data: Data?, rawRequest: HTTPClient.Request) -> ResponseType
}

open class HTTPResponseParser: ResponseParserProtocol {
    
    public typealias ResponseType = HTTPConnection.Response
    
    private var validContentTypeRegex = try! NSRegularExpression(pattern: "^(application/json|text)/.*?(; charset=(.+?))?$", options: [])
    let request: HTTPConnection.Request
    
    public init(request: HTTPConnection.Request) {
        self.request = request
    }
    
    open func parseResponse(error: Error?, response: HTTPClient.Response?, data: Data?, rawRequest: HTTPClient.Request) -> HTTPConnection.Response {
        var error = error
        var decodingCharset: String.Encoding = .utf8
        
        // HTTP replied, there is no error
        guard response != nil && error == nil else {
            return HTTPConnection.Response(document: nil, error: error, data: data, rawRequest: rawRequest, rawResponse: response)
        }
        
        // Status code is 20X, we have data
        let statusCode = Int(response!.status.code)
        guard self.requestDidSucceed(withCode: statusCode) && data != nil else {
            error = HTTPError(errorCode: statusCode)
            return HTTPConnection.Response(document: nil, error: error, data: data, rawRequest: rawRequest, rawResponse: response)
        }
        
        // Valid Content-Type
        let contentType = response!.headers[HTTPConnection.CONTENT_TYPE] as? String
        guard request.ignoreContentType || (contentType != nil && contentType!.matches(self.validContentTypeRegex)) else {
            error = InvalidContentTypeError(contentType: contentType)
            return HTTPConnection.Response(document: nil, error: error, data: data, rawRequest: rawRequest, rawResponse: response)
        }
        
        if contentType != nil, let match = validContentTypeRegex.firstMatch(in: contentType!, options: [.anchored], range: NSRange(location: 0, length: contentType!.unicodeScalars.count)) {
            if match.numberOfRanges == 4, match.range(at: 3).location != Int.max,
                let encoding = String.Encoding.from(literal: contentType![Range<Int>(match.range(at: 3))!]) {
                decodingCharset = encoding
            }
        }
        
        // Can parse String
        if let htmlData = String(data: data!, encoding: decodingCharset) {
            let document = request.parser.parseInput(html: htmlData, baseUri: rawRequest.url.absoluteString)
            return HTTPConnection.Response(document: document, error: error, data: data,  rawRequest: rawRequest, rawResponse: response)
        } else if let asciiData = String(data: data!, encoding: .ascii) {
            // Fallback for 'exotic' encodings
            let document = request.parser.parseInput(html: asciiData, baseUri: rawRequest.url.absoluteString)
            return HTTPConnection.Response(document: document, error: error, data: data, rawRequest: rawRequest, rawResponse: response)
        } else {
            error = StringEncodingError(encoding: .utf8)
            return HTTPConnection.Response(document: nil, error: error, data: data, rawRequest: rawRequest, rawResponse: response)
        }
    }
    
    func requestDidSucceed(withCode statusCode: Int) -> Bool {
        return request.ignoreHTTPErrors || (statusCode >= 200 && statusCode < 300)
    }
    
}
