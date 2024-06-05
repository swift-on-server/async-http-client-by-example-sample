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
        
        var request = HTTPClientRequest(url: "https://httpbin.org/post")
        request.method = .POST
        request.headers.add(name: "User-Agent", value: "Swift AsyncHTTPClient")
        request.body = .bytes(ByteBuffer(string: "Some data"))
        
        let response = try await HTTPClient.shared.execute(
            request,
            timeout: .seconds(5)
        )

        guard response.status == .ok else {
            print("Invalid status code: \(response.status)")
            return
        }
        let contentType = response.headers.first(name: "content-type")
        print("\(contentType ?? "")")

        let contentLength = response.headers.first(
            name: "content-length"
        ).flatMap(Int.init)

        print("\(contentLength ?? -1)")

        let buffer = try await response.body.collect(upTo: 1024 * 1024)
        let rawResponseBody = String(buffer: buffer)
        print("\(rawResponseBody)")
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

        var request = HTTPClientRequest(url: "https://httpbin.org/post")
        request.method = .POST
        request.headers.add(name: "content-type", value: "application/json")
        
        let input = Input(
            id: 1,
            title: "foo",
            completed: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(input)
        request.body = .bytes(.init(bytes: data))
        
        let response = try await HTTPClient.shared.execute(
            request,
            timeout: .seconds(5)
        )
        
        guard response.status == .ok else {
            print("Invalid status code: \(response.status)")
            return
        }
        guard
            let contentType = response.headers.first(name: "content-type"),
            contentType.contains("application/json")
        else {
            print("Invalid content type.")
            return
        }

        var buffer: ByteBuffer = .init()
        for try await var chunk in response.body {
            buffer.writeBuffer(&chunk)
        }
        
        let decoder = JSONDecoder()
        let output = try decoder.decode(Output.self, from: buffer)
        print(output.json.title)
    }
    
    // MARK: -
    
    static func example3() async throws {
        
        let delegate = try FileDownloadDelegate(
            path: NSTemporaryDirectory() + "600x400.png",
            reportProgress: {
                if let totalBytes = $0.totalBytes {
                    print("Total: \(totalBytes).")
                }
                print("Downloaded: \($0.receivedBytes).")
            }
        )

        let fileDownloadResponse = try await HTTPClient.shared.execute(
            request: .init(url: "https://placehold.co/600x400.png"),
            delegate: delegate
        ).futureResult.get()
        
        print(fileDownloadResponse)
    }
}

do {
    try await Entrypoint.main()
}
catch {
    fatalError("\(error)")
}
