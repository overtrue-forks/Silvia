import Foundation

extension String {
    var length: Int {
        return (self as NSString).length
    }

    var UInt8Array: [UInt8] {
        return [UInt8](self.utf8)
    }

    init(ascii: Int) {
        self.init(UnicodeScalar(ascii))
    }

    init?(byRepeatString str: String, count: Int) {
        var newString = ""

        for _ in 0 ..< count {
            newString += str
        }

        self.init(newString)
    }

    func split(separator: Character) -> [String] {
        return self.characters.split { $0 == separator }.map(String.init)
    }
    
    func split(maxSplit: Int = Int.max, separator: Character) -> [String] {
        return self.characters.split(maxSplit) { $0 == separator }.map(String.init)
    }

    func split(regex: RegExp) -> [String] {
        var segments: [String] = []
        let stringAsNS = self as NSString
        let results = regex.regexp.matchesInString(self, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.characters.count))
        var offset = 0
        for result in results {
            if result.range.location > offset {
                segments.append(stringAsNS.substringWithRange(NSRange(location: offset, length: result.range.location - offset)))

            }
            segments.append(stringAsNS.substringWithRange(NSRange(location: result.range.location, length: result.range.length)))
            
            offset = result.range.location + result.range.length
        }

        if offset < self.characters.count {
            segments.append(stringAsNS.substringFromIndex(offset))
        }

        return segments
    }
    
    func replace(old: Character, new: Character) -> String {
        var buffer = [Character]()
        self.characters.forEach { buffer.append($0 == old ? new : $0) }
        return String(buffer)
    }
    
    func unquote() -> String {
        var scalars = self.unicodeScalars;
        if scalars.first == "\"" && scalars.last == "\"" && scalars.count >= 2 {
            scalars.removeFirst();
            scalars.removeLast();
            return String(scalars)
        }
        return self
    }
    
    func trim(chars: String = "") -> String {
        let sets = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet()
        
        sets.addCharactersInString(chars)
        
        return self.stringByTrimmingCharactersInSet(sets)
    }

    func rtrim(charsets: String = "") -> String {
        var sets = charsets
        var chars = self.characters

        sets.appendContentsOf("\u{020}\u{009}\u{00A}\u{00D}\u{000}\u{00B}")
    
        while let last = chars.last where sets.characters.contains(last) {
            chars.removeLast()
        }
        
        return String(chars)
    }
    
    func ltrim(charsets: String = "") -> String {
        var sets = charsets
        var chars = self.characters

        sets.appendContentsOf("\u{020}\u{009}\u{00A}\u{00D}\u{000}\u{00B}")
        
        while let first = chars.first where charsets.characters.contains(first) {
            chars.removeFirst()
        }
        
        return String(chars)
    }
    
    static func fromUInt8(array: [UInt8]) -> String {
        #if os(Linux)
            return String(data: NSData(bytes: array, length: array.count), encoding: NSUTF8StringEncoding) ?? ""
        #else
            if let s = String(data: NSData(bytes: array, length: array.count), encoding: NSUTF8StringEncoding) {
                return s
            }
            return ""
        #endif
    }
    
    func removePercentEncoding() -> String {
        var scalars = self.unicodeScalars
        var output = ""
        var bytesBuffer = [UInt8]()
        while let scalar = scalars.popFirst() {
            if scalar == "%" {
                let first = scalars.popFirst()
                let secon = scalars.popFirst()
                if let first = unicodeScalarToUInt32Hex(first), secon = unicodeScalarToUInt32Hex(secon) {
                    bytesBuffer.append(first*16+secon)
                } else {
                    if !bytesBuffer.isEmpty {
                        output.appendContentsOf(String.fromUInt8(bytesBuffer))
                        bytesBuffer.removeAll()
                    }
                    if let first = first { output.append(Character(first)) }
                    if let secon = secon { output.append(Character(secon)) }
                }
            } else {
                if !bytesBuffer.isEmpty {
                    output.appendContentsOf(String.fromUInt8(bytesBuffer))
                    bytesBuffer.removeAll()
                }
                output.append(Character(scalar))
            }
        }
        if !bytesBuffer.isEmpty {
            output.appendContentsOf(String.fromUInt8(bytesBuffer))
            bytesBuffer.removeAll()
        }
        return output
    }
    
    private func unicodeScalarToUInt32Whitespace(x: UnicodeScalar?) -> UInt8? {
        if let x = x {
            if x.value >= 9 && x.value <= 13 {
                return UInt8(x.value)
            }
            if x.value == 32 {
                return UInt8(x.value)
            }
        }
        return nil
    }
    
    private func unicodeScalarToUInt32Hex(x: UnicodeScalar?) -> UInt8? {
        if let x = x {
            if x.value >= 48 && x.value <= 57 {
                return UInt8(x.value) - 48
            }
            if x.value >= 97 && x.value <= 102 {
                return UInt8(x.value) - 87
            }
            if x.value >= 65 && x.value <= 70 {
                return UInt8(x.value) - 55
            }
        }
        return nil
    }
}