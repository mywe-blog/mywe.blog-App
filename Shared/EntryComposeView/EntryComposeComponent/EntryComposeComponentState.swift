import Foundation

struct EntryComposeComponentState: Equatable, Identifiable {
    enum ComponentType: Equatable {
        case headline(String)
        case paragraph(String)
        case imageURL(URL, String)
        case uploadingImage(Data, startUpload: Bool)
    }

    var componentType: ComponentType

    let id: UUID = UUID()
    let postfolder: String

    var text: String {
        switch componentType {
        case .headline(let string):
            return string
        case .paragraph(let string):
            return string
        case .imageURL(let url, _):
            return url.absoluteString
        case .uploadingImage:
            return "Uploading"
        }
    }

    func toContentPart() -> ContentPart? {
        switch componentType {
        case .headline(let string):
            return .header(string)
        case .imageURL(_, let filename):
            return .image(filename)
        case .paragraph(let string):
            return .paragraph(string)
        case .uploadingImage:
            return nil
        }
    }
}
