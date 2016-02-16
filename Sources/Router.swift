import Foundation

enum RouteError: ErrorType {
    case BadOptionalSegment(String)
}

public class Router {

    public typealias Handler = (request: Request, args: [String: String]) -> Any
    
    private static let approxChunkSize = 10
    private static let variableRegExp: String = "\\{ \\s* ([a-zA-Z][a-zA-Z0-9_]*) \\s* (?: : \\s* ([^{}]*) )? \\}"

    private static var staticRoutes: [String: [String: Route]] = [:]
    private static var regexToRoutes: [String: [String: Route]] = [:]

    public class func get(pattern: String, handler: Handler) -> Void {
        map(["GET"], pattern: pattern, handler: handler)
    }

    public class func post(pattern: String, handler: Handler) {
        map(["POST"], pattern: pattern, handler: handler)
    }

    public class func put(pattern: String, handler: Handler) {
        map(["PUT"], pattern: pattern, handler: handler)
    }

    public class func patch(pattern: String, handler: Handler) {
        map(["PATCH"], pattern: pattern, handler: handler)
    }

    public class func delete(pattern: String, handler: Handler) {
        map(["DELETE"], pattern: pattern, handler: handler)
    }

    public class func map(methods: [String], pattern: String, handler: Handler) {
        addRoute(methods, pattern: pattern, handler: handler)
    }

    public class func addRoute(methods: [String], pattern: String, handler: Handler) {
        let routeDatas = try! parsePattern(pattern)     
        
        for method in methods {
            for data in routeDatas {
                let (type, route) = RouteBuilder.build(method, route: data as! [AnyObject], handler: handler)

                switch type {
                case .Static:
                    if staticRoutes[method]?.count <= 0 {
                        staticRoutes[method] = [:]
                    }
                    staticRoutes[method]![route.pattern] = route
                case .Variable:
                    if regexToRoutes[method]?.count <= 0 {
                        regexToRoutes[method] = [:]
                    }
                    regexToRoutes[method]![route.pattern] = route
                }
            }
        }
    }

    public class func routes() -> ([String: [String: Route]], [String: [String: [Int: Route]]]) {
        return (staticRoutes, generateVariableRoutes())
    }

    public class func dispatch(method: String, uri: String) -> Route? {
        let (statics, variables) = self.routes()
        Log("request:\(method, uri)")
        Log("variables:\(variables)")
        Log("statics:\(statics[method])")
        if let route = statics[method]?[uri] {
            return route
        } else if method == "HEAD", let route = statics["GET"]?[uri] {
            return route
        }

        if let items = variables[method] { 
            return dispatchVariableRoute(items, uri: uri) 
        } else if method == "HEAD", let items = variables["GET"] {
            return dispatchVariableRoute(items, uri: uri) 
        }

        return nil
    }

    private class func generateVariableRoutes() -> [String: [String: [Int: Route]]] {
        var variableRoutes: [String: [String: [Int: Route]]] = [:]
        Log("regexToRoutes:\(regexToRoutes)")
        for (method, maps) in regexToRoutes {
            let chunkSize = maps.count / max(1, maps.count / approxChunkSize)
            Log("maps:\(maps, "chunkSize", chunkSize)")
            var segment: [String: Route] = [:]
            var index = 1

            variableRoutes[method] = [:]

            for (regex, route) in maps {
                segment[regex] = route
                
                if index % chunkSize == 0 {
                    let (regex, routeMap) = processRouteMap(segment)
                    variableRoutes[method]?[regex] = routeMap
                    segment = [:]
                }

                index += 1
            }
        } 

        return variableRoutes
    }

    private class func processRouteMap(items: [String: Route]) -> (regex: String, routeMap: [Int: Route]) {
        var routeMap: [Int: Route] = [:]
        var regexes: [String] = []
        var groups: Int = 0

        Log("items:\(items)")

        for (regex, route) in items {
            groups = max(groups, route.placeholders.count)
            regexes.append("\(regex)\(String(byRepeatString: "()", count: groups - route.placeholders.count)!)")
            routeMap[groups + 1] = route
            groups += 1
        }

        let regex = "^(?:\(regexes.joinWithSeparator("|")))$"
        
        return (regex, routeMap)
    }

    private class func parsePattern(pattern: String) throws -> [AnyObject] {
        let routeWithoutClosingOptionals: String = pattern.rtrim("]")
        let numOptionals = pattern.length - routeWithoutClosingOptionals.length

        let segments = routeWithoutClosingOptionals.split("[")

        if numOptionals != segments.count - 1 {
            var error = "Number of opening '[' and closing ']' does not match"
            if let regex = try? RegExp("(?)\(variableRegExp) | \\]", options: .AllowCommentsAndWhitespace) where regex.isMatching(routeWithoutClosingOptionals) {
                error = "Optional segments can only occur at the end of a route"
            }

            throw RouteError.BadOptionalSegment(error)
        }

        var currentRoute = ""
        var routeDatas: [AnyObject] = []

        for (i, segment) in segments.enumerate() {
            if segment == "" && i != 0 {
                throw RouteError.BadOptionalSegment("Empty optional part")
            }

            currentRoute += segment
            routeDatas.append(parsePlaceholders(currentRoute))
        }

        return routeDatas
    }

    public class func dispatchVariableRoute(items: [String: [Int: Route]], uri: String) -> Route? {
        for (regex, maps) in items {

            Log("regex:\(regex)")
            Log("uri:\(uri)")

            if let matches = (try? RegExp(regex))?.allMatches(uri) {
                Log("matches:\(matches)")

                if matches.count <= 0 { continue }
                
                if let route = maps[matches.count] {
                    
                    Log("pattern:\(route.pattern)")
                    Log("placeholders:\(route.placeholders)")

                    for (i, name) in route.placeholders.enumerate() {
                        route.args[name] = matches[i + 1]

                        Log("route.args[\(name)] = \(matches[i+1])")
                    }
                    return route
                }
            }
        }

        return nil
    }

    private class func parsePlaceholders(path: String) -> [AnyObject] {
        guard let regex = try? RegExp(variableRegExp, options:.AllowCommentsAndWhitespace), segments: [String] = path.split(regex) where segments.count > 0 else {
            return [path]
        }

        var data:[AnyObject] = []

        for segment in segments {
            if !segment.characters.contains("{")  {
                data.append(segment)
                continue
            } 

            let trimedSegment = segment.trim("{}")

            if trimedSegment.characters.contains(":") {
                let parts = trimedSegment.split(separator: ":").filter({
                    return $0.trim().characters.count > 0
                })
                
                if parts.count == 2 {
                    data.append([parts.first!.trim(): parts.last!.trim()])
                }
            } else {
                data.append([trimedSegment: "[^/]+"])
            }
        }

        return data;
    }
}