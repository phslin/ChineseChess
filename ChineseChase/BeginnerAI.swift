//
//  BeginnerAI.swift
//  ChineseChase
//
//  Beginner AI implementation for single player mode
//

import Foundation
import GameplayKit

/// Beginner AI that makes random moves with basic piece value awareness
public class BeginnerAI: BanqiAIEngine {
    
    public override init(name: String = "Beginner AI", randomSource: GKRandomSource = GKRandomSource.sharedRandom()) {
        super.init(name: name, randomSource: randomSource)
    }
    
    public override func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        
        guard !legalMoves.isEmpty else {
            // No legal moves available
            return .flip(at: BanqiPosition(column: 0, row: 0)) // Fallback
        }
        
        // Separate moves by type for better decision making
        let flipMoves = legalMoves.filter { if case .flip = $0 { return true } else { return false } }
        let captureMoves = legalMoves.filter { if case .capture = $0 { return true } else { return false } }
        let regularMoves = legalMoves.filter { if case .move = $0 { return true } else { return false } }
        
        // Priority order: captures > flips > regular moves
        if !captureMoves.isEmpty {
            // Prefer captures, especially of high-value pieces
            let bestCapture = selectBestCapture(from: captureMoves, in: game)
            return bestCapture
        }
        
        if !flipMoves.isEmpty {
            // Random flip move
            return flipMoves[randomSource.nextInt(upperBound: flipMoves.count)]
        }
        
        if !regularMoves.isEmpty {
            // Random regular move
            return regularMoves[randomSource.nextInt(upperBound: regularMoves.count)]
        }
        
        // Fallback to any legal move
        return legalMoves[randomSource.nextInt(upperBound: legalMoves.count)]
    }
    
    public override func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double {
        // Simple material counting for beginner AI
        return PositionEvaluator.evaluatePosition(game, for: player)
    }
    
    // MARK: - Private Helper Methods
    
    /// Selects the best capture move based on piece values
    private func selectBestCapture(from captures: [BanqiAction], in game: BanqiGame) -> BanqiAction {
        var bestCapture = captures[0]
        var bestValue = -1.0
        
        for capture in captures {
            if case .capture(_, let to) = capture {
                if let targetPiece = game.board[to.row][to.column] {
                    let pieceValue = getPieceValue(targetPiece.type)
                    if pieceValue > bestValue {
                        bestValue = pieceValue
                        bestCapture = capture
                    }
                }
            }
        }
        
        // 70% chance to make the best capture, 30% chance to make a random capture
        if randomSource.nextUniform() < 0.7 {
            return bestCapture
        } else {
            return captures[randomSource.nextInt(upperBound: captures.count)]
        }
    }
    
    /// Gets the value of a piece type
    private func getPieceValue(_ pieceType: BanqiPieceType) -> Double {
        switch pieceType {
        case .general: return 9.0
        case .advisor: return 2.0
        case .elephant: return 2.0
        case .chariot: return 9.0
        case .horse: return 4.0
        case .cannon: return 4.5
        case .soldier: return 1.0
        }
    }
}
