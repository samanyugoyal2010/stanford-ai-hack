import Foundation

/// Uploads files to EverOS-managed object storage via pre-signed S3 POST.
actor EverOSObjectUploader {
    private let client: EverOSClient
    private let session: URLSession

    init(client: EverOSClient, session: URLSession = .shared) {
        self.client = client
        self.session = session
    }

    /// Signs and uploads JPEG/PNG bytes; returns the `objectKey` for message content.
    func uploadImage(
        data: Data,
        fileName: String,
        fileType: String = "image",
        ext: String
    ) async throws -> String {
        let fileId = UUID().uuidString
        let signed = try await client.signObjects([
            EverOSSignObject(fileId: fileId, fileName: fileName, fileType: fileType)
        ])
        guard let item = signed.first,
              let objectKey = item.objectKey,
              let info = item.objectSignedInfo,
              let urlString = info.url,
              let url = URL(string: urlString),
              let fields = info.fields else {
            throw EverOSClientError.emptySignResponse
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: image/\(ext)\r\n\r\n")
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 120

        let (_, response) = try await session.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        // S3 pre-signed POST typically returns 204.
        guard (200...299).contains(code) else {
            throw EverOSClientError.uploadFailed(code)
        }
        return objectKey
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
