import Foundation

public class RegExp: NSObject {

    public var regexp = NSRegularExpression()

    public init(_ pattern: String, options:NSRegularExpressionOptions = .AllowCommentsAndWhitespace) throws {
        super.init()
        regexp = try NSRegularExpression(pattern: pattern, options: options)
    }

    /// simple boolean match test
    public func isMatching(string: String) -> Bool {
        let matches = regexp.numberOfMatchesInString(string, options: NSMatchingOptions(rawValue: 0), range: fullRangeForString(string))

        return matches > 0
    }

    /// returns the matching part of a String
    public func match(string: String) -> String? {
        let allStringRange = fullRangeForString(string)

        if let res = regexp.firstMatchInString(string, options: NSMatchingOptions(rawValue: 0), range: allStringRange) {
            let stringAsNS = string as NSString
            let firstMatch = stringAsNS.substringWithRange(res.range)
            return firstMatch
        } 
        
        return nil
    }

    /// returns all matches (including capture groups) as an array of String
    public func allMatches(string: String) -> [String] {
        var matches = [String]()
        let stringAsNS = string as NSString

        regexp.enumerateMatchesInString(string, options: NSMatchingOptions(rawValue: 0), range: fullRangeForString(string)) {
            (textCheckingResult:NSTextCheckingResult?, flags:NSMatchingFlags, stop:UnsafeMutablePointer<ObjCBool>) -> Void in

            if let textCheckingResult = textCheckingResult {
                for i in 0..<textCheckingResult.numberOfRanges {
                    let range = textCheckingResult.rangeAtIndex(i)

                    if range.location >= 0 && range.location <= string.characters.count && range.length >= 0 {
                        matches.append(stringAsNS.substringWithRange(range) as String)
                    }
                }
            }
        }

        return matches
    }

    private func fullRangeForString(string: String) -> NSRange {
        return NSRange(location:0, length:string.characters.count)
    }
}

/// Some operator overloading
infix operator =~ {}

public func =~ (left: String, right: RegExp) -> String? {
    return right.match(left)
}

public func =~ (left: RegExp, right: String) -> String? {
    return left.match(right)
}

