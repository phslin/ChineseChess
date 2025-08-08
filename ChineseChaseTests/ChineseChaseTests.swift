//
//  ChineseChaseTests.swift
//  ChineseChaseTests
//
//  Created by Benson Lin on 8/7/25.
//

import Testing
@testable import ChineseChase

struct ChineseChaseTests {

    @Test func testCannonCaptureBasic() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a cannon with one screen and one target
        game.board[0][0] = BanqiPiece(color: .red, type: .cannon, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true) // screen
        game.board[0][2] = BanqiPiece(color: .black, type: .general, isFaceUp: true) // target
        
        let cannon = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: cannon, at: BanqiPosition(column: 0, row: 0))
        
        // Should be able to capture the general
        let captureAction = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 2, row: 0)
            }
            return false
        }
        
        #expect(captureAction != nil)
    }
    
    @Test func testCannonCaptureMultipleScreens() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a cannon with multiple screens
        game.board[0][0] = BanqiPiece(color: .red, type: .cannon, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true) // screen 1
        game.board[0][2] = BanqiPiece(color: .black, type: .advisor, isFaceUp: true) // screen 2
        game.board[0][3] = BanqiPiece(color: .black, type: .general, isFaceUp: true) // target
        
        let cannon = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: cannon, at: BanqiPosition(column: 0, row: 0))
        
        // Should NOT be able to capture the general (too many screens)
        let captureAction = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 3, row: 0)
            }
            return false
        }
        
        #expect(captureAction == nil)
    }
    
    @Test func testCannonCaptureFaceDownScreen() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a cannon with face-down screen
        game.board[0][0] = BanqiPiece(color: .red, type: .cannon, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .soldier, isFaceUp: false) // face-down screen
        game.board[0][2] = BanqiPiece(color: .black, type: .general, isFaceUp: true) // target
        
        let cannon = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: cannon, at: BanqiPosition(column: 0, row: 0))
        
        // Should NOT be able to capture (face-down screen doesn't count)
        let captureAction = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 2, row: 0)
            }
            return false
        }
        
        #expect(captureAction == nil)
    }
    
    @Test func testCannonCaptureFaceDownTarget() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a cannon with face-down target
        game.board[0][0] = BanqiPiece(color: .red, type: .cannon, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true) // screen
        game.board[0][2] = BanqiPiece(color: .black, type: .general, isFaceUp: false) // face-down target
        
        let cannon = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: cannon, at: BanqiPosition(column: 0, row: 0))
        
        // Should NOT be able to capture (face-down target)
        let captureAction = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 2, row: 0)
            }
            return false
        }
        
        #expect(captureAction == nil)
    }
    
    @Test func testCannonCaptureSameColorTarget() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a cannon with same-color target
        game.board[0][0] = BanqiPiece(color: .red, type: .cannon, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true) // screen
        game.board[0][2] = BanqiPiece(color: .red, type: .general, isFaceUp: true) // same-color target
        
        let cannon = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: cannon, at: BanqiPosition(column: 0, row: 0))
        
        // Should NOT be able to capture (same color)
        let captureAction = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 2, row: 0)
            }
            return false
        }
        
        #expect(captureAction == nil)
    }
    
    @Test func testCannonMoveWithoutScreen() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a cannon with no screen
        game.board[0][0] = BanqiPiece(color: .red, type: .cannon, isFaceUp: true)
        game.board[0][2] = BanqiPiece(color: .black, type: .general, isFaceUp: true) // target without screen
        
        let cannon = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: cannon, at: BanqiPosition(column: 0, row: 0))
        
        // Should be able to move to empty squares
        let moveAction = actions.first { action in
            if case .move(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 1, row: 0)
            }
            return false
        }
        
        #expect(moveAction != nil)
        
        // Should NOT be able to capture (no screen)
        let captureAction = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 2, row: 0)
            }
            return false
        }
        
        #expect(captureAction == nil)
    }
    
    @Test func testLegalMovesBasic() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a simple scenario
        game.board[0][0] = BanqiPiece(color: .red, type: .soldier, isFaceUp: true)
        game.sideToMove = .red
        
        let soldier = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: soldier, at: BanqiPosition(column: 0, row: 0))
        
        // Should have 4 possible moves (up, down, left, right)
        #expect(actions.count == 4)
    }
    
    @Test func testCaptureRankRules() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up capture scenarios
        game.board[0][0] = BanqiPiece(color: .red, type: .soldier, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .general, isFaceUp: true)
        game.board[1][0] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true)
        
        let soldier = game.piece(at: BanqiPosition(column: 0, row: 0))!
        let actions = game.legalMovesAndCaptures(for: soldier, at: BanqiPosition(column: 0, row: 0))
        
        // Soldier should be able to capture General
        let captureGeneral = actions.first { action in
            if case .capture(let from, let to) = action {
                return from == BanqiPosition(column: 0, row: 0) && to == BanqiPosition(column: 1, row: 0)
            }
            return false
        }
        
        #expect(captureGeneral != nil)
    }
    
    @Test func testWinDetection() async throws {
        let game = BanqiGame(seed: 12345)
        
        // Set up a scenario where one side has no legal moves
        game.board[0][0] = BanqiPiece(color: .red, type: .general, isFaceUp: true)
        game.board[0][1] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true)
        game.board[0][2] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true)
        game.board[0][3] = BanqiPiece(color: .black, type: .soldier, isFaceUp: true)
        game.sideToMove = .red
        
        // Red should have no legal moves (surrounded)
        let actions = game.legalActionsForSideToMove()
        #expect(actions.isEmpty)
        
        // Game should be over
        game.evaluateGameEnd()
        #expect(game.gameOver == true)
        #expect(game.winner == .black)
    }
    
    @Test func testDeterministicSeeding() async throws {
        let game1 = BanqiGame(seed: 12345)
        let game2 = BanqiGame(seed: 12345)
        
        // Both games should have identical board layouts
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                let pos = BanqiPosition(column: col, row: row)
                let piece1 = game1.piece(at: pos)
                let piece2 = game2.piece(at: pos)
                #expect(piece1?.type == piece2?.type)
                #expect(piece1?.color == piece2?.color)
                #expect(piece1?.isFaceUp == piece2?.isFaceUp)
            }
        }
    }

}
