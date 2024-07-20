//
//  MessageView.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-04-28.
//

import SwiftUI
// import OpenAI
import Alamofire

// AI Chatbot Configuration
struct AIChatBot {
    private let openAIKey = "YOUR_OPENAI_API_KEY"
    private let ollamaKey = "YOUR_OLLAMA_API_KEY"
    
    // Function to generate response using OpenAI
    func generateResponseOpenAI(message: String, completion: @escaping (String) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(openAIKey)"
        ]
        
        let parameters: [String: Any] = [
            "model": "text-davinci-002",
            "prompt": "Pure Life Yogi brand: \(message)",
            "max_tokens": 150
        ]
        
        AF.request("https://api.openai.com/v1/engines/text-davinci-002/completions",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let choices = json["choices"] as? [[String: Any]], let text = choices.first?["text"] as? String {
                    completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case .failure(let error):
                print("Error in OpenAI response: \(error)")
                completion("Sorry, I couldn't understand that.")
            }
        }
    }
    
    // Function to generate response using Ollama
    func generateResponseOllama(message: String, completion: @escaping (String) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(ollamaKey)"
        ]
        
        let parameters: [String: Any] = [
            "prompt": "Analyze market trends for Pure Life Yogi and respond: \(message)",
            "max_tokens": 150
        ]
        
        AF.request("https://api.ollama.ai/v1/completions",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let choices = json["choices"] as? [[String: Any]], let text = choices.first?["text"] as? String {
                    completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case .failure(let error):
                print("Error in Ollama response: \(error)")
                completion("Sorry, I couldn't understand that.")
            }
        }
    }
    
    // Function to decide which AI to use
    func respondToMessage(message: String, completion: @escaping (String) -> Void) {
        if message.contains("market") {
            generateResponseOllama(message: message, completion: completion)
        } else {
            generateResponseOpenAI(message: message, completion: completion)
        }
    }
}

// Model for Messages
struct Message: Identifiable {
    let id = UUID()
    let sender: String
    let content: String
    let isAIResponse: Bool
}

// View for Message Row
struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isAIResponse {
                Spacer()
            }
            
            Text(message.content)
                .padding(10)
                .foregroundColor(message.isAIResponse ? .white : .black)
                .background(message.isAIResponse ? Color.blue : Color.gray.opacity(0.5))
                .cornerRadius(10)
            
            if !message.isAIResponse {
                Spacer()
            }
        }
    }
}

// View for Messaging
struct MessageView: View {
    @State private var messages: [Message] = []
    @State private var inputText = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Type your message...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: sendMessage) {
                        Text("Send")
                    }
                    .padding(.trailing)
                }
            }
            .navigationTitle("Messages")
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // User message
        addMessage(Message(sender: "User", content: inputText, isAIResponse: false))
        
        // Simulate AI response
        let aiResponse = generateAIResponse(for: inputText)
        addMessage(Message(sender: "Pure Life Yogi", content: aiResponse, isAIResponse: true))
        
        // Clear input field
        inputText = ""
    }
    
    private func addMessage(_ message: Message) {
        messages.append(message)
        
        // Scroll to the bottom of messages
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async {
            if let lastMessage = messages.last {
                withAnimation {
                    // Scroll to the last message
                }
            }
        }
    }
    
    // Advanced AI response generation tailored for Pure Life Yogi
    private func generateAIResponse(for message: String) -> String {
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("hello") {
            return "Hello, welcome to Pure Life Yogi! How can I assist you with our yoga products today?"
        } else if lowercasedMessage.contains("thank you") {
            return "You're welcome! Namaste 🙏"
        } else if lowercasedMessage.contains("cork yoga mat") {
            return "Our cork yoga mats are perfect for a sustainable practice. They offer great grip and are eco-friendly!"
        } else if lowercasedMessage.contains("tpe yoga mat") {
            return "TPE yoga mats are made from thermoplastic elastomers, known for their elasticity and recyclability. Ideal for those who prioritize comfort and eco-friendliness!"
        } else if lowercasedMessage.contains("yoga roller") {
            return "Our yoga rollers with massage balls are great for deep tissue massage and can help relieve muscle tension after a long yoga session."
        } else if lowercasedMessage.contains("spirituality") {
            return "Spirituality is at the core of yoga. It's not just about physical exercise; it's about connecting with your inner self."
        } else if lowercasedMessage.contains("help") {
            return "Sure, I'm here to help! Please ask me anything about our yoga products or your yoga practice."
        } else {
            return "I'm not sure how to answer that. Could you please provide more details or ask about our products like cork and TPE yoga mats, or our yoga rollers?"
        }
    }
}

// View for Contact Row
struct ContactRow: View {
    let name: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text(name)
            }
        }
    }
}

// View for Contacts List
struct ContactListView: View {
    var body: some View {
        List {
            Section(header: Text("Support")) {
                ContactRow(name: "Pure Life Yogi Support") {
                    // Navigate to Chatbot
                    // You can implement navigation here
                }
                ContactRow(name: "Customer Support") {
                    // Navigate to Customer Support
                    // You can implement navigation here
                }
            }
        }
        .navigationTitle("Contacts")
    }
}

// Tabbed View for Messages and Contacts
struct MessageTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                MessageView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Messages")
            }
            
            NavigationView {
                ContactListView()
            }
            .tabItem {
                Image(systemName: "phone.fill")
                Text("Contacts")
            }
        }
    }
}
