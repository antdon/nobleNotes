import Foundation

let serverPath = ""



func getNotes() async throws -> [Note] {
    let endpoint = serverPath + "/notes"
    
    guard let url = URL(string: endpoint) else { throw NotesError.invalidURL }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw  NotesError.invalidResponse
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode([Note].self, from: data)
    }
}

func updateNote(id:String, title:String?, content:String?) async throws {
    let queryItems = [
        URLQueryItem(name: "id", value: id),
        URLQueryItem(name: "title", value: title),
        URLQueryItem(name: "content", value: content)
    ]
    var urlComponents = URLComponents(string: serverPath + "/notes/update")
    urlComponents?.queryItems = queryItems

    guard let url = urlComponents?.url else { throw NotesError.invalidURL }

    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    
    let (_, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NotesError.invalidResponse
    }
}

func createNote(note:Note) async throws {
    guard let url = URL(string: serverPath + "/notes/create") else {throw NotesError.invalidURL}
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    do {
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(note)
    }
    
    let (_, response) = try await URLSession.shared.data(for: request)
}

func deleteNote(note:Note) async throws {
    let queryItems = [URLQueryItem(name:"id", value: note.id)]
    var urlComponents = URLComponents(string: serverPath + "/notes/delete")
    urlComponents?.queryItems = queryItems
    guard let url = urlComponents?.url else { throw NotesError.invalidURL }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    
    let (_, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NotesError.invalidResponse
    }
}

class Controller {
    weak var viewController: ViewController?
    init(viewController: ViewController? = nil) {
        self.viewController = viewController
    }
    func populateNotes() {
        Task {
            let notes = try await getNotes()
            await viewController?.updateUI(notes:notes)
        }
    }
    func updateServerNote(note:Note) {
        Task {
            try await updateNote(id:note.id, title:note.title, content:note.content)
        }
    }
    func createServerNote(note:Note) {
        Task {
            try await createNote(note:note)
        }
    }
    func deleteServerNote(note:Note) {
        Task {
            try await deleteNote(note:note)
        }
    }
}


