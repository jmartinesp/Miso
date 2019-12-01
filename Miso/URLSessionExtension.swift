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
