//
//  ConnectionTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 4/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

/*
import XCTest
@testable import Miso

// Fake HTTP server dependencies
import Embassy
import Ambassador

struct FakeHTTPServer {
    let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
    let router = Router()
    let server: HTTPServer
    
    init() {
        server = DefaultHTTPServer(eventLoop: loop, port: 8080, app: router.app)
        
        router["/api/v2/users"] = DelayResponse(JSONResponse(handler: { _ -> Any in
            return [
                ["id": "01", "name": "john"],
                ["id": "02", "name": "tom"]
            ]
        }))
    }
    
    func start() {
        // Start HTTP server to listen on the port
        try! server.start()
        
        // Run event loop
        loop.runForever()
    }
}

class ConnectionTest: XCTestCase {
    
    let loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    
    func testSimpleRequest() {
        let response = HTTPConnection(url: "https://www.google.es/")!.request()
        XCTAssertNil(response.error)
        XCTAssertEqual(200, response.rawResponse?.statusCode)
    }
    
    //======================================================================
    // MARK: HTTPS
    //======================================================================
    
    func testSelfSignedTLSFails() {
        let response = HTTPConnection(url: "https://self-signed.badssl.com/")!.request()
        XCTAssertNotNil(response.error)
        XCTAssertNil(response.rawResponse?.statusCode)
    }
    
    func testExpiredTLSFails() {
        let response = HTTPConnection(url: "https://expired.badssl.com/")!.request()
        XCTAssertNotNil(response.error)
        XCTAssertNil(response.rawResponse?.statusCode)
    }
    
    func testExpiredTLSSucceedsIfValidationDisabled() {
        let response = HTTPConnection(url: "https://expired.badssl.com/")!
            .validateTLSCertificate(false)
            .request()
        XCTAssertNil(response.error)
        XCTAssertEqual(200, response.rawResponse?.statusCode)
    }
    
    func testSelfSignedTLSSucceedsIfValidationDisabled() {
        let response = HTTPConnection(url: "https://self-signed.badssl.com/")!
            .validateTLSCertificate(false)
            .request()
        XCTAssertNil(response.error)
        XCTAssertEqual(200, response.rawResponse?.statusCode)
    }
    
    func testValidTLS() {
        let response = HTTPConnection(url: "https://rsa2048.badssl.com/")!.request()
        XCTAssertNil(response.error)
        XCTAssertEqual(200, response.rawResponse?.statusCode)
    }
    
    //======================================================================
    // MARK: Params - GET
    //======================================================================
    
    func testGETParamsOneAtATime() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(key: "limit", value: "1")
            .data(key: "album_type", value: "SINGLE")
            .rawRequest
        
        XCTAssertEqual("http://test.com/?limit=1&album_type=SINGLE", request.url?.absoluteString)
    }
    
    func testGETParamsDictionary() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(params: ["limit": "1", "album_type": "SINGLE"])
            .rawRequest
        
        XCTAssertEqual("http://test.com/?album_type=SINGLE&limit=1", request.url?.absoluteString)
    }
    
    func testGETEmptyParamsDictionary() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(params: [:])
            .rawRequest
        
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testGETEmptyParamsArray() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(params: [])
            .rawRequest
        
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testGETParamsArray() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(params: [(key: "limit", value: "1"), (key: "album_type", value: "SINGLE")])
            .rawRequest
        
        XCTAssertEqual("http://test.com/?limit=1&album_type=SINGLE", request.url?.absoluteString)
    }
    
    func testGETChangeParams() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(key: "limit", value: "1")
            .data(key: "album_type", value: "SINGLE")
            .data(key: "album_type", value: "ALBUM")
            .rawRequest
        
        XCTAssertEqual("http://test.com/?limit=1&album_type=ALBUM", request.url?.absoluteString)
    }
    
    func testGETEncodeParams() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.GET, url: baseURL)!
            .data(key: "album_type", value: "SINGLE&l")
            .data(key: "imit", value: "1")
            .rawRequest
        XCTAssertEqual("http://test.com/?album_type=SINGLE%26l&imit=1", request.url?.absoluteString)
    }
    
    //======================================================================
    // MARK: Params - POST
    //======================================================================
    
    func testPOSTParamsOneAtATime() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(key: "Test", value: "Works")
            .data(key: "Test2", value: "Works2")
            .rawRequest
        
        XCTAssertEqual("Test=Works&Test2=Works2", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTParamsDictionary() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(params: ["Test": "Works", "Test2": "Works2"])
            .rawRequest
        
        XCTAssertEqual("Test=Works&Test2=Works2", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTParamsEmptyDictionary() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(params: [:])
            .rawRequest
        
        XCTAssertNil(request.httpBody)
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTParamsArray() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(params: [(key: "Test", value: "Works"), (key: "Test2", value: "Works2")])
            .rawRequest
        
        XCTAssertEqual("Test=Works&Test2=Works2", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTParamsEmptyArray() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(params: [])
            .rawRequest
        
        XCTAssertNil(request.httpBody)
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTChangeParams() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(key: "Test", value: "Works")
            .data(key: "Test2", value: "Works2")
            .data(key: "Test", value: "Definitely works")
            .rawRequest
        
        XCTAssertEqual("Test=Definitely%20works&Test2=Works2", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTEncodeParams() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(key: "Test", value: "Works&")
            .data(key: "&Test", value: ";Works")
            .rawRequest
        
        XCTAssertEqual("Test=Works%26&%26Test=%3BWorks", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTBody() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .body("Contents!")
            .rawRequest
        
        XCTAssertEqual("Contents!", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testPOSTMutipart() {
        let baseURL = "http://test.com"
        let path = Bundle(for: ConnectionTest.self).path(forResource: "postText", ofType: "txt")
        let contents = try! String(contentsOfFile: path!).data(using: .utf8)!
        
        let request = HTTPConnection(.POST, url: baseURL)!
            .data(key: "Test", value: "It works!")
            .data(key: "data", filename: "postTest.txt", data: contents)
            .rawRequest
        
        let body = String(data: request.httpBody!, encoding: .utf8)!
        
        let contentType = request.allHTTPHeaderFields!["Content-Type"]!
        XCTAssert(contentType.hasPrefix("multipart/form-data"))
        let boundary = contentType.components(separatedBy: "boundary=")[1]
        XCTAssertEqual("--\(boundary)\r\nContent-Disposition: form-data; name=\"Test\"\r\n\r\nIt works!--\(boundary)\r\nContent-Disposition: form-data; name=\"data\"; filename=\"postTest%2Etxt\"\r\nContent-Type: application/octet-stream\r\n\r\nTesting%20multipart%20POST%20request%21%0A--\(boundary)--", body)
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    //======================================================================
    // MARK: Maximum Body Size
    //======================================================================
    
    func testMaxBodySize() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .body(loremIpsum)
            .maxBodySize(20)
            .rawRequest
        
        XCTAssertEqual("Lorem ipsum dolor si", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    func testMaxBodySizeUnicode() {
        let baseURL = "http://test.com"
        let request = HTTPConnection(.POST, url: baseURL)!
            .body("á😀öñç!")
            .maxBodySize(4)
            .rawRequest
        
        XCTAssertEqual("á😀öñ", String(data: request.httpBody!, encoding: .utf8))
        XCTAssertEqual("http://test.com/", request.url?.absoluteString)
    }
    
    //======================================================================
    // MARK: Follows redirects
    //======================================================================
    
    func testFollowsRedirects() {
        // 301: Moved Permanently
        var request = HTTPConnection(url: "http://httpstat.us/301")!.followRedirects(true)
        var response = request.request()
        XCTAssertEqual(200, response.rawResponse?.statusCode)
        XCTAssert(response.contents!.contains("This is a super simple service for generating different HTTP codes."))
        
        // 307: Temporary Redirect
        request = HTTPConnection(url: "http://httpstat.us/307")!.followRedirects(true)
        response = request.request()
        XCTAssertEqual(200, response.rawResponse?.statusCode)
        XCTAssert(response.contents!.contains("This is a super simple service for generating different HTTP codes."))
        
        // 308: Permanent Redirect
        request = HTTPConnection(url: "http://httpstat.us/308")!.followRedirects(true)
        response = request.request()
        XCTAssertEqual(200, response.rawResponse?.statusCode)
        XCTAssert(response.contents!.contains("This is a super simple service for generating different HTTP codes."))
    }
    
    /*
     * Crashes due to Apple bug: https://openradar.appspot.com/31284156 ¯\_(ツ)_/¯
     *
    func testDontFollowsRedirects() {
        // 301: Moved Permanently
        var request = HTTPConnection(url: "http://httpstat.us/301")!
        var response = request.request()
        XCTAssertEqual(301, response.rawResponse?.statusCode)
        XCTAssertEqual(nil, response.data)
        
        // 307: Temporary Redirect
        request = HTTPConnection(url: "http://httpstat.us/307")!
        response = request.request()
        XCTAssertEqual(307, response.rawResponse?.statusCode)
        XCTAssertEqual(nil, response.data)
        
        // 308: Permanent Redirect
        request = HTTPConnection(url: "http://httpstat.us/308")!
        response = request.request()
        XCTAssertEqual(308, response.rawResponse?.statusCode)
        XCTAssertEqual(nil, response.data)
    }*/
    
    //======================================================================
    // MARK: Ignore HTTP Errors
    //======================================================================
    
    func testIgnoreHTTPErrors() {
        let request = HTTPConnection(url: "http://httpstat.us/404")?.ignoreHTTPErrors(true)
        let response = request?.request()
        
        XCTAssertEqual("404 Not Found", response?.contents)
        XCTAssertEqual(404, response?.rawResponse?.statusCode)
        XCTAssertNil(response?.error)
    }
    
    func testDontIgnoreHTTPErrors() {
        let request = HTTPConnection(url: "http://httpstat.us/404")
        let response = request?.request()
        
        XCTAssertNil(response?.contents)
        XCTAssertEqual(404, response?.rawResponse?.statusCode)
        XCTAssertNotNil(response?.error)
    }
    
    //======================================================================
    // MARK: Ignore Content-Type
    //======================================================================
    
    func testIgnoreContentType() {
        let request = HTTPConnection(url: "https://jsoup.org/rez/osi_logo.png")?.ignoreContentType(true)
        let response = request?.request()
        
        XCTAssertFalse(response!.data!.isEmpty)
        XCTAssertEqual(200, response?.rawResponse?.statusCode)
        XCTAssertNil(response?.error)
    }
    
    func testDontIgnoreContentType() {
        let request = HTTPConnection(url: "https://jsoup.org/rez/osi_logo.png")
        let response = request?.request()
        
        XCTAssertNil(response!.contents)
        XCTAssertEqual(200, response?.rawResponse?.statusCode)
        XCTAssertNotNil(response?.error)
    }
}

*/
