//
//  ChatBot.swift
//  PureLifeYogi
//
//  Created by mahmmud abdolaziz on 2024-05-03.
//

import Foundation

// Define the chatbot's responses
let responses: [String] = [
    "Hello!",
    "Hi there!",
    "Greetings!",
    "Howdy!",
    "Salut!",
    "Witaj!",
    "Namaste!",
    "How can I assist you today?"
]





// Define a function to handle incoming messages
func handleIncomingMessage(message: String) {
    
    // Iterate through the chatbot's responses and return one at random
    let responseIndex = Int.random(in: 0..<responses.count)
    let selectedResponse = responses[responseIndex]
    
    // Print out the selected chatbot response
    print(selectedResponse)
    
    // If the selected chatbot response is "How can I assist you today?",
    // then call the handleIncomingMessage function and pass in the "Hello!" message as the argument
    if selectedResponse == "How can I assist you today?" {
        handleIncomingMessage(message: "Hello!")
    }
}

// Define a main function that starts up the chatbot
func main() {
    // Start the conversation with a "Hello!" message
    handleIncomingMessage(message: "Hello!")
}

// Call the main function to start the chatbot

