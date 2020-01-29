//
//  StringExtension.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

extension String {
    
    static let padding = ["", " ", " "*2, " "*3, " "*4, " "*5, " "*6, " "*7, " "*8, " "*9]
    
    init(_ scalars: [UnicodeScalar]) {
        self.init(UnicodeScalarView(scalars))
    }

    @discardableResult
    mutating func append(_ scalar: UnicodeScalar) -> String {
        self.unicodeScalars.append(scalar)
        return self
    }
    
    static func toHexString(int: Int) -> String {
        return String(format:"%2x", int)
    }
    
    static func padding(amount: Int) -> String {
        guard amount > 0 else { return String.padding[0] }
        
        // Cache to improve performance
        if amount < String.padding.count {
            return String.padding[amount]
        }
        
        return " "*amount
    }
    
    static func *(lhs: String, rhs: Int) -> String {
        var result = lhs
        (0..<rhs - 1).forEach { _ in result += lhs }
        return result
    }
    
    static func *(lhs: Int, rhs: String) -> String {
        var result = rhs
        (0..<lhs - 1).forEach { _ in result += rhs }
        return result
    }
    
    func normalizedWhitespace(stripLeading: Bool = false) -> String {
        let accum = StringBuilder()
        
        var reachedNonWhite = false
        var wasWhitespace = false
        for i in (0..<self.unicodeScalars.count) {
            if self.unicodeScalars[i].isWhitespace {
                if wasWhitespace || (stripLeading && !reachedNonWhite) {
                    continue
                }
                accum += " "
                wasWhitespace = true
            } else {
                accum.append(self.unicodeScalars[i])
                reachedNonWhite = true
                wasWhitespace = false
            }
        }
        
        return accum.stringValue
    }
    
    subscript(range: NSRange) -> String {
        let correctedRange = self.range(fromNSRange: range)
        return String(self[correctedRange])
    }
    
    subscript(range: Range<Int>) -> String {
        let start = range.lowerBound
        let end = range.upperBound
        
        let startIndex = self.index(self.startIndex, offsetBy: start)
        let endIndex = self.index(self.startIndex, offsetBy: end)
        
        return String(self[Range<String.Index>(uncheckedBounds: (startIndex, endIndex))])
    }
    
    func range(fromNSRange range: NSRange) -> Range<String.Index> {
        return Range(range, in: self)!
    }
    
    func matches(_ regex: NSRegularExpression) -> Bool {
        return regex.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: self.count)) > 0
    }
    
    func replaceFirst(regex regexStr: String, by replacement: String) -> String {
        var result = self
        guard let regex = try? NSRegularExpression(pattern: regexStr, options: []) else { return result }
        if let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) {
            result.replaceSubrange(self.range(fromNSRange: match.range), with: replacement)
        }
        return result
    }
    
    func replaceAll(regex regexStr: String, by replacement: String) -> String {
        var result = self
        guard let regex = try? NSRegularExpression(pattern: regexStr, options: []) else { return result }
        
        while let match = regex.firstMatch(in: result, options: [], range: NSRange(location: 0, length: result.count)) {
            result.replaceSubrange(self.range(fromNSRange: match.range), with: replacement)
        }
        
        return result
    }
    
    func index(of string: String, since startIndex: Int = 0) -> Int? {
        var correct = false
        
        for i in (startIndex..<unicodeScalars.count) {
            let provisionalIndex = i
            correct = true
            for j in (0..<string.unicodeScalars.count) {
                correct = correct && (unicodeScalars[i + j] == string.unicodeScalars[j])
                if (!correct) {
                    break
                }
            }
            if correct { return provisionalIndex }
        }
        return nil
    }
}

extension Character {
    
    static let MIN_SUPPLEMENTARY_CODE_POINT: UInt32 = 0x010000
    static let WHITESPACE_CHARACTERS : [Character] = [" ", "\t", "\n", "\u{000C}", "\r"]
    
    var isWhitespace: Bool {
        return Character.WHITESPACE_CHARACTERS.contains(self)
    }
    
    var isLetter: Bool {
        return CharacterSet.letters.contains(self.unicodeScalar)
    }
    
    var isLetterOrDigit: Bool {
        return CharacterSet.alphanumerics.contains(self.unicodeScalar)
    }
    
    static func ==(lhs: Character, rhs: String) -> Bool {
        return lhs == rhs.first
    }
    
    static func ==(lhs: String, rhs: Character) -> Bool {
        return lhs.first == rhs
    }
    
    static func +(lhs: String, rhs: Character) -> String {
        return lhs + String(rhs)
    }
    
    static func +(lhs: Character, rhs: String) -> String {
        return String(lhs) + rhs
    }
    
    var unicodeScalar: UnicodeScalar {
        return String.init(describing: self).unicodeScalars[0]
    }
    
    var string: String {
        return String(self)
    }
    
}

extension UnicodeScalar {
    
    static let WHITESPACE_CHARACTERS : [UnicodeScalar] = [" ", "\t", "\n", "\u{000C}", "\r"]
    static let MIN_SUPPLEMENTARY_CODE_POINT: UInt32 = 0x010000
    
    var isWhitespace: Bool {
        return UnicodeScalar.WHITESPACE_CHARACTERS.contains(self)
    }

    var isLetter: Bool {
        return CharacterSet.letters.contains(self)
    }

    var isLetterOrDigit: Bool {
        return CharacterSet.alphanumerics.contains(self)
    }
    
    var isLowercase: Bool {
        return value > 96 && value < 123
    }
    
    var isUppercase: Bool {
        return value > 64 && value < 91
    }
    
    static func ==(lhs: UnicodeScalar, rhs: String) -> Bool {
        return lhs == rhs.unicodeScalars.first
    }
    
    static func ==(lhs: String, rhs: UnicodeScalar) -> Bool {
        return lhs.unicodeScalars.first == rhs
    }
    
    static func +(lhs: String, rhs: UnicodeScalar) -> String {
        var sum = lhs
        sum.append(rhs)
        return sum
    }
    
    static func +(lhs: UnicodeScalar, rhs: String) -> String {
        var sum = rhs
        sum.append(lhs)
        return sum
    }
    
    var character: Character {
        return Character(self)
    }
    
    var string: String {
        return String(self)
    }
    
    static let Space: UnicodeScalar = " "
    static let Ampersand: UnicodeScalar = "&"
    static let LessThan: UnicodeScalar = "<"
    static let GreaterThan: UnicodeScalar = ">"
    static let BackslashF: UnicodeScalar = "\u{000C}"
    static let BackslashR: UnicodeScalar = "\r"
    static let Tabulation: UnicodeScalar = "\t"
    static let Slash: UnicodeScalar = "/"
    static let FormFeed: UnicodeScalar = "\u{000B}"// Form Feed
    static let VerticalTab: UnicodeScalar = "\u{000C}"// vertical tab
    static let NewLine: UnicodeScalar = "\n"
}

extension String.UnicodeScalarView {
    public static func ==(lhs: String.UnicodeScalarView, rhs: String.UnicodeScalarView) -> Bool {
        return String(lhs) == String(rhs)
    }

    public static func !=(lhs: String.UnicodeScalarView, rhs: String.UnicodeScalarView) -> Bool {
        return String(lhs) != String(rhs)
    }
}

extension String.Encoding {
    func canEncode(_ string: String) -> Bool {
        return string.data(using: self, allowLossyConversion: true) != nil
    }
    
    public var displayName: String {
        switch self {
        case String.Encoding.ascii: return "US-ASCII"
        case String.Encoding.nextstep: return "nextstep"
        case String.Encoding.japaneseEUC: return "EUC-JP"
        case String.Encoding.utf8: return "UTF-8"
        case String.Encoding.isoLatin1: return "csISOLatin1"
        case String.Encoding.symbol: return "MacSymbol"
        case String.Encoding.nonLossyASCII: return "nonLossyASCII"
        case String.Encoding.shiftJIS: return "shiftJIS"
        case String.Encoding.isoLatin2: return "csISOLatin2"
        case String.Encoding.unicode: return "unicode"
        case String.Encoding.windowsCP1251: return "windows-1251"
        case String.Encoding.windowsCP1252: return "windows-1252"
        case String.Encoding.windowsCP1253: return "windows-1253"
        case String.Encoding.windowsCP1254: return "windows-1254"
        case String.Encoding.windowsCP1250: return "windows-1250"
        case String.Encoding.iso2022JP: return "iso2022jp"
        case String.Encoding.macOSRoman: return "macOSRoman"
        case String.Encoding.utf16: return "UTF-16"
        case String.Encoding.utf16BigEndian: return "UTF-16BE"
        case String.Encoding.utf16LittleEndian: return "UTF-16LE"
        case String.Encoding.utf32: return "UTF-32"
        case String.Encoding.utf32BigEndian: return "UTF-32BE"
        case String.Encoding.utf32LittleEndian: return "UTF-32LE"
        default:
            return self.description
        }
    }
    
    static func from(literal: String) -> String.Encoding? {
        switch literal.lowercased() {
        case "utf-8":
            return .utf8
        case "us-ascii":
            return .ascii
        case "euc-jp":
            return .japaneseEUC
        case "csisolatin1", "iso-8859-1":
            return .isoLatin1
        case "csisolatin2", "iso-8859-2":
            return .isoLatin2
        case "iso2022jp":
            return .iso2022JP
        case "utf-16":
            return .utf16
        case "utf-32":
            return .utf32
        default:
            return nil
        }
    }
}
