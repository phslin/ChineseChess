//
//  IntermediateAI.swift
//  ChineseChase
//
//  Intermediate AI implementation for single player mode
//

import Foundation
import GameplayKit

/// Intermediate AI that uses 2-ply minimax search with alpha-beta pruning
public class IntermediateAI: BanqiAIEngine {
    
    public override init(name: String = "Intermediate AI", randomSource: GKRandomSource = GKRandomSource.sharedRandom()) {
        super.init(name: name, randomSource: randomSource)
    }
    
    public override func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        
        guard !legalMoves.isEmpty else {
            // No legal moves available
            return .flip(at: BanqiPosition(column: 0, row: 0)) // Fallback
        }
        
        // For intermediate AI, use 2-ply search
        let searchDepth = min(difficulty.searchDepth, 2)
        let timeLimit = difficulty.maxThinkingTime
        
        // Use iterative deepening search with time limit
        if let bestMove = SearchEngine.iterativeDeepeningSearch(game: game, maxDepth: searchDepth, timeLimit: timeLimit) {
            return bestMove
        }
        
        // Fallback to beginner AI logic if search fails
        return fallbackMoveSelection(for: game, from: legalMoves)
    }
    
    public override func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double {
        // Enhanced position evaluation for intermediate AI
        var score = PositionEvaluator.evaluatePosition(game, for: player)
        
        // Add some strategic considerations
        score += evaluateStrategicFactors(game: game, for: player)
        
        return score
    }
    
    // MARK: - Private Helper Methods
    
    /// Fallback move selection using beginner AI logic
    private func fallbackMoveSelection(for game: BanqiGame, from legalMoves: [BanqiAction]) -> BanqiAction {
        // Separate moves by type
        let flipMoves = legalMoves.filter { if case .flip = $0 { return true } else { return false } }
        let captureMoves = legalMoves.filter { if case .capture = $0 { return true } else { return false } }
        let regularMoves = legalMoves.filter { if case .move = $0 { return true } else { return false } }
        
        // Priority order: captures > flips > regular moves
        if !captureMoves.isEmpty {
            let bestCapture = selectBestCapture(from: captureMoves, in: game)
            return bestCapture
        }
        
        if !flipMoves.isEmpty {
            // Prefer flipping pieces in strategic positions
            let strategicFlip = selectStrategicFlip(from: flipMoves, in: game)
            return strategicFlip
        }
        
        if !regularMoves.isEmpty {
            // Prefer moves that improve piece position
            let strategicMove = selectStrategicMove(from: regularMoves, in: game)
            return strategicMove
        }
        
        // Fallback to random move
        return legalMoves[randomSource.nextInt(upperBound: legalMoves.count)]
    }
    
    /// Selects the best capture move based on piece values and position
    private func selectBestCapture(from captures: [BanqiAction], in game: BanqiGame) -> BanqiAction {
        var bestCapture = captures[0]
        var bestScore = -Double.infinity
        
        for capture in captures {
            if case .capture = capture {
                let score = evaluateCaptureMove(capture, in: game)
                if score > bestScore {
                    bestScore = score
                    bestCapture = capture
                }
            }
        }
        
        return bestCapture
    }
    
    /// Evaluates a capture move considering piece value and position
    private func evaluateCaptureMove(_ capture: BanqiAction, in game: BanqiGame) -> Double {
        guard case .capture(_, let to) = capture else { return 0.0 }
        
        var score = 0.0
        
        // Piece value
        if let targetPiece = game.board[to.row][to.column] {
            score += getPieceValue(targetPiece.type)
        }
        
        // Position bonus (center control)
        if isCenterPosition(to) {
            score += 0.5
        }
        
        // Safety bonus (avoiding immediate recapture)
        if !isPositionUnderThreat(to, in: game) {
            score += 0.3
        }
        
        return score
    }
    
    /// Selects a strategic flip move
    private func selectStrategicFlip(from flips: [BanqiAction], in game: BanqiGame) -> BanqiAction {
        var bestFlip = flips[0]
        var bestScore = -Double.infinity
        
        for flip in flips {
            if case .flip(let at) = flip {
                let score = evaluateFlipPosition(at, in: game)
                if score > bestScore {
                    bestScore = score
                    bestFlip = flip
                }
            }
        }
        
        return bestFlip
    }
    
    /// Evaluates a flip position for strategic value
    private func evaluateFlipPosition(_ position: BanqiPosition, in game: BanqiGame) -> Double {
        var score = 0.0
        
        // Center position bonus
        if isCenterPosition(position) {
            score += 1.0
        }
        
        // Edge position penalty
        if isEdgePosition(position) {
            score -= 0.5
        }
        
        // Adjacent to own pieces bonus
        score += evaluateAdjacentPieces(at: position, in: game)
        
        return score
    }
    
    /// Selects a strategic regular move
    private func selectStrategicMove(from moves: [BanqiAction], in game: BanqiGame) -> BanqiAction {
        var bestMove = moves[0]
        var bestScore = -Double.infinity
        
        for move in moves {
            if case .move(_, let to) = move {
                let score = evaluateMovePosition(to, in: game)
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }
        }
        
        return bestMove
    }
    
    /// Evaluates a move position for strategic value
    private func evaluateMovePosition(_ position: BanqiPosition, in game: BanqiGame) -> Double {
        var score = 0.0
        
        // Center control bonus
        if isCenterPosition(position) {
            score += 0.8
        }
        
        // Edge position penalty
        if isEdgePosition(position) {
            score -= 0.3
        }
        
        // Mobility bonus
        score += evaluateMobility(at: position, in: game)
        
        return score
    }
    
    /// Checks if a position is in the center of the board
    private func isCenterPosition(_ position: BanqiPosition) -> Bool {
        let centerColumns = [1, 2]
        let centerRows = [3, 4]
        return centerColumns.contains(position.column) && centerRows.contains(position.row)
    }
    
    /// Checks if a position is on the edge of the board
    private func isEdgePosition(_ position: BanqiPosition) -> Bool {
        return position.column == 0 || position.column == 3 || position.row == 0 || position.row == 7
    }
    
    /// Evaluates adjacent pieces for strategic value
    private func evaluateAdjacentPieces(at position: BanqiPosition, in game: BanqiGame) -> Double {
        var score = 0.0
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        for (dx, dy) in directions {
            let adjCol = position.column + dx
            let adjRow = position.row + dy
            
            if adjCol >= 0 && adjCol < BanqiGame.numberOfColumns && 
               adjRow >= 0 && adjRow < BanqiGame.numberOfRows {
                if let piece = game.board[adjRow][adjCol], piece.isFaceUp {
                    if piece.color == game.sideToMove {
                        score += 0.2 // Own piece bonus
                    } else {
                        score -= 0.1 // Enemy piece penalty
                    }
                }
            }
        }
        
        return score
    }
    
    /// Evaluates mobility at a position
    private func evaluateMobility(at position: BanqiPosition, in game: BanqiGame) -> Double {
        // Simple mobility evaluation based on available directions
        var availableDirections = 0
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        for (dx, dy) in directions {
            let newCol = position.column + dx
            let newRow = position.row + dy
            
            if newCol >= 0 && newCol < BanqiGame.numberOfColumns && 
               newRow >= 0 && newRow < BanqiGame.numberOfRows {
                if game.board[newRow][newCol] == nil {
                    availableDirections += 1
                }
            }
        }
        
        return Double(availableDirections) * 0.1
    }
    
    /// Checks if a position is under threat
    private func isPositionUnderThreat(_ position: BanqiPosition, in game: BanqiGame) -> Bool {
        guard let currentPlayer = game.sideToMove else { return false }
        let opponent = currentPlayer.opponent
        
        // Check if any opponent piece can capture at this position
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == opponent {
                    let fromPos = BanqiPosition(column: col, row: row)
                    let legalMoves = game.legalMovesAndCaptures(for: piece, at: fromPos)
                    
                    for move in legalMoves {
                        if case .capture(_, let to) = move, to == position {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    /// Evaluates strategic factors for the position
    private func evaluateStrategicFactors(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // King safety evaluation
        score += evaluateKingSafety(game: game, for: player)
        
        // Development evaluation
        score += evaluateDevelopment(game: game, for: player)
        
        return score
    }
    
    /// Evaluates king safety
    private func evaluateKingSafety(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Find the king
        var kingPosition: BanqiPosition?
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.type == .general, piece.color == player {
                    kingPosition = BanqiPosition(column: col, row: row)
                    break
                }
            }
        }
        
        guard let kingPos = kingPosition else { return score }
        
        // Penalty for king being exposed
        if isEdgePosition(kingPos) {
            score -= 0.5
        }
        
        // Bonus for king being protected
        if hasProtectivePieces(around: kingPos, in: game, for: player) {
            score += 0.3
        }
        
        return score
    }
    
    /// Checks if there are protective pieces around the king
    private func hasProtectivePieces(around position: BanqiPosition, in game: BanqiGame, for player: BanqiPieceColor) -> Bool {
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        for (dx, dy) in directions {
            let adjCol = position.column + dx
            let adjRow = position.row + dy
            
            if adjCol >= 0 && adjCol < BanqiGame.numberOfColumns && 
               adjRow >= 0 && adjRow < BanqiGame.numberOfRows {
                if let piece = game.board[adjRow][adjCol], piece.isFaceUp, piece.color == player {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Evaluates piece development
    private func evaluateDevelopment(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Bonus for having pieces in the center
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    if isCenterPosition(BanqiPosition(column: col, row: row)) {
                        score += 0.2
                    }
                }
            }
        }
        
        return score
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
