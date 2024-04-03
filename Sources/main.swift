import AsyncHTTPClient
import NIOCore
import Foundation

struct Entrypoint {
    
    static func main() async throws {
        try await example1()
        try await example2()
        try await example3()
    }
    
    // MARK: -

    static func example1() async throws {

        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton
        )
        
        do {
            var request = HTTPClientRequest(
                url: "https://httpbin.org/post"
            )
            request.method = .POST
            request.headers.add(name: "User-Agent", value: "Swift AsyncHTTPClient")
            request.body = .bytes(ByteBuffer(string: "Some data"))
            
            let response = try await httpClient.execute(
                request,
                timeout: .seconds(5)
            )
            
            if response.status == .ok {
                let contentType = response.headers.first(
                    name: "content-type"
                )
                print("\(contentType ?? "")")

                let contentLength = response.headers.first(
                    name: "content-length"
                ).flatMap(Int.init)
                print("\(contentLength ?? -1)")

                let buffer = try await response.body.collect(upTo: 1024 * 1024)
                let rawResponseBody = buffer.getString(
                    at: 0,
                    length: buffer.readableBytes
                )
                print("\(rawResponseBody ?? "")")
            }
        }
        catch {
            print("\(error)")
        }

        try await httpClient.shutdown()
    }
    
    // MARK: -
    
    static func example2() async throws {

        struct Input: Codable {
            let id: Int
            let title: String
            let completed: Bool
        }
        
        struct Output: Codable {
            let json: Input
        }

        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton
        )
        do {
            var request = HTTPClientRequest(
                url: "https://httpbin.org/post"
            )
            request.method = .POST
            request.headers.add(name: "content-type", value: "application/json")
            
            let input = Input(
                id: 1,
                title: "foo",
                completed: false
            )
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(input)
            let buffer = ByteBuffer(bytes: data)
            request.body = .bytes(buffer)
            
            let response = try await httpClient.execute(
                request,
                timeout: .seconds(5)
            )
            
            if response.status == .ok {
                if let contentType = response.headers.first(
                    name: "content-type"
                ), contentType.contains("application/json") {
                    var buffer: ByteBuffer = .init()
                    for try await var chunk in response.body {
                        buffer.writeBuffer(&chunk)
                    }
                    
                    let decoder = JSONDecoder()
                    if let data = buffer.getData(at: 0, length: buffer.readableBytes) {
                        let output = try decoder.decode(Output.self, from: data)
                        print(output.json.title)
                    }
                }

            }
            else {
                print("Invalid status code: \(response.status)")
            }
        }
        catch {
            print("\(error)")
        }
        
        try await httpClient.shutdown()
    }
    
    // MARK: -
    
    static func example3() async throws {
        
        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton
        )

        do {
            let delegate = try FileDownloadDelegate(
                path: NSTemporaryDirectory() + "600x400.png",
                reportProgress: {
                    if let totalBytes = $0.totalBytes {
                        print("Total: \(totalBytes).")
                    }
                    print("Downloaded: \($0.receivedBytes).")
                }
            )
            
            let fileDownloadResponse = try await httpClient.execute(
                request: .init(
                    url: "https://placehold.co/600x400.png"
                ),
                delegate: delegate
            ).futureResult.get()
            
            print(fileDownloadResponse)
        }
        catch {
            print("\(error)")
        }
        
        try await httpClient.shutdown()
    }
}

try await Entrypoint.main()
