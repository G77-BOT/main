//
//  LudoGameView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-05-08.
//

import Foundation
import SwiftUI

struct LudoGameView: View {
    @StateObject private var ludoGame = LudoGameViewModel()

    var body: some View {
        ZStack {
            // Background for the Ludo board
            Color.green.edgesIgnoringSafeArea(.all)
            
            // Ludo board layout
            LudoBoardView(game: ludoGame)
            
            // Controls and information panel
            VStack {
                Spacer()
                gameControls
                Spacer()
                gameInformation
            }
        }
        .alert(isPresented: $ludoGame.showAlert) {
            Alert(title: Text("Game Over"), message: Text(ludoGame.winnerMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var gameControls: some View {
        HStack {
            Button(action: {
                ludoGame.rollDice()
            }) {
                Text("Roll Dice")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(ludoGame.isDiceRolling)
            
            if ludoGame.canPassTurn {
                Button(action: {
                    ludoGame.passTurn()
                }) {
                    Text("Pass")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private var gameInformation: some View {
        VStack {
            Text("Current Turn: \(ludoGame.currentPlayerName)")
                .font(.headline)
            Text("Dice Roll: \(ludoGame.lastDiceRoll)")
                .font(.subheadline)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
    }
}

struct LudoBoardView: View {
    @ObservedObject var game: LudoGameViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Path { path in
                // Drawing the Ludo board based on the size of the view
                // This is a placeholder for the actual board drawing logic
            }
            .fill(Color.white)
        }
    }
}

class LudoGameViewModel: ObservableObject {
    @Published var currentPlayerName = "Player 1"
    @Published var lastDiceRoll = 0
    @Published var isDiceRolling = false
    @Published var canPassTurn = false
    @Published var showAlert = false
    @Published var winnerMessage = ""
    
    func rollDice() {
        isDiceRolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.lastDiceRoll = Int.random(in: 1...6)
            self.isDiceRolling = false
            // Handle game logic after dice roll
        }
    }
    
    func passTurn() {
        currentPlayerName = "Player \((Int(currentPlayerName.split(separator: " ").last!)! % noOfPlayer) + 1)"
        canPassTurn = false
    }
}
