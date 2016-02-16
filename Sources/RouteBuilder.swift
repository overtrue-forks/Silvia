import Foundation

enum BadRouteSegmentError: ErrorType {
    case SamePlaceholder(String)
    case ContainsCaptuingGroup(String)
}

public enum RouteType {
    case Static
    case Variable
}

public class RouteBuilder {
    
    public typealias Handler = (request: Request, args: [String: String]) -> Any

    public class func build(method: String, route: [AnyObject], handler: Handler) -> (RouteType, Route) {
        if isStatic(route) {
            return (RouteType.Static, buildStaticRoute(method, route: route, handler: handler))
        }

        return (RouteType.Variable, buildVariableRoute(method, route: route, handler: handler))
    }

    public class func isStatic(route: [AnyObject]) -> Bool {
        return route.count == 1 && route.first is String
    }

    public class func buildStaticRoute(method: String, route: [AnyObject], handler: Handler) -> Route {
        return Route(method, pattern: route.first as! String, handler: handler)
    }

    public class func buildVariableRoute(method: String, route: [AnyObject], handler: Handler) -> Route {
        let (pattern, placeholders) = try! buildRegexForRoute(route)

        return Route(method, pattern: pattern, handler: handler, placeholders: placeholders)
    }

    private class func buildRegexForRoute(route: [AnyObject]) throws -> (String, [String]) {
        var regex = ""
        var placeholders: [String] = []

        for part in route {
            if part is String {
                regex += part as! String
                continue
            }
            
            if part is [String: String] {
                let dict = part as! [String: String]
                let placeholder = dict.keys.first!
                let regexPart = dict.values.first!

                if placeholders.contains(placeholder) {
                    throw BadRouteSegmentError.SamePlaceholder("Cannot use the same placeholder '\(placeholder)' twice.")
                }
                
                if regexHasCapturingGroups(regexPart) {
                    throw BadRouteSegmentError.ContainsCaptuingGroup("Regex '\(regexPart)' for parameter '\(placeholder)' contains a capturing group.")
                }

                placeholders.append(placeholder) 
                regex += "(\(regexPart))"
            }
        }
        
        return (regex, placeholders)
    }

    private class func regexHasCapturingGroups(regex: String) -> Bool {
        if !regex.characters.contains("(") {
            return false
        }

        return try! RegExp("(?:  \\(\\?\\( | \\[ [^\\]\\\\\\\\]* (?: \\\\\\\\ . [^\\]\\\\\\\\]* )* \\]  | \\\\\\\\ . ) | \\( (?! \\? (?! <(?![!=]) | P< | \\' ) | \\* )", options: .AllowCommentsAndWhitespace).isMatching(regex)
    }
}