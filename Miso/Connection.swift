//
//  Connection.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 3/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

/**
 * A Connection provides a convenient interface to fetch content from the web, and parse them into Documents.
 * <p>
 * To get a new Connection, use {@link org.jsoup.Jsoup#connect(String)}. Connections contain {@link Connection.Request}
 * and {@link Connection.Response} objects. The request objects are reusable as prototype requests.
 * </p>
 * <p>
 * Request configuration can be made using either the shortcut methods in Connection (e.g. {@link #userAgent(String)}),
 * or by methods in the Connection.Request object directly. All request configuration must be made before the request is
 * executed.
 * </p>
 */
public protocol Connection {
    
    associatedtype RequestType: RequestProtocol
    associatedtype ResponseType: ResponseProtocol
    
    init?(url: String, session: URLSession)
    init(url: URL, session: URLSession)
    
    // TODO: see if there is a replacement in Swift for `func proxy(_ proxy: Proxy) -> Self`
    func proxy(host: String, port: Int) -> Self
    var proxy: HTTPConnection.Proxy? { get }
    
    func userAgent(_ agent: String) -> Self
    var userAgent: String { get }
    func timeout(_ time: TimeInterval?) -> Self
    var timeout: TimeInterval? { get }
    func maxBodySize(_ maxSize: Int?) -> Self
    var maxBodySize: Int? { get }
    func referrer(_ referrer: String?) -> Self
    var referrer: String? { get }
    func followRedirects(_ follows: Bool) -> Self
    var followRedirects: Bool { get }
    func ignoreHTTPErrors(_ ignore: Bool) -> Self
    var ignoreHTTPErrors: Bool { get }
    func ignoreContentType(_ ignore: Bool) -> Self
    var ignoreContentType: Bool { get }
    func validateTLSCertificate(_ validate: Bool) -> Self
    var validateTLSCertificate: Bool { get }
    
    func data(key: String, value: String?) -> Self
    func data(key: String, filename: String, data: Data) -> Self
    func data(params: [(key: String, value: String)]) -> Self
    func data(params: [String: String]) -> Self
    func data(key: String) -> String?
    func body(_ body: String?) -> Self
    func header(name: String) -> String?
    func header(name: String, value: String?) -> Self
    func headers(_ headers: [String: String]) -> Self
    func cookie(_ cookie: HTTPCookie) -> Self
    func cookie(name: String, value: String?) -> Self
    func cookies(_ cookies: [String: String]) -> Self
    func cookies(_ cookies: [HTTPCookie]) -> Self
    
    func parser(_ parser: Parser) -> Self
    func postDataEncoding(_ encoding: String.Encoding) -> Self
    
    func request(parse: Bool) -> ResponseType
    func request(responseHandler: @escaping (ResponseType) -> ())
}

public protocol RequestProtocol {
    mutating func toURLRequest(session: URLSession) -> URLRequest
}

public protocol ResponseProtocol {

    var error: Error? { get }
    var document: Document? { get }
    var data: Data? { get }

}

