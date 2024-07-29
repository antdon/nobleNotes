import Foundation

final class Note:Codable, Equatable {
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, creationdate: String, title: String? = nil, content: String? = nil) {
        self.id = id
        self.creationdate = creationdate
        self.title = title
        self.content = content
    }
    
    var id:String
    var creationdate: String
    var title: String?
    var content: String?
}
