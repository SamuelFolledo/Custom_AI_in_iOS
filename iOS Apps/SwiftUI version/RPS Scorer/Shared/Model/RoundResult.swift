//
//  RoundResult.swift
//  RPS Scorer (iOS)
//
//  Created by Samuel Folledo on 8/21/22.
//

import Foundation

enum RoundResult: String {
    case tieRound, p1WonRound, p2WonRound, p1WonGame, p2WonGame
    
    var description: String {
        return self.rawValue
    }
    
    var announcement: String {
        get {
            switch self {
            case .tieRound: return "Tied"
            case .p1WonRound: return "Player 1 plus 1"
            case .p2WonRound: return "Player 2 plus 1"
            case .p1WonGame: return "Player 1 wins"
            case .p2WonGame: return "Player 2 wins"
            }
        }
    }
}
