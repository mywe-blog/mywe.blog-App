import Foundation

public struct ImageUploadContent: Codable {
    public struct Content: Codable {
        let downloadUrl: String
    }

    public struct CommitResponse: Codable {
        let content: Content
    }

    let commitResponse: CommitResponse?
    let filename: String
}

public struct PostContent: Codable {
    let location: ContentLocation
    let date: Date
    let title: String?
    let postfolder: String
    let content: [ContentPart]
}

public enum ContentPart: Codable, Identifiable {
    public var id: UUID {
        return UUID()
    }

    case header(String)
    case paragraph(String)
    case image(filename: String)
    case link(title: String, urlString: String)

    enum CodingError: Error {
        case decoding(String)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case filename
        case title
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let typeString = try? container.decode(String.self, forKey: .type) else {
            throw CodingError.decoding("ContentPart couldn't be decoded")
        }

        switch typeString {
        case "Header":
            guard let valueString = try? container.decode(String.self, forKey: .text) else {
                throw CodingError.decoding("ContentPart couldn't be decoded")
            }

            self = .header(valueString)
        case "Paragraph":
            guard let valueString = try? container.decode(String.self, forKey: .text) else {
                throw CodingError.decoding("ContentPart couldn't be decoded")
            }

            self = .paragraph(valueString)
        case "Image":
            guard let valueString = try? container.decode(String.self, forKey: .filename) else {
                throw CodingError.decoding("ContentPart couldn't be decoded")
            }

            self = .image(filename: valueString)
        case "Link":
            guard let title = try? container.decode(String.self, forKey: .title),
                  let urlString = try? container.decode(String.self, forKey: .url) else {
                throw CodingError.decoding("ContentPart couldn't be decoded")
            }

            self = .link(title: title, urlString: urlString)
        default:
            throw CodingError.decoding("ContentPart couldn't be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .header(let value):
            try? container.encode("Header", forKey: .type)
            try? container.encode(value, forKey: .text)
        case .paragraph(let value):
            try? container.encode("Paragraph", forKey: .type)
            try? container.encode(value, forKey: .text)
        case .image(let value):
            try? container.encode("Image", forKey: .type)
            try? container.encode(value, forKey: .filename)
        case .link(let title, let urlString):
            try? container.encode("Link", forKey: .type)
            try? container.encode(title, forKey: .title)
            try? container.encode(urlString, forKey: .url)
        }
    }
}

public enum ContentLocation: Codable, Identifiable, Equatable {
    public var id: UUID {
        return UUID()
    }

    case github(repo: String, accessToken: String)
    case local(path: String)

    enum CodingError: Error {
        case decoding(String)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case repo
        case accessToken
        case path
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let typeString = try? container.decode(String.self, forKey: .type) else {
            throw CodingError.decoding("ContentPart couldn't be decoded")
        }

        switch typeString {
        case "Github":
            guard let repoString = try? container.decode(String.self, forKey: .repo),
                  let accessTokenString = try? container.decode(String.self, forKey: .accessToken) else {
                throw CodingError.decoding("ContentLocation couldn't be decoded")
            }

            self = .github(repo: repoString, accessToken: accessTokenString)
        case "Local":
            guard let valueString = try? container.decode(String.self, forKey: .path) else {
                throw CodingError.decoding("ContentLocation couldn't be decoded")
            }

            self = .local(path: valueString)
        default:
            throw CodingError.decoding("ContentPart couldn't be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .github(let repo, let accessToken):
            try? container.encode("Github", forKey: .type)
            try? container.encode(repo, forKey: .repo)
            try? container.encode(accessToken, forKey: .accessToken)
        case .local(let path):
            try? container.encode("Local", forKey: .type)
            try? container.encode(path, forKey: .path)
        }
    }
}
