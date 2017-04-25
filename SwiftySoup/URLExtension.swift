//
//  URLExtension.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

extension URL {
    
    static func isValidURL(path: String) -> Bool {
        let validPrefixes = ["http://", "https://", "file:/"]
        let lowerPath = path.lowercased()
        return validPrefixes.first { lowerPath.hasPrefix($0) } != nil
    }
    
    static func resolve(basePath: String?, relURL: String) -> String? {
        
        guard basePath != nil, let baseURL = URL(string: basePath!) else {
            return URL(string: relURL)?.absoluteURL.absoluteString
        }
        
        guard let resolvedURL = resolve(baseURL: baseURL, relURL: relURL) else {
            return baseURL.absoluteURL.absoluteString
        }
        
        return resolvedURL.absoluteURL.absoluteString
    }
    
    static func resolve(baseURL: URL, relURL: String) -> URL? {
        var baseURL = baseURL
        let lastChar = baseURL.absoluteString.unicodeScalars.last
        if baseURL.pathComponents.isEmpty && lastChar != "/" && !baseURL.isFileURL {
           baseURL.appendPathComponent("/", isDirectory: false)
        }
        
        return URL(string: relURL, relativeTo: baseURL)
    }
    
}
