//
//  ViewController.swift
//  AI
//
//  Created by wny on 24/12/2025.
//

import UIKit

class HussainViewController2: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    //MARK: - Model
    
    struct Message {
        let text: String
        let isUser: Bool
        let isTyping: Bool
    }
    
    private var messages: [Message] = []
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        setupUI()
        setupTableView()
        setupKeyboard()
        setupHeader()
        
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Header Setup
    
    private func setupHeader(){
        headerView.layer.cornerRadius = 18
        headerView.layer.masksToBounds = true
        
    }
    
    
    
    
    //MARK: - UI Setup
    
    private func setupUI() {
        inputContainer.layer.cornerRadius = 25
        inputContainer.layer.masksToBounds = true
        
    }
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        
    }
    

    
    //MARK: - Keyboard
    
    private func setupKeyboard(){
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard(){
        view.endEditing(true)
    }
    
    //MARK: - AI connection
    let systemPrompt = """
    You are an AI chatbot for a food donation mobile application.

    You may respond naturally to greetings such as:
    - hi
    - hello
    - hey

    You help with:
    - Food donation
    - How to use the app
    - SDG 2 (Zero Hunger)
    - SDG 12 (Responsible Consumption)

    If the user asks something unrelated AFTER the conversation has started,
    respond with:
    "I can only help with food donation, app-related questions, and sustainability goals."

    Be friendly and helpful.
    """
    
    //MARK: - Typing indicator
    
    private func showTypingIndicator(){
        messages.append(Message(text: "", isUser: false, isTyping: true))
        tableView.reloadData()
        scrollToBottom()
    }
        
    private func hideTypingIndicator(){
        messages.removeAll{ $0.isTyping }
        tableView.reloadData()
    }
    
    // MARK: - Local greeting handler

    private func handleLocalMessage(_ text: String) -> String? {
        let msg = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if msg == "hi" || msg == "hello" || msg == "hey" {
            return "Hi 👋 How can I help you today?"
        }

        return nil
    }
    //MARK: - API CALL
        
        private var chatAPIKey: String {
            guard let key = ProcessInfo.processInfo.environment["CHAT_API_KEY"],
                  !key.isEmpty else {
                fatalError("CHAT_API_KEY not found in Environment Variables")
            }
            return key
        }
        
        func sendMessageToAPI(userText: String) {

            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            request.setValue("Bearer \(chatAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userText]
                ]
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else { return }

                let reply = self.parseResponse(data)

                DispatchQueue.main.async {
                    self.hideTypingIndicator()
                    self.messages.append(
                        Message(text: reply, isUser: false, isTyping: false)
                    )
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }.resume()
        }
        
        func parseResponse(_ data: Data) -> String {
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String
            else {
                return "Sorry, I couldn’t understand that."
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

    
    
    
    //MARK: - Actions
    
    @IBAction func sendTapped(_ sender: UIButton) {
        guard let text = messageTextField.text,
              !text.trimmingCharacters(in: .whitespaces).isEmpty else {return}
        
        messages.append(Message(text: text, isUser: true, isTyping: false))
        tableView.reloadData()
        scrollToBottom()
        messageTextField.text = ""
        
        if let localReply = handleLocalMessage(text){
            messages.append(Message(text: localReply, isUser: false, isTyping: false))
            tableView.reloadData()
            scrollToBottom()
            return
        }
        
        
        showTypingIndicator()
        sendMessageToAPI(userText: text)
        
    }
    
    private func addMessage(text: String, isUser: Bool){
        messages.append(Message(text: text, isUser: isUser, isTyping: false))
        tableView.reloadData()
        scrollToBottom()
    }
    
    //MARK: - table logic
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
        
        let message = messages[indexPath.row]
        cell.configure(text: message.text, isUser:  message.isUser)
        cell.configureTyping(message.isTyping)
        return cell
        
    }
    
    
    
    
    
    //MARK: -
    
    private func scrollToBottom(){
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(
            row: messages.count - 1,
            section: 0
        )
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
}

