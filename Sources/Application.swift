import Foundation

public class Application {
    private lazy var server: Server = {
        return Server(handler: self.handle)
    }()

    public static let VERSION = "0.0.1"

    public init() { }

    public func run(port inPort: Int = 80) {
        var port = inPort

        if Process.arguments.count >= 2 {
            let secondArg = Process.arguments[1]
            if secondArg.hasPrefix("--port=") {
                let portString = secondArg.split("=")[1]
                if let portInt = Int(portString) {
                    port = portInt
                }
            }
        }

        do {
            try server.start(port)

            print("Server has started on port \(port)")

            server.loop()
        } catch {
            print("Server start error: \(error)")
        }
    }

    public func handle(socket: Socket) {
        //try to get the ip address of the incoming request (like 127.0.0.1)
        let address = try? socket.peername()

        //create a request parser
        let parser = Parser()

        while let request = try? parser.readHttpRequest(socket) {
            //add parameters to request
            request.address = address
            request.parameters = [:]
            
            //dispatch the server to handle the request
            let response = self.dispatch(request)
            print("response:", response)
            var keepConnection = parser.supportsKeepAlive(request.headers)
            do {
                keepConnection = try server.respond(socket, response: response, keepAlive: keepConnection)
            } catch {
                print("Failed to send response: \(error)")
                break
            }
            if !keepConnection { break }
        }

        //release the connection
        socket.release()
    }

    func dispatch(request: Request) -> Response {
        if let route = Router.dispatch(request.method.rawValue, uri: request.path) {
            let result = route.handler(request: request, args: route.args)

            if let response = result as? Response {
                return response
            } else if let html = result as? String {
                return Response(status: .OK, text: html)
            }
        }

        //check in file system
        let filePath = "Public" + request.path
        let fileManager = NSFileManager.defaultManager()
        var isDir: ObjCBool = false
        if fileManager.fileExistsAtPath(filePath, isDirectory: &isDir) {
            if isDir {
                do {
                    let files = try fileManager.contentsOfDirectoryAtPath(filePath)
                    var response = "<style> body { font-family: Helvetica, STHeiti, sans-serif; font-size: 75%;}</style>"
                    response += "<h3>\(filePath)</h3></br><ul>"
                    response += files.map({ "<li><a href=\"\(request.path.ltrim("/"))/\($0.ltrim("/"))\">\($0)</a></li>"}).joinWithSeparator("")
                    response += "</ul>"

                    return Response(status: .OK, html: response)
                } catch {
                    //continue to not found
                }
            } else {
                if let fileBody = NSData(contentsOfFile: filePath) {
                    var array = [UInt8](count: fileBody.length, repeatedValue: 0)
                    fileBody.getBytes(&array, length: fileBody.length)

                    return Response(status: .OK, data: array, contentType: .Plain)
                }
            }
        }

        return Response(status: .NotFound, text: "Page not found.") 
    }
}