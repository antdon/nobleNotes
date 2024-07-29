import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    private var controller: Controller
    private var notesList: UITableView
    private var refreshControl: UIRefreshControl
    private var notes:[Note]
    private var newlyCreatedNote:Note?
    private var mostRecentlyViewedIndex:Int
    init() {
        self.controller = Controller()
        self.controller.populateNotes()
        self.notesList = {
            let notesList = UITableView()
            notesList.backgroundColor = UIColor.white
            notesList.translatesAutoresizingMaskIntoConstraints = false
            return notesList
        }()
        refreshControl = UIRefreshControl()
        self.notes = []
        self.mostRecentlyViewedIndex = -1
        super.init(nibName: nil, bundle: nil)
        self.controller.viewController = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNewNoteButton()
    }
    
    func setupTableView() {
        notesList.register(NoteCell.self, forCellReuseIdentifier: "cellId")
        view.addSubview(notesList)
        notesList.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        notesList.delegate = self
        notesList.dataSource = self
        
        NSLayoutConstraint.activate([
            notesList.topAnchor.constraint(equalTo: self.view.topAnchor),
            notesList.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            notesList.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            notesList.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        ])
    }
    
    func setupNewNoteButton() {
        let pencilImage = UIImage(systemName: "square.and.pencil")
        let elipsisImage = UIImage(systemName: "ellipsis")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: pencilImage, style: .plain, target: self, action: #selector(newNote))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: elipsisImage, style: .plain, target: self, action: #selector(toggleEditable))
    }
    
    @objc func newNote() {
        let maxId = notes.max{a,b in a.id < b.id}
        var newId = "1"
        if let maxId = maxId {
            newId = String(Int(maxId.id)! + 1)
        }
        let creationDate = "21/01/00" // fix this lmao
        newlyCreatedNote = Note(id: newId, creationdate: creationDate)
        navigationController?.pushViewController(NoteEditingView(note: newlyCreatedNote!), animated: true)
    }
    
    @objc func toggleEditable() {
        notesList.setEditing(!notesList.isEditing, animated: true)
    }
    
    // Server interaction
    
    @MainActor
    func updateUI(notes: [Note])  {
        self.notes = notes
        notesList.reloadData()
    }
    
    @objc func handleRefreshControl() {
        self.controller.populateNotes()
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }
    
    // UITableViewDelegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! NoteCell
        cell.backgroundColor = UIColor.white
        cell.selectionStyle = .none
        if notes != [] {
            cell.noteTitleLabel.text = notes[indexPath.row].title
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = notes[indexPath.row]
        let noteEditingView = NoteEditingView(note: note)
        mostRecentlyViewedIndex = indexPath.row
        navigationController?.pushViewController(noteEditingView, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            controller.deleteServerNote(note: notes[indexPath.row])
            notes.remove(at: indexPath.row)
            notesList.deleteRows(at: [indexPath], with: .left)
        }
    }
    
    // UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController.isKind(of: NoteEditingView.self) {
            if let newlyCreatedNote = newlyCreatedNote, newlyCreatedNote.title != "" {
                notes.append(newlyCreatedNote)
                controller.createServerNote(note: newlyCreatedNote)
                self.newlyCreatedNote = nil
            }
            notesList.reloadData()
            if mostRecentlyViewedIndex != -1 {
                controller.updateServerNote(note: notes[mostRecentlyViewedIndex])
            }
        }

    }
    
}

class NoteCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    func setupView() {
        addSubview(noteTitleLabel)

        noteTitleLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
//        noteTitleLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        noteTitleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        noteTitleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder is not implemented")
    }
    
    let noteTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    

}

class NoteEditingView: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    var titleLabel = {
        let field = UITextField()
        field.textColor = UIColor.black
        field.font = UIFont.boldSystemFont(ofSize: 48)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    var contentLabel = {
        let field = UITextView()
        field.textColor = UIColor.black
        field.isScrollEnabled = true
        field.font = UIFont.systemFont(ofSize: 24)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    var note:Note;
    
    init(note: Note) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
        if let title = note.title {self.titleLabel.text = title}
        if let content = note.content {
            self.contentLabel.text = content
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        titleLabel.delegate = self
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            titleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
        ])
        
        contentLabel.delegate = self
        view.addSubview(contentLabel)
        NSLayoutConstraint.activate([
            contentLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            contentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 16),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            contentLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 16)
        ])
    }
    
    func textViewDidChange(_ textView: UITextView) {
        note.content = textView.text
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        note.title = textField.text
    }
}

