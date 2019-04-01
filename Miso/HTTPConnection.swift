//
//  HTTPConnection.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 3/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class HTTPConnection: Connection, CustomStringConvertible {
    
    public typealias RequestType = HTTPConnection.Request
    public typealias ResponseType = HTTPConnection.Response
    
    private static let PROXY_ENABLE = String(kCFNetworkProxiesHTTPEnable)
    private static let PROXY_HOST = String(kCFNetworkProxiesHTTPProxy)
    private static let PROXY_PORT = String(kCFNetworkProxiesHTTPPort)
    
    public static let CONTENT_ENCODING = "Content-Encoding"
    public static let USER_AGENT = "User-Agent"
    public static let CONTENT_TYPE = "Content-Type"
    public static let REFERRER = "Referer"
    public static let MULTIPART_FORM_DATA = "multipart/form-data"
    public static let FORM_URL_ENCODED = "application/x-www-form-urlencoded"
    
    /**
     * Many users would get caught by not setting a user-agent and therefore getting different responses on their desktop
     * vs in jsoup, which would otherwise default to {@code Java}. So by default, use a desktop UA.
     */
    fileprivate static let DEFAULT_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/51.0.2704.79 Chrome/51.0.2704.79 Safari/537.36"
    
    public static func connect(_ method: Request.Method, url: String) -> HTTPConnection? {
        return HTTPConnection(method, url: url)
    }
    
    public static func connect(_ method: Request.Method, url: URL) -> HTTPConnection {
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
    private var followRedirectsDelegate = ConfigurableSessionTaskDelegate()
    private var urlSession: URLSession
    
    //======================================================================
    // MARK: Initializers
    //======================================================================
    
    public required init?(url: String) {
        guard let realURL = URL(string: url) else { return nil }
        self.httpRequest = Request(url: realURL)
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                delegate: followRedirectsDelegate,
                                delegateQueue: OperationQueue())
    }
    
    public required init?(_ method: Request.Method, url: String) {
        guard let realURL = URL(string: url) else { return nil }
        self.httpRequest = Request(url: realURL, method: method)
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                delegate: followRedirectsDelegate,
                                delegateQueue: OperationQueue())
    }
    
    public required init(url: URL) {
        self.httpRequest = Request(url: url)
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                delegate: followRedirectsDelegate,
                                delegateQueue: OperationQueue())
    }
    
    public required init(_ method: Request.Method, url: URL) {
        self.httpRequest = Request(url: url, method: method)
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                delegate: followRedirectsDelegate,
                                delegateQueue: OperationQueue())
    }
    
    //======================================================================
    // MARK: Proxy
    //======================================================================
    
    public func proxy(host: String, port: Int) -> Self {
        guard let url = URL(string: host) else { return self }
        httpRequest.proxy = Proxy(url: url, port: port)
        return self
    }
    
    public var proxy: Proxy? {
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
    
    public func timeout(_ time: TimeInterval?) -> Self {
        httpRequest.timeout = time
        return self
    }
    
    public var timeout: TimeInterval? { return httpRequest.timeout }
    
    //======================================================================
    // MARK: Maximum Body Size
    //======================================================================
    
    public func maxBodySize(_ maxSize: Int?) -> Self {
        httpRequest.maxBodySize = maxSize
        return self
    }
    
    public var maxBodySize: Int? {
        return httpRequest.maxBodySize
    }
    
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
        followRedirectsDelegate.followRedirects = follows
        return self
    }
    
    public var followRedirects: Bool {
        return followRedirectsDelegate.followRedirects
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
        followRedirectsDelegate.validateTLSCertificates = validate
        return self
    }
    
    public var validateTLSCertificate: Bool {
        return followRedirectsDelegate.validateTLSCertificates
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
        httpRequest.rawBodyData = body
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
    
    public var rawRequest: URLRequest {
        return httpRequest.toURLRequest(session: urlSession)
    }
    
    //======================================================================
    // MARK: Request methods
    //======================================================================
    
    public func requestDocument() -> Document? {
        return self.request(parse: true).document
    }
    
    public func request(parse: Bool = true) -> ResponseType {
        let urlRequest = httpRequest.toURLRequest(session: urlSession)
        let responseData = urlSession.requestSynchronousData(request: urlRequest)
        
        let data = responseData.data
        let urlResponse = responseData.rawResponse
        let error = responseData.error
        
        if parse {
            return parseResponse(error: error, urlResponse: urlResponse, data: data)
        } else {
            let contents: String? = data != nil ?
                (String(data: data!, encoding: .utf8) ?? String(data: data!, encoding: .ascii)) :
                nil
            return ResponseType(document: nil, error: error, data: data, contents: contents, rawResponse: urlResponse)
        }
    }
    
    public func request(responseHandler: @escaping (ResponseType) -> ()) {
        let urlRequest = httpRequest.toURLRequest(session: urlSession)
        urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
            responseHandler(self.parseResponse(error: error, urlResponse: response, data: data))
        })
    }
    
    private func parseResponse(error: Error?, urlResponse: URLResponse?, data: Data?) -> Response {
        let responseParser = HTTPResponseParser(request: httpRequest)
        return responseParser.parseResponse(error: error, urlResponse: urlResponse, data: data)
    }
    
    public func debug() -> HTTPConnection {
        print(description)
        return self
    }
    
    public var description: String {
        return httpRequest.description
    }


    public struct Proxy {
        let url: URL
        let port: Int
    }

    public struct Request: RequestProtocol, CustomStringConvertible {

        public enum Method: String {
            case GET = "GET"
            case POST = "POST"
            case PUT = "PUT"
            case DELETE = "DELETE"
            case PATCH = "PATCH"
            case HEAD = "HEAD"
            case OPTIONS = "OPTIONS"
            case TRACE = "TRACE"

            /**
             * Check if this HTTP method has/needs a request body
             * @return if body needed
             */
            var hasBody: Bool {
                if [.POST, .PUT, .PATCH].contains(self) {
                    return true
                }
                return false
            }
        }

        init(url: URL, method: Request.Method = .GET) {
            self.url = url
            self.method = method
        }

        var url: URL
        var method: Request.Method
        var proxy: Proxy? = nil
        var timeout: TimeInterval? = nil
        var maxBodySize: Int? = nil
        var parser: Parser = Parser.htmlParser
        var ignoreHTTPErrors: Bool = false
        var ignoreContentType: Bool = false
        var postDataEncoding: String.Encoding = .utf8

        var rawBodyData: String? = nil
        var params = OrderedDictionary<String, String>()
        var headers = OrderedDictionary<String, String>()
        var cookies = [String: String]()
        var hasMultipartElement: Bool = false

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

        public func toURLRequest(session: URLSession) -> URLRequest {
            var headers = self.headers
            var url = self.url
            
            var urlRequest = URLRequest(url: sanitizeDomain(url: url))
            urlRequest.httpMethod = method.rawValue

            if proxy != nil {
                session.configuration.connectionProxyDictionary = [
                        HTTPConnection.PROXY_ENABLE: true,
                        HTTPConnection.PROXY_PORT: proxy!.port,
                        HTTPConnection.PROXY_HOST: proxy!.url.host!
                ]
            }

            if let timeout = self.timeout {
                urlRequest.timeoutInterval = timeout
            }

            // Params
            var bodyContents = ""
            if rawBodyData != nil {
                // Set body data directly
                bodyContents = rawBodyData!
            } else if method.hasBody {
                // ~POST method
                if needsMultipart {
                    // Multipart
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
                    var allowedCharset = NSCharacterSet.urlQueryAllowed
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
            } else if !params.isEmpty {
                // ~GET
                var urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
                if urlComponents?.queryItems == nil {
                    urlComponents?.queryItems = []
                }
                params.forEach {
                    urlComponents?.queryItems?.append(URLQueryItem(name: $0.key, value: $0.value))
                }
                if let resultURL = urlComponents?.url {
                    url = resultURL
                    urlRequest.url = url
                }
            }

            // Set body data if needed
            if !bodyContents.isEmpty {
                if maxBodySize != nil {
                    bodyContents = bodyContents[0..<maxBodySize!]
                }
                urlRequest.httpBody = bodyContents.data(using: postDataEncoding)
            }

            // Headers
            headers.forEach { key, value in
                urlRequest.allHTTPHeaderFields?[key] = value
            }

            // User-Agent
            if !headers.keys.contains(HTTPConnection.USER_AGENT) {
                urlRequest.setValue(HTTPConnection.DEFAULT_USER_AGENT, forHTTPHeaderField: HTTPConnection.USER_AGENT)
            }

            // Cookies
            if let cookieStorage = session.configuration.httpCookieStorage {
                cookies.forEach {
                    if let cookie = HTTPCookie(properties: [.name: $0.key, .value: $0.value]) {
                        // TODO check if needs more info
                        cookieStorage.setCookie(cookie)
                    }
                }
            }

            return urlRequest
        }

        // Generate random boundary for multipart requests
        let boundaryChars = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".map {
            $0
        }
        func randomBoundary() -> String {
            let boundary = StringBuilder()
            let count = 32
            for _ in 0..<count {
                let random = Int.random(in: 0..<boundaryChars.count)
                boundary.append(boundaryChars[random])
            }
            return boundary.stringValue
        }
        
        public var description: String {
            let urlRequest = toURLRequest(session: URLSession.shared)
            let body = urlRequest.httpBody != nil ? String(data: urlRequest.httpBody!, encoding: postDataEncoding)! : ""
            let cookies = HTTPCookieStorage.shared.cookies(for: urlRequest.url!)?.map {
                "\($0.name): \($0.value)"
            }
            
            return """
            ===================== REQUEST =====================
            URL: \(urlRequest.url!)
            Method: \(method)
            Body: \(body)
            Headers: \(urlRequest.allHTTPHeaderFields ?? [:])
            Cookies: \(cookies ?? [])
            ===================================================
            
            """
        }

    }

    public struct Response: ResponseProtocol {

        public var document: Document?
        public var error: Error?
        public var data: Data?
        public var contents: String?
        public var rawResponse: HTTPURLResponse?

    }
}

class ConfigurableSessionTaskDelegate: NSObject, URLSessionTaskDelegate {

    var validateTLSCertificates: Bool = true
    var followRedirects: Bool = false

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {

        var responseRequest: URLRequest? = nil

        if followRedirects {
            responseRequest = request
            completionHandler(responseRequest)
        } else {
            completionHandler(nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if validateTLSCertificates {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let trust = challenge.protectionSpace.serverTrust {
                    let credential = URLCredential(trust: trust)
                    completionHandler(.performDefaultHandling, credential)
                    return
                }
            }
        } else {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let trust = challenge.protectionSpace.serverTrust {
                    let credential = URLCredential(trust: trust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }

        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("Finished")
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("Error")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Completed - error")
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
