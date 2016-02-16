public class Route {
    
    public typealias Handler = (request: Request, args: [String: String]) -> Any

    public let method: String
    public let pattern: String
    public let handler: Handler
    public let placeholders: [String]
    public var args: [String: String] = [:]

    public init(_ method: String, pattern: String, handler: Handler, placeholders: [String] = []) {
        self.method = method
        self.pattern = pattern
        self.handler = handler
        self.placeholders = placeholders
    }

    public func matches(uri: String) -> Bool {
        return try! RegExp(pattern).isMatching(uri)
    }

    public func match(uri: String) -> [String] {
        return try! RegExp(pattern).allMatches(uri)
    }
}