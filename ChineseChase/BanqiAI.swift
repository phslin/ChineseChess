//
//  BanqiAI.swift
//  ChineseChase
//
//  AI Engine Architecture for Single Player Mode
//

import Foundation
import GameplayKit

// MARK: - AI Protocol

/// Protocol that all AI implementations must conform to
public protocol BanqiAI {
    /// Selects the best move for the AI given the current game state
    /// - Parameters:
    ///   - game: The current Banqi game state
    ///   - difficulty: The AI difficulty level
    /// - Returns: The selected action (flip, move, or capture)
    func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction
    
    /// Evaluates the current position for the given player
    /// - Parameters:
    ///   - game: The current Banqi game state
    ///   - player: The player whose position is being evaluated
    /// - Returns: Position score (positive favors the player, negative favors opponent)
    func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double
    
    /// Gets the name of the AI implementation
    var name: String { get }
}

// MARK: - AI Difficulty Levels

/// Represents different difficulty levels for the AI opponent
public enum AIDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    /// Description of the difficulty level
    public var description: String {
        switch self {
        case .beginner:
            return "Random moves with basic piece awareness"
        case .intermediate:
            return "Strategic thinking with 2-3 move lookahead"
        case .advanced:
            return "Deep search algorithms with opening knowledge"
        case .expert:
            return "Advanced AI with endgame optimization"
        }
    }
    
    /// Search depth for the difficulty level
    public var searchDepth: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 4
        case .expert: return 6
        }
    }
    
    /// Maximum thinking time in seconds
    public var maxThinkingTime: TimeInterval {
        switch self {
        case .beginner: return 0.5
        case .intermediate: return 1.0
        case .advanced: return 1.5
        case .expert: return 2.0
        }
    }
}

// MARK: - Base AI Engine

/// Base class for all AI implementations
public class BanqiAIEngine: BanqiAI {
    public let name: String
    let randomSource: GKRandomSource
    
    public init(name: String, randomSource: GKRandomSource = GKRandomSource.sharedRandom()) {
        self.name = name
        self.randomSource = randomSource
    }
    
    // Default implementation - subclasses should override
    public func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        fatalError("Subclasses must implement selectMove")
    }
    
    // Default implementation - subclasses should override
    public func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double {
        fatalError("Subclasses must implement evaluatePosition")
    }
}

// MARK: - Move Generator

/// Generates legal moves for the current game state
public class MoveGenerator {
    
    /// Generates all legal moves for the current player
    /// - Parameter game: The current Banqi game state
    /// - Returns: Array of all legal actions
    public static func generateLegalMoves(for game: BanqiGame) -> [BanqiAction] {
        var legalMoves: [BanqiAction] = []
        
        // Generate flip moves for face-down pieces
        legalMoves.append(contentsOf: generateFlipMoves(for: game))
        
        // Generate move and capture moves for face-up pieces
        legalMoves.append(contentsOf: generateMoveMoves(for: game))
        
        return legalMoves
    }
    
    /// Generates legal flip moves
    private static func generateFlipMoves(for game: BanqiGame) -> [BanqiAction] {
        var flipMoves: [BanqiAction] = []
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], !piece.isFaceUp {
                    flipMoves.append(.flip(at: BanqiPosition(column: col, row: row)))
                }
            }
        }
        
        return flipMoves
    }
    
    /// Generates legal move and capture moves
    private static func generateMoveMoves(for game: BanqiGame) -> [BanqiAction] {
        var moveMoves: [BanqiAction] = []
        
        guard let currentPlayer = game.sideToMove else { return moveMoves }
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], 
                   piece.isFaceUp, 
                   piece.color == currentPlayer {
                    
                    let fromPosition = BanqiPosition(column: col, row: row)
                    let legalTargets = generateLegalTargets(for: piece, at: fromPosition, in: game)
                    
                    for target in legalTargets {
                        if let targetPiece = game.board[target.row][target.column] {
                            if targetPiece.color != currentPlayer {
                                // Capture move
                                moveMoves.append(.capture(from: fromPosition, to: target))
                            }
                        } else {
                            // Regular move
                            moveMoves.append(.move(from: fromPosition, to: target))
                        }
                    }
                }
            }
        }
        
        return moveMoves
    }
    
    /// Generates legal target positions for a piece
    public static func generateLegalTargets(for piece: BanqiPiece, at position: BanqiPosition, in game: BanqiGame) -> [BanqiPosition] {
        // Use the existing legal moves method from BanqiGame
        let legalActions = game.legalMovesAndCaptures(for: piece, at: position)
        var legalTargets: [BanqiPosition] = []
        
        for action in legalActions {
            switch action {
            case .move(_, let to):
                legalTargets.append(to)
            case .capture(_, let to):
                legalTargets.append(to)
            case .flip:
                break // Flip actions don't have target positions
            }
        }
        
        return legalTargets
    }
    
    /// Checks if a position is valid on the board
    private static func isValidPosition(column: Int, row: Int) -> Bool {
        return column >= 0 && column < BanqiGame.numberOfColumns &&
               row >= 0 && row < BanqiGame.numberOfRows
    }
}

// MARK: - Position Evaluator

/// Evaluates board positions for AI decision making
public class PositionEvaluator {
    
    /// Piece values for evaluation
    private static let pieceValues: [BanqiPieceType: Double] = [
        .general: 9.0,
        .advisor: 2.0,
        .elephant: 2.0,
        .chariot: 9.0,
        .horse: 4.0,
        .cannon: 4.5,
        .soldier: 1.0
    ]
    
    /// Evaluates the current position for the given player
    /// - Parameters:
    ///   - game: The current Banqi game state
    ///   - player: The player whose position is being evaluated
    /// - Returns: Position score (positive favors the player, negative favors opponent)
    public static func evaluatePosition(_ game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Material evaluation
        score += evaluateMaterial(game: game, for: player)
        
        // Position evaluation
        score += evaluatePositionalFactors(game: game, for: player)
        
        // Tactical evaluation
        score += evaluateTacticalFactors(game: game, for: player)
        
        return score
    }
    
    /// Evaluates material balance
    private static func evaluateMaterial(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp {
                    let value = pieceValues[piece.type] ?? 0.0
                    if piece.color == player {
                        score += value
                    } else {
                        score -= value
                    }
                }
            }
        }
        
        return score
    }
    
    /// Evaluates positional factors
    private static func evaluatePositionalFactors(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Center control bonus
        score += evaluateCenterControl(game: game, for: player)
        
        // Piece mobility bonus
        score += evaluatePieceMobility(game: game, for: player)
        
        return score
    }
    
    /// Evaluates center control
    private static func evaluateCenterControl(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        let centerColumns = [1, 2]
        let centerRows = [3, 4]
        
        for row in centerRows {
            for col in centerColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    score += 0.1 // Small bonus for center control
                }
            }
        }
        
        return score
    }
    
    /// Evaluates piece mobility
    private static func evaluatePieceMobility(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    let legalMoves = MoveGenerator.generateLegalTargets(for: piece, at: BanqiPosition(column: col, row: row), in: game)
                    score += Double(legalMoves.count) * 0.05 // Small bonus for each legal move
                }
            }
        }
        
        return score
    }
    
    /// Evaluates tactical factors
    private static func evaluateTacticalFactors(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        // Capture opportunities
        score += evaluateCaptureOpportunities(game: game, for: player)
        
        // King safety
        score += evaluateKingSafety(game: game, for: player)
        
        return score
    }
    
    /// Evaluates capture opportunities
    private static func evaluateCaptureOpportunities(game: BanqiGame, for player: BanqiPieceColor) -> Double {
        var score = 0.0
        
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == player {
                    let legalMoves = MoveGenerator.generateLegalTargets(for: piece, at: BanqiPosition(column: col, row: row), in: game)
                    
                    for target in legalMoves {
                        if let targetPiece = game.board[target.row][target.column], targetPiece.color != player {
                            let captureValue = pieceValues[targetPiece.type] ?? 0.0
                            score += captureValue * 0.1 // Bonus for capture opportunities
                        }
                    }
                }
            }
        }
        
        return score
    }
    
    /// Evaluates king safety
    private static func evaluateKingSafety(game: BanqiGame, for player: BanqiPieceColor) -> Double {
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
        
        // Check if king is under attack
        let opponent = player.opponent
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = game.board[row][col], piece.isFaceUp, piece.color == opponent {
                    let legalMoves = MoveGenerator.generateLegalTargets(for: piece, at: BanqiPosition(column: col, row: row), in: game)
                    if legalMoves.contains(kingPos) {
                        score -= 1.0 // Penalty for king being under attack
                    }
                }
            }
        }
        
        return score
    }
}

// MARK: - Search Engine

/// Base class for AI search algorithms
public class SearchEngine {
    
    /// Performs minimax search with alpha-beta pruning
    /// - Parameters:
    ///   - game: The current game state
    ///   - depth: Search depth
    ///   - alpha: Alpha value for pruning
    ///   - beta: Beta value for pruning
    ///   - maximizingPlayer: Whether the current player is maximizing
    /// - Returns: Best move and score
    public static func minimaxSearch(game: BanqiGame, depth: Int, alpha: Double = -Double.infinity, beta: Double = Double.infinity, maximizingPlayer: Bool) -> (move: BanqiAction?, score: Double) {
        if depth == 0 || game.gameOver {
            let score = PositionEvaluator.evaluatePosition(game, for: game.sideToMove ?? .red)
            return (nil, score)
        }
        
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        if legalMoves.isEmpty {
            return (nil, -Double.infinity) // No moves available
        }
        
        var bestMove: BanqiAction?
        var bestScore = maximizingPlayer ? -Double.infinity : Double.infinity
        var alpha = alpha
        var beta = beta
        
        for move in legalMoves {
            // Create a copy of the game for this search branch
            let gameCopy = BanqiGame()
            gameCopy.board = game.board
            gameCopy.sideToMove = game.sideToMove
            gameCopy.gameOver = game.gameOver
            gameCopy.winner = game.winner
            gameCopy.lastAction = game.lastAction
            
            // Make the move on the copy
            let success = gameCopy.perform(move)
            if !success {
                continue // Skip invalid moves
            }
            
            // Recursive search
            let (_, score) = minimaxSearch(game: gameCopy, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: !maximizingPlayer)
            
            if maximizingPlayer {
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
                alpha = max(alpha, bestScore)
            } else {
                if score < bestScore {
                    bestScore = score
                    bestMove = move
                }
                beta = min(beta, bestScore)
            }
            
            // Alpha-beta pruning
            if alpha >= beta {
                break
            }
        }
        
        return (bestMove, bestScore)
    }
    
    /// Performs iterative deepening search
    /// - Parameters:
    ///   - game: The current game state
    ///   - maxDepth: Maximum search depth
    ///   - timeLimit: Maximum time to spend searching
    /// - Returns: Best move found
    public static func iterativeDeepeningSearch(game: BanqiGame, maxDepth: Int, timeLimit: TimeInterval) -> BanqiAction? {
        let startTime = Date()
        var bestMove: BanqiAction?
        
        for depth in 1...maxDepth {
            let (move, _) = minimaxSearch(game: game, depth: depth, maximizingPlayer: true)
            
            if Date().timeIntervalSince(startTime) > timeLimit {
                break
            }
            
            if let move = move {
                bestMove = move
            }
        }
        
        return bestMove
    }
}
