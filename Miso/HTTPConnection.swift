//
//  HTTPConnection.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 3/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import AsyncHTTPClient
import NIOHTTP1
import NIO

public class HTTPConnection: Connection, CustomStringConvertible {

    private static let defaultHTTPClient = HTTPClient(eventLoopGroupProvider: .createNew)
    
    public typealias RequestType = HTTPConnection.Request
    public typealias ResponseType = HTTPConnection.Response


#if os(Linux)    
    public static let CONTENT_ENCODING = "content-encoding"
    public static let USER_AGENT = "user-agent"
    public static let CONTENT_TYPE = "content-type"
    public static let REFERRER = "referer"
    public static let MULTIPART_FORM_DATA = "multipart/form-data"
    public static let FORM_URL_ENCODED = "application/x-www-form-urlencoded"
#else
    public static let CONTENT_ENCODING = "Content-Encoding"
    public static let USER_AGENT = "User-Agent"
    public static let CONTENT_TYPE = "Content-Type"
    public static let REFERRER = "Referer"
    public static let MULTIPART_FORM_DATA = "multipart/form-data"
    public static let FORM_URL_ENCODED = "application/x-www-form-urlencoded"
#endif
    public static let COOKIE = "Cookie"

   
    /**
     * Many users would get caught by not setting a user-agent and therefore getting different responses on their desktop
     * vs in jsoup, which would otherwise default to {@code Java}. So by default, use a desktop UA.
     */
    fileprivate static let DEFAULT_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/51.0.2704.79 Chrome/51.0.2704.79 Safari/537.36"
    
    public static func connect(_ method: HTTPMethod, url: String) -> HTTPConnection? {
        return HTTPConnection(method, url: url)
    }
    
    public static func connect(_ method: HTTPMethod, url: URL) -> HTTPConnection {
        return HTTPConnection(method, url: url)
    }
    
    /**
     * Encodes the input URL into a safe ASCII URL string
     * @param url unescaped URL
     * @return escaped URL
     */
    private static func encode(url: String) -> String {
        if let realURL = URL(string: url) {
            return encode(url: realURL)
        } else {
            return url
        }
    }
    
    private static func encode(url: URL) -> String {
        if let data = url.absoluteString.data(using: .utf8), let encodedPath = String(bytes: data, encoding: .ascii) {
            return URL(string: encodedPath)?.absoluteString ?? url.absoluteString
        } else {
            return url.absoluteString
        }
    }
    
    private static func encode(mimeName: String) -> String {
        return mimeName.replaceAll(regex: "\"", by: "%22")
    }

    private var httpRequest: RequestType
    private var response: HTTPURLResponse?
    private var httpClient = HTTPConnection.defaultHTTPClient
    
    private var _followRedirects: Bool = false
    private var _validateTLS: Bool = true
    
    //======================================================================
    // MARK: Initializers
    //======================================================================
    
    public required init?(url: String) {
        guard let realURL = URL(string: url) else { return nil }
        self.httpRequest = Request(url: realURL)
    }
    
    public required init?(_ method: HTTPMethod, url: String) {
        guard let realURL = URL(string: url) else { return nil }
        self.httpRequest = Request(url: realURL, method: method)
    }
    
    public required init(url: URL) {
        self.httpRequest = Request(url: url)
    }
    
    public required init(_ method: HTTPMethod, url: URL) {
        self.httpRequest = Request(url: url, method: method)
    }
    
    //======================================================================
    // MARK: Proxy
    //======================================================================
    
    public func proxy(_ proxy: HTTPClient.Configuration.Proxy) -> Self {
        httpRequest.proxy = proxy
        return self
    }
    
    public func proxy(host: String, port: Int, authorization: HTTPClient.Authorization?) -> Self {
        httpRequest.proxy = HTTPClient.Configuration.Proxy.server(host: host, port: port, authorization: authorization)
        return self
    }
    
    public var proxy: HTTPClient.Configuration.Proxy? {
        return httpRequest.proxy
    }
    
    //======================================================================
    // MARK: User-Agent
    //======================================================================
    
    public func userAgent(_ agent: String) -> Self {
        httpRequest.headers[HTTPConnection.USER_AGENT] = agent
        return self
    }
    
    public var userAgent: String {
        return httpRequest.headers[HTTPConnection.USER_AGENT] ?? HTTPConnection.DEFAULT_USER_AGENT
    }
    
    //======================================================================
    // MARK: Request timeout
    //======================================================================
    
    public func timeout(_ time: TimeAmount?) -> Self {
        httpRequest.timeout = time
        return self
    }
    
    public var timeout: TimeAmount? { return httpRequest.timeout }
    
    //======================================================================
    // MARK: Referrer
    //======================================================================
    
    public func referrer(_ referrer: String?) -> Self {
        httpRequest.headers[HTTPConnection.REFERRER] = referrer
        return self
    }
    
    public var referrer: String? {
        return httpRequest.headers[HTTPConnection.REFERRER]
    }
    
    //======================================================================
    // MARK: Follow redirects
    //======================================================================
    
    public func followRedirects(_ follows: Bool) -> Self {
        self._followRedirects = follows
        return self
    }
    
    public var followRedirects: Bool {
        return _followRedirects
    }
    
    //======================================================================
    // MARK: Ignore HTTP Errors
    //======================================================================
    
    public func ignoreHTTPErrors(_ ignore: Bool) -> Self {
        httpRequest.ignoreHTTPErrors = ignore
        return self
    }
    
    public var ignoreHTTPErrors: Bool {
        return httpRequest.ignoreHTTPErrors
    }
    
    //======================================================================
    // MARK: Ignore ContentType
    //======================================================================
    
    public func ignoreContentType(_ ignore: Bool) -> Self {
        httpRequest.ignoreContentType = ignore
        return self
    }
    
    public var ignoreContentType: Bool {
        return httpRequest.ignoreContentType
    }
    
    //======================================================================
    // MARK: Validate TLS Certificate
    //======================================================================
    
    public func validateTLSCertificate(_ validate: Bool) -> Self {
        _validateTLS = validate
        return self
    }
    
    public var validateTLSCertificate: Bool {
        return _validateTLS
    }
    
    //======================================================================
    // MARK: Authentication
    //======================================================================
    
    public func authenticate(user: String, password: String) -> Self {
        httpRequest.authorization = .basic(username: user, password: password)
        return self
    }
    
    public func authenticate(token: String) -> Self {
        httpRequest.authorization = .bearer(tokens: token)
        return self
    }
    
    public func authentication() -> HTTPClient.Authorization? {
        return httpRequest.authorization
    }
    
    //======================================================================
    // MARK: Headers
    //======================================================================
    
    public func header(name: String) -> String? {
        return httpRequest.headers[name]
    }
    
    public func header(name: String, value: String?) -> Self {
        httpRequest.headers[name] = value
        return self
    }
    
    public func headers(_ headers: [String : String]) -> Self {
        for (key, value) in headers {
            httpRequest.headers[key] = value
        }
        return self
    }
    
    //======================================================================
    // MARK: Body - Query
    //======================================================================
    
    public func data(key: String) -> String? {
        return httpRequest.params[key]
    }
    
    public func data(key: String, value: String?) -> Self {
        httpRequest.params[key] = value
        return self
    }
    
    public func data(params: [String : String]) -> Self {
        for (key, value) in params.sorted(by: { $0.key < $1.key }) {
            httpRequest.params[key] = value
        }
        return self
    }
    
    public func data(key: String, filename: String, data: Data) -> Self {
        guard httpRequest.method.hasBody, let dataValue = String(data: data, encoding: .utf8) else { return self }
        // Percent encode both filename & value
        let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        httpRequest.params[key] = "; filename=\"\(encodedFilename)\"\r\nContent-Type: application/octet-stream\r\n\r\n" + dataValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        httpRequest.hasMultipartElement = true
        return self
    }
    
    public func data(params: [(key: String, value: String)]) -> Self {
        for (key, value) in params {
            httpRequest.params[key] = value
        }
        return self
    }
    
    public func body(_ body: String?) -> Self {
        httpRequest.rawBodyData = body?.data(using: postDataEncoding)
        return self
    }
    
    public func body(_ body: Data?) -> Self {
        httpRequest.rawBodyData = body
        return self
    }
    
    public func body<T: Encodable>(_ body: T?, encoder: JSONEncoder = JSONEncoder()) -> Self {
        guard let body = body, let data = try? encoder.encode(body) else { return self }
        httpRequest.rawBodyData = data
        return self
    }
    
    //======================================================================
    // MARK: Cookies
    //======================================================================
    
    public func cookie(_ cookie: HTTPCookie) -> Self {
        httpRequest.cookies[cookie.name] = cookie.value
        return self
    }
    
    public func cookies(_ cookies: [HTTPCookie]) -> Self {
        for cookie in cookies {
            _ = self.cookie(cookie)
        }
        return self
    }
    
    public func cookie(name: String, value: String?) -> Self {
        httpRequest.cookies[name] = value
        return self
    }
    
    public func cookies(_ cookies: [String : String]) -> Self {
        for (name, value) in cookies {
            httpRequest.cookies[name] = value
        }
        return self
    }
    
    //======================================================================
    // MARK: Parser
    //======================================================================
    
    public var parser: Parser {
        return httpRequest.parser
    }
    
    public func parser(_ parser: Parser) -> Self {
        httpRequest.parser = parser
        return self
    }
    
    //======================================================================
    // MARK: Encoding
    //======================================================================
    
    public func postDataEncoding(_ encoding: String.Encoding) -> Self {
        httpRequest.postDataEncoding = encoding
        return self
    }
    
    public var postDataEncoding: String.Encoding {
        return httpRequest.postDataEncoding
    }
    
    //======================================================================
    // MARK: Build
    //======================================================================
    
    public var rawRequest: HTTPClient.Request? {
        return try? httpRequest.toURLRequest()
    }
    
    //======================================================================
    // MARK: Request methods
    //======================================================================
    
    private func client(for request: HTTPConnection.RequestType) -> HTTPClient {
        var needsCustomConfig = false
        
        if request.proxy != nil || followRedirects || timeout != nil || !validateTLSCertificate {
            needsCustomConfig = true
        }
        
        if needsCustomConfig {
            var configuration = HTTPClient.Configuration()
            configuration.proxy = request.proxy
            configuration.redirectConfiguration = followRedirects ?
                .follow(max: Int.max, allowCycles: true) :
                .disallow
            configuration.timeout = .init(connect: timeout, read: timeout)
            configuration.tlsConfiguration = validateTLSCertificate ?
                .forClient() :
                .forClient(certificateVerification: .none)
            
            self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew, configuration: configuration)
            return self.httpClient
        } else {
            return Self.defaultHTTPClient
        }
    }
    
    public func invalidateClient() throws {
        try httpClient.syncShutdown()
    }
    
    private func invalidateClientIfNeeded() {
        if httpClient !== Self.defaultHTTPClient {
            try? invalidateClient()
        }
    }
    
    public func requestDocument() -> Document? {
        return self.request(parse: true)?.document
    }
    
    public func request(parse: Bool = true) -> ResponseType? {
        defer { self.invalidateClientIfNeeded() }
        
        guard let urlRequest = try? httpRequest.toURLRequest() else { return nil }
        let responseData = client(for: httpRequest).requestSynchronousData(request: urlRequest)
        
        let data = responseData.data
        let urlResponse = responseData.response
        let error = responseData.error
        
        if parse {
            return parseResponse(error: error, urlResponse: urlResponse, data: data, rawRequest: urlRequest)
        } else {
            return ResponseType(document: nil, error: error, data: data, rawRequest: urlRequest, rawResponse: urlResponse)
        }
    }
    
    public func request(parse: Bool, responseHandler: @escaping (ResponseType) -> ()) {
        defer { self.invalidateClientIfNeeded() }
        
        guard let urlRequest = try? httpRequest.toURLRequest() else { return }
        client(for: httpRequest).execute(request: urlRequest).whenComplete { result in
            
            var responseError: Error? = nil
            var data: Data? = nil
            var responseResult: HTTPClient.Response? = nil
            switch result {
            case .success(let response):
                responseResult = response
                var body = response.body
                let length = body?.readableBytes ?? 0
                data = body?.readData(length: length)
            case .failure(let error):
                responseError = error
            }
            
            let response: ResponseType
            if parse {
                response = self.parseResponse(error: responseError, urlResponse: responseResult, data: data, rawRequest: urlRequest)
            } else {
                response = ResponseType(document: nil, error: responseError, data: data, rawRequest: urlRequest, rawResponse: responseResult)
            }
            responseHandler(response)
        }
    }
    
    private func parseResponse(error: Error?, urlResponse: HTTPClient.Response?, data: Data?, rawRequest: HTTPClient.Request) -> Response {
        let responseParser = HTTPResponseParser(request: httpRequest)
        return responseParser.parseResponse(error: error, response: urlResponse, data: data, rawRequest: rawRequest)
    }
    
    public func debug() -> HTTPConnection {
        print(description)
        return self
    }
    
    public var description: String {
        return httpRequest.description
    }

    public class Request: RequestProtocol, CustomStringConvertible {

        public typealias Method = HTTPMethod

        init(url: URL, method: HTTPMethod = .GET) {
            self.url = url
            self.method = method
        }
        
        var authorization: HTTPClient.Authorization?
        var url: URL
        var method: HTTPMethod
        var proxy: HTTPClient.Configuration.Proxy? = nil
        var timeout: TimeAmount? = nil
        var parser: Parser = Parser.htmlParser
        var ignoreHTTPErrors: Bool = false
        var ignoreContentType: Bool = false
        var postDataEncoding: String.Encoding = .utf8

        var rawBodyData: Data? = nil
        var params = OrderedDictionary<String, String>()
        var headers = OrderedDictionary<String, String>()
        var cookies = [String: String]()
        var hasMultipartElement: Bool = false
        
        var rawComputedBody: String?

        private var needsMultipart: Bool {
            return method.hasBody && (hasMultipartElement || headers[HTTPConnection.CONTENT_ENCODING] == HTTPConnection.MULTIPART_FORM_DATA)
        }
        
        private func sanitizeDomain(url: URL) -> URL {
            var url = url
            if url.host != nil && url.absoluteString.hasSuffix(url.host!) {
                url.appendPathComponent("/")
            }
            return url
        }

        public func toURLRequest() throws -> HTTPClient.Request {
            var url = self.url
            
            var nioRequest = try HTTPClient.Request(url: sanitizeDomain(url: url), method: method)
            
            let headers = self.headers
            for header in headers {
                nioRequest.headers.add(name: header.key, value: header.value)
            }
            
            if let authorization = self.authorization {
                nioRequest.headers.add(name: "Authorization", value: authorization.headerValue)
            }
            
            if let bodyData = rawBodyData {
                nioRequest.body = .data(bodyData)
                rawComputedBody = String(data: bodyData, encoding: postDataEncoding)
            } else if method.hasBody {
                var bodyContents = ""
                if needsMultipart {
                    let boundary = randomBoundary()
                    headers[HTTPConnection.CONTENT_TYPE] = HTTPConnection.MULTIPART_FORM_DATA + "; boundary=" + boundary
                    bodyContents += params.map { (pair: (key: String, value: String)) -> String in
                        let key = pair.key.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
                        var base = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\""
                        if pair.value.hasPrefix("; filename") {
                            base += pair.value
                        } else {
                            base += "\r\n\r\n\(pair.value)"
                        }
                        return base
                    }
                    .joined()
                    bodyContents += "--\(boundary)--"
                } else {
                    // URL-Encoded
                    var allowedCharset = CharacterSet.urlQueryAllowed
                    allowedCharset.remove(charactersIn: "!;/?:@&=+$, ")
                    if headers[HTTPConnection.CONTENT_TYPE] == nil {
                        headers[HTTPConnection.CONTENT_TYPE] = HTTPConnection.FORM_URL_ENCODED + "; charset=" + postDataEncoding.displayName
                    }
                    bodyContents = params.map { (pair: (key: String, value: String)) -> String in
                        let key = pair.key.addingPercentEncoding(withAllowedCharacters: allowedCharset)!
                        let value = pair.value.addingPercentEncoding(withAllowedCharacters: allowedCharset)!
                        return "\(key)=\(value)"
                    }
                    .joined(separator: "&")
                }
                nioRequest.body = .string(bodyContents)
                rawComputedBody = bodyContents
            } else if !params.isEmpty {
                // ~GET
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                if urlComponents?.queryItems == nil {
                    urlComponents?.queryItems = []
                }
                params.forEach {
                    urlComponents?.queryItems?.append(URLQueryItem(name: $0.key, value: $0.value))
                }
                if let resultURL = urlComponents?.url {
                    url = resultURL
                    
                    nioRequest = try nioRequest.copy(newURL: url)
                }
            }
            
            // User-Agent
            if !headers.keys.contains(HTTPConnection.USER_AGENT) {
                nioRequest.headers.remove(name: HTTPConnection.USER_AGENT)
                nioRequest.headers.add(name: HTTPConnection.USER_AGENT, value: HTTPConnection.DEFAULT_USER_AGENT)
            }
                                    
            // Cookies
            if !headers.keys.contains(HTTPConnection.COOKIE) {
                let cookieStorage = HTTPCookieStorage.shared
                for cookie in cookies {
                    if let cookie = HTTPCookie(properties: [.name: cookie.key, .value: cookie.value]) {
                        cookieStorage.setCookie(cookie)
                    }
                }
            
                if let matchingCookies = cookieStorage.cookies(for: url) {
                    let cookieHeader = matchingCookies.map { "\($0.name)=\($0.value)" }.joined("; ")
                    nioRequest.headers.remove(name: HTTPConnection.COOKIE)
                    nioRequest.headers.add(name: HTTPConnection.COOKIE, value: cookieHeader)
                }
            }
            
            return nioRequest
        }

        // Generate random boundary for multipart requests
        static let boundaryChars = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".map { $0 }
        func randomBoundary() -> String {
            let boundary = StringBuilder()
            let count = 32
            for _ in 0..<count {
                let random = Int.random(in: 0..<Self.boundaryChars.count)
                boundary.append(Self.boundaryChars[random])
            }
            return boundary.stringValue
        }
        
        public var description: String {
            guard let urlRequest = try? toURLRequest() else { return "Invalid request" }
            let body = self.rawComputedBody ?? ""
            let cookies = HTTPCookieStorage.shared.cookies(for: urlRequest.url)?.map {
                "\($0.name): \($0.value)"
            }
            
            return """
            ===================== REQUEST =====================
            URL: \(urlRequest.url)
            Method: \(method)
            Body: \(body)
            Headers: \(headers)
            Cookies: \(cookies ?? [])
            ===================================================
            
            """
        }

    }

    public struct Response: ResponseProtocol {

        public var document: Document?
        public var error: Error?
        public var data: Data?
        public var rawRequest: HTTPClient.Request
        public var rawResponse: HTTPClient.Response?

    }
}

public struct HTTPError: LocalizedError {
    
    public let errorCode: Int
    public var localizedDescription: String {
        return "Error code: \(errorCode)"
    }
    
}

public struct StringEncodingError: LocalizedError {
    
    let encoding: String.Encoding
    public var localizedDescription: String {
        return "Could not encode data using encoding: \(encoding.displayName)"
    }
    
}

public struct InvalidContentTypeError: LocalizedError {
    
    let contentType: String?
    public var localizedDescription: String {
        return "Unknown content type: \(contentType ?? "nil")"
    }
    
}

extension HTTPClient.Request {
    
    func copy(newURL: URL) throws -> HTTPClient.Request {
        return try Self.init(url: newURL, method: method, headers: headers, body: body)
    }
    
}

extension HTTPMethod {
    
    var hasBody: Bool {
        if [.POST, .PUT, .PATCH].contains(self) {
            return true
        }
        return false
    }
    
}
