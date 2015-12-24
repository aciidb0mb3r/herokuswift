print("HelloWssssorld from package: herokuswift")

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public class HTTP {
  public var   serverSocket : Int32 = 0
  public var  serverAddress : sockaddr_in?
  var     bufferSize : Int = 1024

  func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
  }

  public func echo(socket: Int32, _ output: String) {
   output.withCString { (bytes) in
      #if os(Linux)
      let flags = Int32(MSG_NOSIGNAL)
      #else
      let flags = Int32(0)
      #endif
      send(socket, bytes, Int(strlen(bytes)), flags)
   }
  }

  public init(port: UInt16) {
    #if os(Linux)
    serverSocket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
    #else
    serverSocket = socket(AF_INET, Int32(SOCK_STREAM), 0)
    #endif
    if (serverSocket > 0) {
      print("Socket init: OK")
    }

    #if os(Linux)
    serverAddress = sockaddr_in(
      sin_family: sa_family_t(AF_INET),
      sin_port: port.htons(),
      sin_addr: in_addr(s_addr: in_addr_t(0)),
      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
    )
    #else
    serverAddress = sockaddr_in(
      sin_len: __uint8_t(sizeof(sockaddr_in)),
      sin_family: sa_family_t(AF_INET),
      sin_port: port.htons(),
      sin_addr: in_addr(s_addr: in_addr_t(0)),
      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
    )
    #endif

    setsockopt(serverSocket, SOL_SOCKET, SO_RCVBUF, &bufferSize, socklen_t(sizeof(Int)))

    #if !os(Linux)
    var noSigPipe : Int32 = 1
    setsockopt(serverSocket, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(sizeofValue(noSigPipe)))
    #endif

    let serverBind = bind(serverSocket, sockaddr_cast(&serverAddress), socklen_t(UInt8(sizeof(sockaddr_in))))
    if (serverBind >= 0) {
      print("Server started at port \(port)")
    }
  }
}

extension CUnsignedShort {
  func htons() -> CUnsignedShort { return (self << 8) + (self >> 8); }
}

let args = Array(Process.arguments.dropFirst())

print("starting app")
public struct StderrOutputStream: OutputStreamType {
    public static let stream = StderrOutputStream()
    public func write(string: String) {fputs(string, stderr)}
}
public var errStream = StderrOutputStream.stream

print("This prints to stderr", errStream)

let portInt = UInt16(args[0])!
print("trying to run on port \(portInt)")

let server = HTTP(port: portInt)

while (true) {
  if (listen(server.serverSocket, 10) < 0) {
    exit(1)
  }

  let clientSocket = accept(server.serverSocket, nil, nil)

  let msg = "Hello World"
  let contentLength = msg.utf8.count

  server.echo(clientSocket, "HTTP/1.1 200 OK\n")
  server.echo(clientSocket, "Server: Swift Web Server\n")
  server.echo(clientSocket, "Content-length: \(contentLength)\n")
  server.echo(clientSocket, "Content-type: text-plain\n")
  server.echo(clientSocket, "Connection: close\n")
  server.echo(clientSocket, "\r\n")

  server.echo(clientSocket, msg)

  print("Response sent: '\(msg)' - Length: \(contentLength)")

  shutdown(clientSocket, Int32(SHUT_RDWR))
  close(clientSocket)
}
