//
//  ExpertAI.swift
//  ChineseChase
//
//  Expert AI implementation for single player mode
//

import Foundation
import GameplayKit

/// Expert AI that uses maximum search depth with advanced strategic evaluation
public class ExpertAI: BanqiAIEngine {
    
    public override init(name: String = "Expert AI", randomSource: GKRandomSource = GKRandomSource.sharedRandom()) {
        super.init(name: name, randomSource: randomSource)
    }
    
    public override func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        
        guard !legalMoves.isEmpty else {
            // No legal moves available
            return .flip(at: BanqiPosition(column: 0, row: 0)) // Fallback
        }
        
        // For expert AI, use maximum search depth
        let searchDepth = difficulty.searchDepth
        let timeLimit = difficulty.maxThinkingTime
        
        // Use iterative deepening search with time limit
        if let bestMove = SearchEngine.iterativeDeepeningSearch(game: game, maxDepth: searchDepth, timeLimit: timeLimit) {
            return bestMove
        }
        
        // Fallback to advanced AI logic if search fails
        return fallbackMoveSelection(for: game, from: legalMoves)
    }
    
    public override func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double {
        // Expert position evaluation
        var score = PositionEvaluator.evaluatePosition(game, for: player)
        
        // Add expert strategic considerations
        score += evaluateExpertStrategicFactors(game: game, for: player)
        
        return score
    }
    
    // MARK: - Private Helper Methods
    
    /// Fallback move selection using advanced AI logic
    private func fallbackMoveSelection(for game: BanqiGame, from legalMoves: [BanqiAction]) -> BanqiAction {
        // Use advanced AI logic as fallback
        let advancedAI = AdvancedAI()
        return advancedAI.selectMove(for: game, difficulty: .advanced)
    }
    
    /// Evaluates expert strategic factors for the position
    private func evaluateExpertStrategicFactors(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Expert king safety evaluation
        score += evaluateExpertKingSafety(game: game, for: player)
        
        // Expert development evaluation
        score += evaluateExpertDevelopment(game: game, for: player)
        
        // Advanced control of key squares
        score += evaluateAdvancedKeySquareControl(game: game, for: player)
        
        // Advanced pawn structure evaluation
        score += evaluateAdvancedPawnStructure(game: game, for: player)
        
        // Advanced piece coordination
        score += evaluateAdvancedPieceCoordination(game: game, for: player)
        
        // Opening principles
        score += evaluateOpeningPrinciples(game: game, for: player)
        
        // Endgame evaluation
        score += evaluateEndgameFactors(game: game, for: player)
        
        return score
    }
    
    /// Expert king safety evaluation
    private func evaluateExpertKingSafety(game: BanqiGame, for player: BanqiPieceColor) -> Double {
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
        
        // Advanced king safety evaluation
        score += evaluateKingCastlePosition(kingPos, for: player)
        score += evaluateKingProtection(kingPos, in: game, for: player)
        score += evaluateKingMobility(kingPos, in: game, for: player)
        
        return score
    }
    
    /// Evaluates king castle position
    private func evaluateKingCastlePosition(_ position: BanqiPosition, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Penalty for king being exposed
        if isEdgePosition(position) {
            score -= 1.5
        }
        
        // Bonus for king being in a safe corner
        if isCornerPosition(position) {
            score += 0.5
        }
        
        // Bonus for king being in the center during endgame
        if isCenterPosition(position) {
            score += 0.3
        }
        
        return score
    }
    
    /// Evaluates king protection
    private func evaluateKingProtection(_ position: BanqiPosition, in game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Check for protective pieces around the king
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        for (dx, dy) in directions {
            let adjCol = position.column + dx
            let adjRow = position.row + dy
            
            if adjCol >= 0 && adjCol < BanqiGame.numberOfColumns && 
               adjRow >= 0 && adjRow < BanqiGame.numberOfRows {
                if let piece = game.board[adjRow][adjCol], piece.isFaceUp, piece.color == player {
                    // Bonus for protective pieces
                    score += 0.4
                    
                    // Extra bonus for advisors and elephants (traditional protectors)
                    if piece.type == .advisor || piece.type == .elephant {
                        score += 0.2
                    }
                }
            }
        }
        
        return score
    }
    
    /// Evaluates king mobility
    private func evaluateKingMobility(_ position: BanqiPosition, in game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Count available escape squares
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        for (dx, dy) in directions {
            let newCol = position.column + dx
            let newRow = position.row + dy
            
            if newCol >= 0 && newCol < BanqiGame.numberOfColumns && 
               newRow >= 0 && newRow < BanqiGame.numberOfRows {
                if game.board[newRow][newCol] == nil {
                    // Check if this square is safe
                    if !isPositionUnderThreat(BanqiPosition(column: newCol, row: newRow), in: game) {
                        score += 0.4
                    }
                }
            }
        }
        
        return score
    }
    
    /// Expert development evaluation
    private func evaluateExpertDevelopment(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Advanced development evaluation
        score += evaluatePieceDevelopment(game: game, for: player)
        score += evaluateControlLines(game: game, for: player)
        score += evaluatePieceActivity(game: game, for: player)
        
        return score
    }
    
    /// Evaluates piece development
    private func evaluatePieceDevelopment(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    let position = BanqiPosition(column: col, row: row)
                    
                    // Bonus for pieces being developed
                    if isPieceDeveloped(piece, at: position, for: player) {
                        score += 0.2
                    }
                    
                    // Bonus for pieces in optimal positions
                    score += evaluateOptimalPosition(piece, at: position)
                }
            }
        }
        
        return score
    }
    
    /// Checks if a piece is developed
    private func isPieceDeveloped(_ piece: BanqiPiece, at position: BanqiPosition, for player: BanqiPieceColor) -> Bool {
        if piece.color == .red {
            return position.row > 0
        } else {
            return position.row < 7
        }
    }
    
    /// Evaluates if a piece is in an optimal position
    private func evaluateOptimalPosition(_ piece: BanqiPiece, at position: BanqiPosition) -> Double {
        var score = 0.0
        
        switch piece.type {
        case .general:
            // General prefers center during endgame, safe position during opening
            if isCenterPosition(position) {
                score += 0.3
            }
        case .advisor:
            // Advisors prefer to stay near the general
            score += 0.1
        case .elephant:
            // Elephants prefer center positions
            if isCenterPosition(position) {
                score += 0.2
            }
        case .chariot:
            // Chariots prefer open files and ranks
            score += evaluateChariotPosition(position)
        case .horse:
            // Horses prefer center positions
            if isCenterPosition(position) {
                score += 0.2
            }
        case .cannon:
            // Cannons prefer positions with good firing lines
            score += evaluateCannonPosition(position)
        case .soldier:
            // Soldiers prefer advanced positions
            score += evaluateSoldierPosition(position, for: piece.color)
        }
        
        return score
    }
    
    /// Evaluates chariot position
    private func evaluateChariotPosition(_ position: BanqiPosition) -> Double {
        var score = 0.0
        
        // Bonus for being on open files/ranks
        if position.column == 1 || position.column == 2 {
            score += 0.2
        }
        
        if position.row == 3 || position.row == 4 {
            score += 0.2
        }
        
        return score
    }
    
    /// Evaluates cannon position
    private func evaluateCannonPosition(_ position: BanqiPosition) -> Double {
        var score = 0.0
        
        // Cannons prefer positions with good firing lines
        if isCenterPosition(position) {
            score += 0.3
        }
        
        return score
    }
    
    /// Evaluates soldier position
    private func evaluateSoldierPosition(_ position: BanqiPosition, for color: BanqiPieceColor) -> Double {
        var score = 0.0
        
        if color == .red {
            // Red soldiers prefer advanced positions
            if position.row > 3 {
                score += 0.2
            }
        } else {
            // Black soldiers prefer advanced positions
            if position.row < 4 {
                score += 0.2
            }
        }
        
        return score
    }
    
    /// Evaluates control of lines (files and ranks)
    private func evaluateControlLines(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Evaluate control of center files
        for col in [1, 2] {
            score += evaluateFileControl(col, in: game, for: player)
        }
        
        // Evaluate control of center ranks
        for row in [3, 4] {
            score += evaluateRankControl(row, in: game, for: player)
        }
        
        return score
    }
    
    /// Evaluates control of a file
    private func evaluateFileControl(_ column: Int, in game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        var playerPieces = 0
        var enemyPieces = 0
        
        for row in 0..<BanqiGame.numberOfRows {
            if let piece = game.board[row][column], piece.isFaceUp {
                if piece.color == player {
                    playerPieces += 1
                } else {
                    enemyPieces += 1
                }
            }
        }
        
        if playerPieces > enemyPieces {
            score += 0.3
        } else if enemyPieces > playerPieces {
            score -= 0.3
        }
        
        return score
    }
    
    /// Evaluates control of a rank
    private func evaluateRankControl(_ row: Int, in game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        var playerPieces = 0
        var enemyPieces = 0
        
        for col in 0..<BanqiGame.numberOfColumns {
            if let piece = game.board[row][col], piece.isFaceUp {
                if piece.color == player {
                    playerPieces += 1
                } else {
                    enemyPieces += 1
                }
            }
        }
        
        if playerPieces > enemyPieces {
            score += 0.3
        } else if enemyPieces > playerPieces {
            score -= 0.3
        }
        
        return score
    }
    
    /// Evaluates piece activity
    private func evaluatePieceActivity(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    let position = BanqiPosition(column: col, row: row)
                    let legalMoves = game.legalMovesAndCaptures(for: piece, at: position)
                    
                    // Bonus for active pieces
                    score += Double(legalMoves.count) * 0.05
                }
            }
        }
        
        return score
    }
    
    /// Advanced key square control evaluation
    private func evaluateAdvancedKeySquareControl(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Define advanced key squares
        let keySquares = [
            BanqiPosition(column: 1, row: 3), BanqiPosition(column: 2, row: 3),
            BanqiPosition(column: 1, row: 4), BanqiPosition(column: 2, row: 4),
            BanqiPosition(column: 0, row: 3), BanqiPosition(column: 3, row: 3),
            BanqiPosition(column: 0, row: 4), BanqiPosition(column: 3, row: 4)
        ]
        
        for square in keySquares {
            if let piece = game.board[square.row][square.column], piece.isFaceUp {
                if piece.color == player {
                    score += 0.3 // Own piece on key square
                } else {
                    score -= 0.3 // Enemy piece on key square
                }
            }
        }
        
        return score
    }
    
    /// Advanced pawn structure evaluation
    private func evaluateAdvancedPawnStructure(game: BanqiGame, for player: BanqiPieceColor) -> Double {
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
        
        // Advanced soldier structure evaluation
        for soldier in soldierPositions {
            score += evaluateAdvancedSoldierPosition(soldier, in: soldierPositions, for: player)
        }
        
        return score
    }
    
    /// Evaluates advanced soldier position
    private func evaluateAdvancedSoldierPosition(_ position: BanqiPosition, in soldierPositions: [BanqiPosition], for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Bonus for advanced soldiers
        if player == .red && position.row > 3 {
            score += 0.2
        } else if player == .black && position.row < 4 {
            score += 0.2
        }
        
        // Bonus for connected soldiers
        if hasConnectedSoldiers(at: position, in: soldierPositions) {
            score += 0.1
        }
        
        // Bonus for isolated soldiers (sometimes good for flexibility)
        if isIsolatedSoldier(at: position, in: soldierPositions) {
            score += 0.05
        }
        
        return score
    }
    
    /// Checks if a soldier is isolated
    private func isIsolatedSoldier(at position: BanqiPosition, in soldierPositions: [BanqiPosition]) -> Bool {
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        for (dx, dy) in directions {
            let adjCol = position.column + dx
            let adjRow = position.row + dy
            let adjPos = BanqiPosition(column: adjCol, row: adjRow)
            
            if soldierPositions.contains(adjPos) {
                return false
            }
        }
        
        return true
    }
    
    /// Advanced piece coordination evaluation
    private func evaluateAdvancedPieceCoordination(game: BanqiGame, for player: BanqiPieceColor) -> Double {
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
        
        // Advanced coordination evaluation
        for i in 0..<piecePositions.count {
            for j in (i+1)..<piecePositions.count {
                let pos1 = piecePositions[i]
                let pos2 = piecePositions[j]
                
                score += evaluateAdvancedPieceCoordination(pos1: pos1, pos2: pos2, in: game)
            }
        }
        
        return score
    }
    
    /// Evaluates advanced piece coordination
    private func evaluateAdvancedPieceCoordination(pos1: BanqiPosition, pos2: BanqiPosition, in game: BanqiGame) -> Double {
        var score = 0.0
        
        // Check if pieces can support each other
        if canPiecesSupportEachOther(pos1: pos1, pos2: pos2, in: game) {
            score += 0.15
        }
        
        // Check for fork opportunities
        if canCreateFork(pos1: pos1, pos2: pos2, in: game) {
            score += 0.2
        }
        
        // Check for pin opportunities
        if canCreatePin(pos1: pos1, pos2: pos2, in: game) {
            score += 0.15
        }
        
        return score
    }
    
    /// Checks if pieces can create a fork
    private func canCreateFork(pos1: BanqiPosition, pos2: BanqiPosition, in game: BanqiGame) -> Bool {
        // Simplified fork detection
        let distance = abs(pos1.column - pos2.column) + abs(pos1.row - pos2.row)
        return distance <= 3
    }
    
    /// Checks if pieces can create a pin
    private func canCreatePin(pos1: BanqiPosition, pos2: BanqiPosition, in game: BanqiGame) -> Bool {
        // Simplified pin detection
        let distance = abs(pos1.column - pos2.column) + abs(pos1.row - pos2.row)
        return distance <= 2
    }
    
    /// Evaluates opening principles
    private func evaluateOpeningPrinciples(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Bonus for controlling the center
        score += evaluateCenterControl(game: game, for: player)
        
        // Bonus for developing pieces
        score += evaluateDevelopmentSpeed(game: game, for: player)
        
        // Bonus for king safety
        score += evaluateOpeningKingSafety(game: game, for: player)
        
        return score
    }
    
    /// Evaluates center control
    private func evaluateCenterControl(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        let centerSquares = [
            BanqiPosition(column: 1, row: 3), BanqiPosition(column: 2, row: 3),
            BanqiPosition(column: 1, row: 4), BanqiPosition(column: 2, row: 4)
        ]
        
        for square in centerSquares {
            if let piece = game.board[square.row][square.column], piece.isFaceUp {
                if piece.color == player {
                    score += 0.4
                } else {
                    score -= 0.4
                }
            }
        }
        
        return score
    }
    
    /// Evaluates development speed
    private func evaluateDevelopmentSpeed(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        var developedPieces = 0
        var totalPieces = 0
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    totalPieces += 1
                    if isPieceDeveloped(piece, at: BanqiPosition(column: col, row: row), for: player) {
                        developedPieces += 1
                    }
                }
            }
        }
        
        if totalPieces > 0 {
            score += Double(developedPieces) / Double(totalPieces) * 0.5
        }
        
        return score
    }
    
    /// Evaluates opening king safety
    private func evaluateOpeningKingSafety(game: BanqiGame, for player: BanqiPieceColor) -> Double {
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
        
        // Bonus for king being in a safe position during opening
        if !isEdgePosition(kingPos) {
            score += 0.3
        }
        
        return score
    }
    
    /// Evaluates endgame factors
    private func evaluateEndgameFactors(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Check if we're in endgame (few pieces remaining)
        let totalPieces = countTotalPieces(in: game)
        if totalPieces <= 8 {
            score += evaluateEndgamePosition(game: game, for: player)
        }
        
        return score
    }
    
    /// Counts total pieces on the board
    private func countTotalPieces(in game: BanqiGame) -> Int {
        var count = 0
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp {
                    count += 1
                }
            }
        }
        return count
    }
    
    /// Evaluates endgame position
    private func evaluateEndgamePosition(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // In endgame, king activity becomes more important
        if let kingPos = findKingPosition(in: game, for: player) {
            if isCenterPosition(kingPos) {
                score += 0.5
            }
        }
        
        return score
    }
    
    /// Finds king position
    private func findKingPosition(in game: BanqiGame, for player: BanqiPieceColor) -> BanqiPosition? {
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.type == .general, piece.color == player {
                    return BanqiPosition(column: col, row: row)
                }
            }
        }
        return nil
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
    
    /// Checks if a position is in a corner
    private func isCornerPosition(_ position: BanqiPosition) -> Bool {
        return (position.column == 0 || position.column == 3) && (position.row == 0 || position.row == 7)
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
}
