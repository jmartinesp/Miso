import Foundation

extension Optional where Wrapped: Sequence {
    
    var isNilOrEmpty: Bool {
        return self == nil || self?.underestimatedCount == 0
    }
    
}

extension Collection {
    
    func binarySearch(test: (Self.Element) -> Bool) -> Self.Index? {
        var searchRange = startIndex..<endIndex
        
        var count = distance(from: startIndex, to: endIndex)
        while count > 0 {
            let testIndex = index(searchRange.lowerBound, offsetBy: (count-1)/2)
            let passesTest = test(self[testIndex])
            
            if count == 1 {
                return passesTest ? searchRange.lowerBound : nil
            }
            
            if passesTest {
                searchRange = searchRange.lowerBound..<index(after: testIndex)
            } else {
                searchRange = index(after: testIndex)..<searchRange.upperBound
            }
            
            count = distance(from: searchRange.lowerBound, to: searchRange.upperBound)
        }
        
        return nil
    }
}

extension Collection where Element: Comparable {
    
    func binarySearch(value: Element) -> Self.Index? {
        var start = startIndex
        var end = endIndex
        
        var count = distance(from: start, to: end)
        while count > 0 {
            let testIndex = index(start, offsetBy: count/2)
            
            if value == self[testIndex] {
                return testIndex
            } else if value < self[testIndex] {
                end = testIndex
            } else {
                start = index(after: testIndex)
            }
            
            count = distance(from: start, to: end)
        }
        
        return nil
    }
    
}
