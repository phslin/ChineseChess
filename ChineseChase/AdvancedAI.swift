//
//  AdvancedAI.swift
//  ChineseChase
//
//  Advanced AI implementation for single player mode
//

import Foundation
import GameplayKit

/// Advanced AI that uses 4-6 ply search with enhanced strategic evaluation
public class AdvancedAI: BanqiAIEngine {
    
    public override init(name: String = "Advanced AI", randomSource: GKRandomSource = GKRandomSource.sharedRandom()) {
        super.init(name: name, randomSource: randomSource)
    }
    
    public override func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        
        guard !legalMoves.isEmpty else {
            // No legal moves available
            return .flip(at: BanqiPosition(column: 0, row: 0)) // Fallback
        }
        
        // For advanced AI, use 4-6 ply search
        let searchDepth = min(difficulty.searchDepth, 6)
        let timeLimit = difficulty.maxThinkingTime
        
        // Use iterative deepening search with time limit
        if let bestMove = SearchEngine.iterativeDeepeningSearch(game: game, maxDepth: searchDepth, timeLimit: timeLimit) {
            return bestMove
        }
        
        // Fallback to intermediate AI logic if search fails
        return fallbackMoveSelection(for: game, from: legalMoves)
    }
    
    public override func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double {
        // Advanced position evaluation
        var score = PositionEvaluator.evaluatePosition(game, for: player)
        
        // Add advanced strategic considerations
        score += evaluateAdvancedStrategicFactors(game: game, for: player)
        
        return score
    }
    
    // MARK: - Private Helper Methods
    
    /// Fallback move selection using intermediate AI logic
    private func fallbackMoveSelection(for game: BanqiGame, from legalMoves: [BanqiAction]) -> BanqiAction {
        // Use intermediate AI logic as fallback
        let intermediateAI = IntermediateAI()
        return intermediateAI.selectMove(for: game, difficulty: .intermediate)
    }
    
    /// Evaluates advanced strategic factors for the position
    private func evaluateAdvancedStrategicFactors(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Advanced king safety evaluation
        score += evaluateAdvancedKingSafety(game: game, for: player)
        
        // Advanced development evaluation
        score += evaluateAdvancedDevelopment(game: game, for: player)
        
        // Control of key squares
        score += evaluateKeySquareControl(game: game, for: player)
        
        // Pawn structure evaluation
        score += evaluatePawnStructure(game: game, for: player)
        
        // Piece coordination
        score += evaluatePieceCoordination(game: game, for: player)
        
        return score
    }
    
    /// Advanced king safety evaluation
    private func evaluateAdvancedKingSafety(game: BanqiGame, for player: BanqiPieceColor) -> Double {
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
            score -= 1.0
        }
        
        // Bonus for king being protected
        if hasProtectivePieces(around: kingPos, in: game, for: player) {
            score += 0.5
        }
        
        // Check for king being in check
        if isKingInCheck(game: game, for: player) {
            score -= 2.0
        }
        
        // Evaluate escape squares
        score += evaluateKingEscapeSquares(around: kingPos, in: game, for: player)
        
        return score
    }
    
    /// Checks if the king is in check
    private func isKingInCheck(game: BanqiGame, for player: BanqiPieceColor) -> Bool {
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
        
        guard let kingPos = kingPosition else { return false }
        
        // Check if any opponent piece can capture the king
        let opponent = player.opponent
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == opponent {
                    let fromPos = BanqiPosition(column: col, row: row)
                    let legalMoves = game.legalMovesAndCaptures(for: piece, at: fromPos)
                    
                    for move in legalMoves {
                        if case .capture(_, let to) = move, to == kingPos {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    /// Evaluates king escape squares
    private func evaluateKingEscapeSquares(around position: BanqiPosition, in game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        for (dx, dy) in directions {
            let newCol = position.column + dx
            let newRow = position.row + dy
            
            if newCol >= 0 && newCol < BanqiGame.numberOfColumns && 
               newRow >= 0 && newRow < BanqiGame.numberOfRows {
                if game.board[newRow][newCol] == nil {
                    // Check if this square is safe
                    if !isPositionUnderThreat(BanqiPosition(column: newCol, row: newRow), in: game) {
                        score += 0.3
                    }
                }
            }
        }
        
        return score
    }
    
    /// Advanced development evaluation
    private func evaluateAdvancedDevelopment(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Bonus for having pieces in the center
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    if isCenterPosition(BanqiPosition(column: col, row: row)) {
                        score += 0.3
                    }
                    
                    // Bonus for pieces being developed (not on back rank)
                    if piece.color == .red && row > 0 {
                        score += 0.1
                    } else if piece.color == .black && row < 7 {
                        score += 0.1
                    }
                }
            }
        }
        
        return score
    }
    
    /// Evaluates control of key squares
    private func evaluateKeySquareControl(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Define key squares (center and strategic positions)
        let keySquares = [
            BanqiPosition(column: 1, row: 3), BanqiPosition(column: 2, row: 3),
            BanqiPosition(column: 1, row: 4), BanqiPosition(column: 2, row: 4)
        ]
        
        for square in keySquares {
            if let piece = game.board[square.row][square.column], piece.isFaceUp {
                if piece.color == player {
                    score += 0.2 // Own piece on key square
                } else {
                    score -= 0.2 // Enemy piece on key square
                }
            }
        }
        
        return score
    }
    
    /// Evaluates pawn structure
    private func evaluatePawnStructure(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Find all soldiers of the player
        var soldierPositions: [BanqiPosition] = []
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.type == .soldier, piece.color == player {
                    soldierPositions.append(BanqiPosition(column: col, row: row))
                }
            }
        }
        
        // Evaluate soldier structure
        for soldier in soldierPositions {
            // Bonus for advanced soldiers
            if player == .red && soldier.row > 3 {
                score += 0.1
            } else if player == .black && soldier.row < 4 {
                score += 0.1
            }
            
            // Bonus for connected soldiers
            if hasConnectedSoldiers(at: soldier, in: soldierPositions) {
                score += 0.05
            }
        }
        
        return score
    }
    
    /// Checks if a soldier has connected soldiers
    private func hasConnectedSoldiers(at position: BanqiPosition, in soldierPositions: [BanqiPosition]) -> Bool {
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        for (dx, dy) in directions {
            let adjCol = position.column + dx
            let adjRow = position.row + dy
            let adjPos = BanqiPosition(column: adjCol, row: adjRow)
            
            if soldierPositions.contains(adjPos) {
                return true
            }
        }
        
        return false
    }
    
    /// Evaluates piece coordination
    private func evaluatePieceCoordination(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Find all pieces of the player
        var piecePositions: [BanqiPosition] = []
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    piecePositions.append(BanqiPosition(column: col, row: row))
                }
            }
        }
        
        // Evaluate coordination between pieces
        for i in 0..<piecePositions.count {
            for j in (i+1)..<piecePositions.count {
                let pos1 = piecePositions[i]
                let pos2 = piecePositions[j]
                
                // Bonus for pieces that can support each other
                if canPiecesSupportEachOther(pos1: pos1, pos2: pos2, in: game) {
                    score += 0.1
                }
            }
        }
        
        return score
    }
    
    /// Checks if two pieces can support each other
    private func canPiecesSupportEachOther(pos1: BanqiPosition, pos2: BanqiPosition, in game: BanqiGame) -> Bool {
        // Check if pieces are close enough to support each other
        let distance = abs(pos1.column - pos2.column) + abs(pos1.row - pos2.row)
        
        if distance <= 2 {
            // Check if they can attack the same squares
            if let piece1 = game.board[pos1.row][pos1.column],
               let piece2 = game.board[pos2.row][pos2.column] {
                
                let moves1 = game.legalMovesAndCaptures(for: piece1, at: pos1)
                let moves2 = game.legalMovesAndCaptures(for: piece2, at: pos2)
                
                // Check for overlapping attack squares
                for move1 in moves1 {
                    if case .capture(_, let to1) = move1 {
                        for move2 in moves2 {
                            if case .capture(_, let to2) = move2 {
                                if to1 == to2 {
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return false
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
    
    /// Checks if there are protective pieces around a position
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
}
