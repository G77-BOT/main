//
//  DiceGameView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-05-08.
//

import Foundation
import SwiftUI
import AVFoundation

import SceneKit
import MessageUI

class DiceGameView: ObservableObject, MFMessageComposeViewControllerDelegate {
    @Published var diceValues: [Int] = [1, 1]
    @Published var score: Int = 0
    var rollSound: AVAudioPlayer?
    var gameType: DiceGameType = .simple
    var players: [Player] = []
    var botPlayer: Player?
    var isBotChallenge: Bool = false

    init() {
        loadSound()
        setupGame()
    }

    func setupGame() {
        switch gameType {
        case .simple:
            setupSimpleGame()
        case .hood:
            setupHoodGame()
        }
    }

    func setupSimpleGame() {
        diceValues = [1, 1]
        score = 0
        players = [Player(name: "Player 1"), Player(name: "Player 2")]
    }

    func setupHoodGame() {
        diceValues = [1, 1, 1]
        score = 0
        players = [Player(name: "Player 1", avatar: "avatar1.scn"), Player(name: "Player 2", avatar: "avatar2.scn")]
        botPlayer = Player(name: "Bot", avatar: "botAvatar.scn")
        isBotChallenge = true
    }

    func rollDice() {
        diceValues = diceValues.map { _ in Int.random(in: 1...6) }
        score += diceValues.reduce(0, +)
        playSound()
        print("You rolled dice and got \(diceValues), Your score is \(score)")
    }

    private func loadSound() {
        if let path = Bundle.main.path(forResource: "diceRoll", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                rollSound = try AVAudioPlayer(contentsOf: url)
                rollSound?.prepareToPlay()
            } catch {
                print("Dice roll sound could not be loaded")
            }
        }
    }

    private func playSound() {
        rollSound?.play()
    }

    func resetGame() {
        score = 0
        setupGame()
        print("Game has been reset, Start again!")
    }

    func sendGameInvite(to phoneNumber: String) {
        if MFMessageComposeViewController.canSendText() {
            let messageVC = MFMessageComposeViewController()
            messageVC.body = "Join me in a dice game!"
            messageVC.recipients = [phoneNumber]
            messageVC.messageComposeDelegate = self
            // Present messageVC in your view controller
        } else {
            print("SMS services are not available")
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Handle the result of the message composition
    }
}

enum DiceGameType {
    case simple
    case hood
}

class Player {
    var name: String
    var avatar: String?

    init(name: String, avatar: String? = nil) {
        self.name = name
        self.avatar = avatar
    }
}