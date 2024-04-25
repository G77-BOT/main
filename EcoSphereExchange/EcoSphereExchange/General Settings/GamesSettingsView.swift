//
//  GamesSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI

struct GamesSettingsView: View {
    @State private var diceGameEnabled: Bool = true
    @State private var cardGameEnabled: Bool = false
    @State private var candyGameEnabled: Bool = false
    @State private var diceGameDifficulty: Double = 1.0
    @State private var cardGameDifficulty: Double = 2.0
    @State private var candyGameDifficulty: Double = 3.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dice Game")) {
                    Toggle("Enable Dice Game", isOn: $diceGameEnabled)
                    if diceGameEnabled {
                        Slider(value: $diceGameDifficulty, in: 1...3, step: 1) {
                            Text("Difficulty Level")
                        }
                        Text("Difficulty: \(difficultyText(diceGameDifficulty))")
                    }
                }
                
                Section(header: Text("Card Game")) {
                    Toggle("Enable Card Game", isOn: $cardGameEnabled)
                    if cardGameEnabled {
                        Slider(value: $cardGameDifficulty, in: 1...3, step: 1) {
                            Text("Difficulty Level")
                        }
                        Text("Difficulty: \(difficultyText(cardGameDifficulty))")
                    }
                }
                
                Section(header: Text("Candy Game")) {
                    Toggle("Enable Candy Game", isOn: $candyGameEnabled)
                    if candyGameEnabled {
                        Slider(value: $candyGameDifficulty, in: 1...3, step: 1) {
                            Text("Difficulty Level")
                        }
                        Text("Difficulty: \(difficultyText(candyGameDifficulty))")
                    }
                }
                
                Section {
                    Button(action: {
                        // Action to save game settings
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Games Settings")
        }
    }
    
    func difficultyText(_ value: Double) -> String {
        switch value {
        case 1:
            return "Easy"
        case 2:
            return "Medium"
        case 3:
            return "Hard"
        default:
            return "Unknown"
        }
    }
}
