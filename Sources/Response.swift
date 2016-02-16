import Foundation

/**
    Responses that redirect to a supplied URL.
 */
public class Redirect: Response {

    ///The URL string for redirect
    var location: String

    /**
        Redirect headers return normal `Response` headers
        while adding `Location`.

        @return [String: String] Dictionary of headers
     */
    override func getHeaders() -> [String: String] {
        var headers = super.getHeaders()
        headers["Location"] = self.location
        return headers
    }

    /**
        Creates a `Response` object that redirects
        to a given URL string.

        - parameter location: The URL string for redirect
        
        - returns Response
     */
    public init(to location: String) {
        self.location = location
        super.init(status: .MovedPermanently, data: [], contentType: .None)
    }
}

/**
    Responses are objects responsible for returning
    data to the HTTP request such as the body, status 
    code and headers.
 */
public class Response {

    public enum SerializationError: ErrorType {
        case InvalidObject
        case NotSupported
    }

    let status: Status
    let data: [UInt8]
    var body: String {
        return String(self.data.map({ Character(UnicodeScalar($0)) }))
    }
    let contentType: ContentType
    var headers = ["Server" : "Silvia \(Application.VERSION)"]

    public var cookies: [String: String] = [:]

    enum ContentType {
        case Plain, Html, Json, None
    }

    public enum Status {
        case OK, Created, Accepted
        case MovedPermanently
        case BadRequest, Unauthorized, Forbidden, NotFound
        case Error
        case Unknown
        case Custom(Int)

        public var code: Int {
            switch self {
                case .OK: return 200
                case .Created: return 201
                case .Accepted: return 202

                case .MovedPermanently: return 301

                case .BadRequest: return 400
                case .Unauthorized: return 401
                case .Forbidden: return 403
                case .NotFound: return 404

                case .Error: return 500 

                case .Unknown: return 0
                case .Custom(let code):
                    return code
            }
        }
    }

    var reasonPhrase: String {
        switch self.status {
        case .OK:
            return "OK"
        case .Created: 
            return "Created"
        case .Accepted: 
            return "Accepted"

        case .MovedPermanently: 
            return "Moved Permanently"

        case .BadRequest: 
            return "Bad Request"
        case .Unauthorized: 
            return "Unauthorized"
        case .Forbidden: 
            return "Forbidden"
        case .NotFound: 
            return "Not Found"

        case .Error: 
            return "Internal Server Error"
            
        case .Unknown:
            return "Unknown"
        case .Custom:
            return "Custom"    
        }
    }

    func getHeaders() -> [String: String] {
        if self.cookies.count > 0 {
            var cookieString = ""
            for (key, value) in self.cookies {
                if cookieString != "" {
                    cookieString += ";"
                }

                cookieString += "\(key)=\(value)"
            }
            headers["Set-Cookie"] = cookieString
        }

        switch self.contentType {
        case .Json: 
            headers["Content-Type"] = "application/json"
        case .Plain: 
            headers["Content-Type"] = "text/plain"
        default:
            headers["Content-Type"] = "text/html"
            break
        }

        return headers
    }

    init(status: Status, data: [UInt8], contentType: ContentType, headers: [String: String] = [:]) {
        self.status = status
        self.data = data
        self.contentType = contentType

        for (name, value) in headers {
            self.headers[name] = value
        }
    }

    public convenience init(error: String) {
        let text = "{\"error\": true,\"message\":\"\(error)\"}"

        self.init(status: .Error, data: text.UInt8Array, contentType: .Json)
    }

    public convenience init(status: Status, html: String, headers: [String: String] = [:]) {
        self.init(status: status, data: html.UInt8Array, contentType: .Html, headers: headers)
    }

    public convenience init(status: Status, text: String, headers: [String: String] = [:]) {
        self.init(status: status, data: text.UInt8Array, contentType: .Plain, headers: headers)
    }

    // public convenience init(status: Status, json: Any) throws {
    //     var data: [UInt8] = []

    //     if let jsonObject = json as? AnyObject {
    //         guard NSJSONSerialization.isValidJSONObject(jsonObject) else {
    //             throw SerializationError.InvalidObject
    //         }

    //         let json = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions.PrettyPrinted)
    //         data = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(json.bytes), count: json.length))
    //     } else {
    //         //fall back to manual serializer
    //         // let string = JSONSerializer.serialize(json)
    //         // data = [UInt8]("not found.")
    //     }
       

    //     self.init(status: status, body: body, contentType: .Json)
    // }
}


func ==(left: Response, right: Response) -> Bool {
    return left.status.code == right.status.code
}

