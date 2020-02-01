//
//  URLSessionExtension.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 4/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import AsyncHTTPClient
import NIO

extension URLSession {
    
    public func requestSynchronousData(request: URLRequest) -> (data: Data?, rawResponse: HTTPURLResponse?, error: Error?) {
        var data: Data? = nil
        var error: Error? = nil
        var response: HTTPURLResponse? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let task = dataTask(with: request, completionHandler: {
            taskData, taskResponse, taskError in
            error = taskError
            response = taskResponse as? HTTPURLResponse
            data = taskData
            semaphore.signal()
        })
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return (data, response, error)
    }
    
}

extension HTTPClient {
    
    public func requestSynchronousData(request: HTTPClient.Request, in client: HTTPClient, timeout: TimeAmount? = nil) -> (data: Data?, response: HTTPClient.Response?, error: Error?) {
        var data: Data? = nil
        var responseError: Error? = nil
        var resultResponse: HTTPClient.Response? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let deadline: NIODeadline? = timeout != nil ? .now() + timeout! : nil
        client.execute(request: request, deadline: deadline).whenComplete { result in
            switch result {
            case .success(let response):
                resultResponse = response
                var body = response.body
                let length = body?.readableBytes ?? 0
                data = body?.readData(length: length)
            case .failure(let error):
                responseError = error
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return (data, resultResponse, responseError)
    }
    
}
