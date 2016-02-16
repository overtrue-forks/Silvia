//
// Based on HttpServerIO from Swifter (https://github.com/glock45/swifter) by Damian Kołakowski.
//

import Foundation

#if os(Linux)
    import Glibc
#endif

public class Server {
    
    ///A socket open to the port the server is listening on. Usually 80.
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)

    ///A set of connected client sockets.
    private var clientSockets: Set<Socket> = []

    ///The shared lock for notifying new connections.
    private let clientSocketsLock = NSLock()

    private let handler: (Socket) -> ()

    init(handler: (Socket) -> ()) {
        self.handler = handler
    }
    
    /**
        Starts the server on a given port.
        - parameter listenPort: The port to listen on.
    */
    func start(listenPort: Int) throws {
        //stop the server if it's running
        self.stop()

        //open a socket, might fail
        self.listenSocket = try Socket.tcpSocketForListen(UInt16(listenPort))

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {

            //creates the infinite loop that will wait for client connections
            while let socket = try? self.listenSocket.acceptClientSocket() {

                //wait for lock to notify a new connection
                self.lock(self.clientSocketsLock) {
                    //keep track of open sockets
                    self.clientSockets.insert(socket)
                }

                //handle connection in background thread
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                    self.handler(socket)

                    //set lock to wait for another connection
                    self.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                })
            }

            //stop the server in case something didn't work
            self.stop()
        }
    }

    /**
        Starts an infinite loop to keep the server alive while it
        waits for inbound connections.
    */
    func loop() {
        #if os(Linux)
            while true {
                sleep(1)
            }
        #else
            NSRunLoop.mainRunLoop().run()
        #endif
    }
    
    /**
        Stops the server
    */
    func stop() {
        //free the port
        self.listenSocket.release()

        //shutdown all client sockets
        self.lock(self.clientSocketsLock) {
            for socket in self.clientSockets {
                socket.shutdwn()
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }
    
    /**
        Locking mechanism for holding thread until a 
        new socket connection is ready.
        
        - parameter handle: NSLock
        - parameter closure: Code that will run when the lock has been altered.
    */
    private func lock(handle: NSLock, closure: () -> ()) {
        handle.lock()
        closure()
        handle.unlock();
    }
    
    /**
        Writes the response to the client socket.
    */
    public func respond(socket: Socket, response: Response, keepAlive: Bool) throws -> Bool {
        try socket.writeUTF8("HTTP/1.1 \(response.status.code) \(response.reasonPhrase)\r\n")

        var headers = response.getHeaders()

        if response.body.length >= 0 {
            headers["Content-Length"] = "\(response.data.count)"
        }
        
        if keepAlive && response.data.count != -1 {
            headers["Connection"] = "keep-alive"
        }
        
        for (name, value) in headers {
            try socket.writeUTF8("\(name): \(value)\r\n")
        }
        
        try socket.writeUTF8("\r\n")

        try socket.writeUInt8(response.data)
        
        return keepAlive && response.data.count != -1;  
    }
}