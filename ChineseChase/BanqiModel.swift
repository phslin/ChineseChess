//
//  BanqiModel.swift
//  ChineseChase
//
//  Core rules, board state, and legal move generation for Banqi (Dark Chess).
//

import Foundation
import GameplayKit

public enum BanqiPieceColor: String, Codable, CaseIterable {
    case red
    case black

    public var opponent: BanqiPieceColor {
        return self == .red ? .black : .red
    }
}

public enum BanqiPieceType: Int, Codable, CaseIterable {
    case general = 6
    case advisor = 5
    case elephant = 4
    case chariot = 3
    case horse = 2
    case cannon = 1
    case soldier = 0

    public var rank: Int { rawValue }
    
    public var symbol: String {
        switch self {
        case .general: return "帥"
        case .advisor: return "仕"
        case .elephant: return "相"
        case .chariot: return "俥"
        case .horse: return "傌"
        case .cannon: return "炮"
        case .soldier: return "兵"
        }
    }
}

public struct BanqiPiece: Codable, Equatable {
    public let color: BanqiPieceColor
    public let type: BanqiPieceType
    public var isFaceUp: Bool
}

public struct BanqiPosition: Hashable, Codable {
    public let column: Int
    public let row: Int
}

public enum BanqiAction: Equatable {
    case flip(at: BanqiPosition)
    case move(from: BanqiPosition, to: BanqiPosition)
    case capture(from: BanqiPosition, to: BanqiPosition)
}

public final class BanqiGame {
    public static let numberOfColumns: Int = 4
    public static let numberOfRows: Int = 8

    public var board: [[BanqiPiece?]] // [row][column]
    public var sideToMove: BanqiPieceColor? // nil until first flip determines colors
    public var gameOver: Bool = false
    public var winner: BanqiPieceColor?
    public var lastAction: BanqiAction?

    private var randomSource: GKRandomSource

    public init(seed: UInt64? = nil) {
        if let seed = seed {
            let seeded = GKARC4RandomSource(seed: dataFromSeed(seed))
            seeded.dropValues(1024)
            self.randomSource = seeded
        } else {
            // Use a more random seed based on current time and random data
            let randomSeed = UInt64(Date().timeIntervalSince1970 * 1000000) ^ UInt64.random(in: 0...UInt64.max)
            let seeded = GKARC4RandomSource(seed: dataFromSeed(randomSeed))
            seeded.dropValues(2048) // Drop more values for better randomness
            self.randomSource = seeded
        }
        self.board = Array(repeating: Array(repeating: nil, count: BanqiGame.numberOfColumns), count: BanqiGame.numberOfRows)
        self.sideToMove = nil
        dealNewGame()
    }

    public func reset(seed: UInt64? = nil) {
        if let seed = seed {
            let seeded = GKARC4RandomSource(seed: dataFromSeed(seed))
            seeded.dropValues(1024)
            self.randomSource = seeded
        } else {
            self.randomSource = GKRandomSource.sharedRandom()
        }
        self.board = Array(repeating: Array(repeating: nil, count: BanqiGame.numberOfColumns), count: BanqiGame.numberOfRows)
        self.gameOver = false
        self.winner = nil
        self.sideToMove = nil
        dealNewGame()
    }

    // MARK: - Setup

    private func dealNewGame() {
        var deck: [BanqiPiece] = []
        for color in [BanqiPieceColor.red, .black] {
            deck.append(BanqiPiece(color: color, type: .general, isFaceUp: false))
            deck.append(contentsOf: Array(repeating: BanqiPiece(color: color, type: .advisor, isFaceUp: false), count: 2))
            deck.append(contentsOf: Array(repeating: BanqiPiece(color: color, type: .elephant, isFaceUp: false), count: 2))
            deck.append(contentsOf: Array(repeating: BanqiPiece(color: color, type: .chariot, isFaceUp: false), count: 2))
            deck.append(contentsOf: Array(repeating: BanqiPiece(color: color, type: .horse, isFaceUp: false), count: 2))
            deck.append(contentsOf: Array(repeating: BanqiPiece(color: color, type: .cannon, isFaceUp: false), count: 2))
            deck.append(contentsOf: Array(repeating: BanqiPiece(color: color, type: .soldier, isFaceUp: false), count: 5))
        }

        // Shuffle
        deck = shuffled(deck)

        // Deal 4x8 row-major
        var index = 0
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                board[row][col] = deck[index]
                index += 1
            }
        }
    }

    private func shuffled<T>(_ array: [T]) -> [T] {
        guard array.count > 1 else { return array }
        var copy = array
        for i in stride(from: copy.count - 1, through: 1, by: -1) {
            let j = randomSource.nextInt(upperBound: i + 1)
            if i != j { copy.swapAt(i, j) }
        }
        return copy
    }

    // MARK: - Queries

    public func piece(at position: BanqiPosition) -> BanqiPiece? {
        guard isInsideBoard(position) else { return nil }
        return board[position.row][position.column]
    }

    public func isInsideBoard(_ position: BanqiPosition) -> Bool {
        return position.column >= 0 && position.column < BanqiGame.numberOfColumns && position.row >= 0 && position.row < BanqiGame.numberOfRows
    }

    public func hasAnyFaceDownPiece() -> Bool {
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = board[row][col], piece.isFaceUp == false { return true }
            }
        }
        return false
    }

    // MARK: - Legal Actions

    public func legalActionsForSideToMove() -> [BanqiAction] {
        if gameOver { return [] }
        // First turn: only flips allowed
        if sideToMove == nil {
            return allFlips()
        }
        var actions: [BanqiAction] = []
        actions.append(contentsOf: allFlips())
        actions.append(contentsOf: allMovesAndCaptures(for: sideToMove!))
        return actions
    }

    private func allFlips() -> [BanqiAction] {
        var actions: [BanqiAction] = []
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                if let piece = board[row][col], piece.isFaceUp == false {
                    actions.append(.flip(at: BanqiPosition(column: col, row: row)))
                }
            }
        }
        return actions
    }

    private func allMovesAndCaptures(for color: BanqiPieceColor) -> [BanqiAction] {
        var actions: [BanqiAction] = []
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                let pos = BanqiPosition(column: col, row: row)
                guard let piece = board[row][col], piece.isFaceUp, piece.color == color else { continue }
                actions.append(contentsOf: legalMovesAndCaptures(for: piece, at: pos))
            }
        }
        return actions
    }

    public func legalMovesAndCaptures(for piece: BanqiPiece, at position: BanqiPosition) -> [BanqiAction] {
        var actions: [BanqiAction] = []
        let deltas = [ (1, 0), (-1, 0), (0, 1), (0, -1) ]

        if piece.type == .cannon {
            // Non-capturing step: 1 orthogonal into empty
            for (dx, dy) in deltas {
                let to = BanqiPosition(column: position.column + dx, row: position.row + dy)
                if isInsideBoard(to), board[to.row][to.column] == nil {
                    actions.append(.move(from: position, to: to))
                }
            }
            // Captures: ray with exactly one intervening piece, target must be opponent and face-up
            for (dx, dy) in deltas {
                var screens = 0
                var c = position.column + dx
                var r = position.row + dy
                while c >= 0 && c < BanqiGame.numberOfColumns && r >= 0 && r < BanqiGame.numberOfRows {
                    if let target = board[r][c] {
                        if screens == 0 {
                            screens = 1
                        } else if screens == 1 {
                            if target.isFaceUp && target.color != piece.color {
                                actions.append(.capture(from: position, to: BanqiPosition(column: c, row: r)))
                            }
                            break
                        }
                    }
                    c += dx
                    r += dy
                }
            }
            return actions
        }

        // Non-cannon pieces: step 1 orthogonal into empty
        for (dx, dy) in deltas {
            let to = BanqiPosition(column: position.column + dx, row: position.row + dy)
            guard isInsideBoard(to) else { continue }
            if board[to.row][to.column] == nil {
                actions.append(.move(from: position, to: to))
            } else if let target = board[to.row][to.column], target.isFaceUp, target.color != piece.color {
                if canCapture(attacker: piece, target: target) {
                    actions.append(.capture(from: position, to: to))
                }
            }
        }
        return actions
    }

    private func canCapture(attacker: BanqiPiece, target: BanqiPiece) -> Bool {
        // Soldier captures General; General cannot capture Soldier
        if attacker.type == .soldier && target.type == .general { return true }
        if attacker.type == .general && target.type == .soldier { return false }
        return attacker.type.rank >= target.type.rank
    }

    // MARK: - Apply Action

    @discardableResult
    public func perform(_ action: BanqiAction) -> Bool {
        guard !gameOver else { return false }
        switch action {
        case .flip(let at):
            guard isInsideBoard(at), var piece = board[at.row][at.column], piece.isFaceUp == false else { return false }
            piece.isFaceUp = true
            board[at.row][at.column] = piece
            lastAction = action
            // First flip determines colors; next to move is the opponent
            if sideToMove == nil {
                sideToMove = piece.color.opponent
            } else {
                sideToMove = sideToMove?.opponent
            }
            evaluateGameEnd()
            return true
        case .move(let from, let to):
            guard sideToMove != nil else { return false }
            guard isInsideBoard(from), isInsideBoard(to) else { return false }
            guard let moving = board[from.row][from.column], moving.isFaceUp else { return false }
            if let stm = sideToMove, stm != moving.color { return false }
            guard board[to.row][to.column] == nil else { return false }
            // Validate is a legal step
            let legal = legalMovesAndCaptures(for: moving, at: from).contains { candidate in
                if case .move(let f, let t) = candidate { return f == from && t == to } else { return false }
            }
            guard legal else { return false }
            board[from.row][from.column] = nil
            board[to.row][to.column] = moving
            lastAction = action
            sideToMove = sideToMove?.opponent
            evaluateGameEnd()
            return true
        case .capture(let from, let to):
            guard sideToMove != nil else { return false }
            guard isInsideBoard(from), isInsideBoard(to) else { return false }
            guard let moving = board[from.row][from.column], moving.isFaceUp else { return false }
            if let stm = sideToMove, stm != moving.color { return false }
            guard let target = board[to.row][to.column], target.isFaceUp, target.color != moving.color else { return false }
            // Validate is a legal capture
            let legal = legalMovesAndCaptures(for: moving, at: from).contains { candidate in
                if case .capture(let f, let t) = candidate { return f == from && t == to } else { return false }
            }
            guard legal else { return false }
            board[from.row][from.column] = nil
            board[to.row][to.column] = moving
            lastAction = action
            sideToMove = sideToMove?.opponent
            evaluateGameEnd()
            return true
        }
    }

    private func evaluateGameEnd() {
        guard let stm = sideToMove else { return }
        if hasAnyFaceDownPiece() { return } // flips remain; game continues
        // No flips remain; check if side to move has any legal moves/captures
        if allMovesAndCaptures(for: stm).isEmpty {
            gameOver = true
            winner = stm.opponent
        }
    }

    // Get captured pieces for a specific side
    public func capturedPieces(for side: BanqiPieceColor) -> [BanqiPieceType] {
        var captured: [BanqiPieceType] = []
        
        // Expected piece counts for each side in Banqi
        let expectedCounts: [BanqiPieceType: Int] = [
            .general: 1,
            .advisor: 2,
            .elephant: 2,
            .chariot: 2,
            .horse: 2,
            .cannon: 2,
            .soldier: 5
        ]
        
        for (pieceType, expectedCount) in expectedCounts {
            var actualCount = 0
            for row in 0..<BanqiGame.numberOfRows {
                for col in 0..<BanqiGame.numberOfColumns {
                    if let piece = board[row][col], piece.color == side, piece.type == pieceType {
                        actualCount += 1
                    }
                }
            }
            
            // Add missing pieces to captured list
            let missing = expectedCount - actualCount
            for _ in 0..<missing {
                captured.append(pieceType)
            }
        }
        
        return captured
    }
}

// MARK: - Helpers

private func dataFromSeed(_ value: UInt64) -> Data {
    withUnsafeBytes(of: value) { Data($0) }
}


