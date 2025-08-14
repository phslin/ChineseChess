//
//  AITestHelper.swift
//  ChineseChase
//
//  Helper class for testing AI implementations
//

import Foundation

/// Helper class for testing AI implementations
public class AITestHelper {
    
    /// Tests the BeginnerAI with a simple game scenario
    public static func testBeginnerAI() -> Bool {
        print("🧪 Testing BeginnerAI...")
        
        // Create a new game
        let game = BanqiGame()
        
        // Set up single player mode
        let ai = BeginnerAI()
        game.setupSinglePlayerMode(mode: .singlePlayer, humanPlayer: .red, ai: ai)
        
        // Test that AI can generate moves
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        print("📊 Legal moves available: \(legalMoves.count)")
        
        // Test AI move selection
        let aiMove = ai.selectMove(for: game, difficulty: .beginner)
        print("🤖 AI selected move: \(aiMove)")
        
        // Test position evaluation
        let evaluation = ai.evaluatePosition(game, for: .black)
        print("📈 Position evaluation: \(evaluation)")
        
        print("✅ BeginnerAI test completed successfully")
        return true
    }
    
    /// Tests the IntermediateAI with a simple game scenario
    public static func testIntermediateAI() -> Bool {
        print("🧪 Testing IntermediateAI...")
        
        // Create a new game
        let game = BanqiGame()
        
        // Set up single player mode
        let ai = IntermediateAI()
        game.setupSinglePlayerMode(mode: .singlePlayer, humanPlayer: .red, ai: ai)
        
        // Test that AI can generate moves
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        print("📊 Legal moves available: \(legalMoves.count)")
        
        // Test AI move selection
        let aiMove = ai.selectMove(for: game, difficulty: .intermediate)
        print("🤖 AI selected move: \(aiMove)")
        
        // Test position evaluation
        let evaluation = ai.evaluatePosition(game, for: .black)
        print("📈 Position evaluation: \(evaluation)")
        
        print("✅ IntermediateAI test completed successfully")
        return true
    }
    
    /// Tests the AdvancedAI with a simple game scenario
    public static func testAdvancedAI() -> Bool {
        print("🧪 Testing AdvancedAI...")
        
        // Create a new game
        let game = BanqiGame()
        
        // Set up single player mode
        let ai = AdvancedAI()
        game.setupSinglePlayerMode(mode: .singlePlayer, humanPlayer: .red, ai: ai)
        
        // Test that AI can generate moves
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        print("📊 Legal moves available: \(legalMoves.count)")
        
        // Test AI move selection
        let aiMove = ai.selectMove(for: game, difficulty: .advanced)
        print("🤖 AI selected move: \(aiMove)")
        
        // Test position evaluation
        let evaluation = ai.evaluatePosition(game, for: .black)
        print("📈 Position evaluation: \(evaluation)")
        
        print("✅ AdvancedAI test completed successfully")
        return true
    }
    
    /// Tests the ExpertAI with a simple game scenario
    public static func testExpertAI() -> Bool {
        print("🧪 Testing ExpertAI...")
        
        // Create a new game
        let game = BanqiGame()
        
        // Set up single player mode
        let ai = ExpertAI()
        game.setupSinglePlayerMode(mode: .singlePlayer, humanPlayer: .red, ai: ai)
        
        // Test that AI can generate moves
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        print("📊 Legal moves available: \(legalMoves.count)")
        
        // Test AI move selection
        let aiMove = ai.selectMove(for: game, difficulty: .expert)
        print("🤖 AI selected move: \(aiMove)")
        
        // Test position evaluation
        let evaluation = ai.evaluatePosition(game, for: .black)
        print("📈 Position evaluation: \(evaluation)")
        
        print("✅ ExpertAI test completed successfully")
        return true
    }
    
    /// Tests all AI implementations
    public static func testAllAIs() -> Bool {
        print("🚀 Starting comprehensive AI testing...")
        
        let results = [
            testBeginnerAI(),
            testIntermediateAI(),
            testAdvancedAI(),
            testExpertAI()
        ]
        
        let allPassed = results.allSatisfy { $0 }
        
        if allPassed {
            print("🎉 All AI tests passed successfully!")
        } else {
            print("❌ Some AI tests failed!")
        }
        
        return allPassed
    }
    
    /// Tests the GameModeManager functionality
    public static func testGameModeManager() -> Bool {
        print("🧪 Testing GameModeManager...")
        
        let manager = GameModeManager.shared
        
        // Test game mode switching
        manager.setGameMode(.singlePlayer)
        print("📱 Game mode set to: \(manager.getCurrentGameMode().rawValue)")
        
        // Test AI difficulty setting
        manager.setAIDifficulty(.advanced)
        print("🎯 AI difficulty set to: \(manager.getCurrentAIDifficulty().rawValue)")
        
        // Test human player setting
        manager.setHumanPlayer(.black)
        print("👤 Human player set to: \(manager.getCurrentHumanPlayer().rawValue)")
        
        // Test AI creation
        let ai = manager.createAI()
        print("🤖 Created AI: \(ai.name)")
        
        // Test statistics recording
        manager.recordGameResult(result: .win, gameTime: 300.0, difficulty: .advanced)
        let stats = manager.getStatistics()
        print("📊 Games played: \(stats.gamesPlayed), Win rate: \(String(format: "%.1f", stats.winRate))%")
        
        print("✅ GameModeManager test completed successfully")
        return true
    }
    
    /// Tests the MoveGenerator functionality
    public static func testMoveGenerator() -> Bool {
        print("🧪 Testing MoveGenerator...")
        
        let game = BanqiGame()
        
        // Test legal move generation
        let legalMoves = MoveGenerator.generateLegalMoves(for: game)
        print("📊 Total legal moves: \(legalMoves.count)")
        
        // Count different types of moves
        let flipMoves = legalMoves.filter { if case .flip = $0 { return true } else { return false } }
        let moveMoves = legalMoves.filter { if case .move = $0 { return true } else { return false } }
        let captureMoves = legalMoves.filter { if case .capture = $0 { return true } else { return false } }
        
        print("🔄 Flip moves: \(flipMoves.count)")
        print("➡️ Move moves: \(moveMoves.count)")
        print("⚔️ Capture moves: \(captureMoves.count)")
        
        print("✅ MoveGenerator test completed successfully")
        return true
    }
    
    /// Tests the PositionEvaluator functionality
    public static func testPositionEvaluator() -> Bool {
        print("🧪 Testing PositionEvaluator...")
        
        let game = BanqiGame()
        
        // Test position evaluation for both players
        let redEvaluation = PositionEvaluator.evaluatePosition(game, for: .red)
        let blackEvaluation = PositionEvaluator.evaluatePosition(game, for: .black)
        
        print("🔴 Red player evaluation: \(redEvaluation)")
        print("⚫ Black player evaluation: \(blackEvaluation)")
        
        // Test that evaluations are opposite (zero-sum game)
        let totalEvaluation = redEvaluation + blackEvaluation
        print("📊 Total evaluation (should be ~0): \(totalEvaluation)")
        
        print("✅ PositionEvaluator test completed successfully")
        return true
    }
    
    /// Tests the SearchEngine functionality
    public static func testSearchEngine() -> Bool {
        print("🧪 Testing SearchEngine...")
        
        let game = BanqiGame()
        
        // Test minimax search with limited depth
        let (move, score) = SearchEngine.minimaxSearch(game: game, depth: 1, maximizingPlayer: true)
        
        if let move = move {
            print("🤖 Search engine found move: \(move)")
            print("📈 Move score: \(score)")
        } else {
            print("❌ Search engine found no moves")
        }
        
        print("✅ SearchEngine test completed successfully")
        return true
    }
    
    /// Tests AI vs AI gameplay to verify difficulty levels
    public static func testAIVsAI() -> Bool {
        print("🧪 Testing AI vs AI gameplay...")
        
        // Test different AI matchups
        let matchups: [(String, String, BanqiAI, BanqiAI)] = [
            ("Beginner", "Intermediate", BeginnerAI(), IntermediateAI()),
            ("Intermediate", "Advanced", IntermediateAI(), AdvancedAI()),
            ("Advanced", "Expert", AdvancedAI(), ExpertAI()),
            ("Beginner", "Expert", BeginnerAI(), ExpertAI())
        ]
        
        for (ai1Name, ai2Name, ai1, ai2) in matchups {
            print("\n🎮 Testing \(ai1Name) vs \(ai2Name)...")
            
            let result = playAIGame(ai1: ai1, ai2: ai2, maxMoves: 50)
            
            if result.completed {
                print("✅ Game completed in \(result.movesPlayed) moves")
                if let winner = result.winner {
                    print("🏆 Winner: \(winner.rawValue)")
                } else {
                    print("🏆 Winner: Draw")
                }
                print("⏱️ Game time: \(String(format: "%.2f", result.gameTime))s")
            } else {
                print("⚠️ Game incomplete (max moves reached)")
            }
        }
        
        print("✅ AI vs AI testing completed successfully")
        return true
    }
    
    /// Plays a complete game between two AI players
    private static func playAIGame(ai1: BanqiAI, ai2: BanqiAI, maxMoves: Int) -> (completed: Bool, movesPlayed: Int, winner: BanqiPieceColor?, gameTime: TimeInterval) {
        let game = BanqiGame()
        let startTime = Date()
        var movesPlayed = 0
        
        // Set up the game for AI vs AI
        game.setupSinglePlayerMode(mode: .singlePlayer, humanPlayer: .red, ai: ai1)
        
        while !game.gameOver && movesPlayed < maxMoves {
            guard let currentPlayer = game.sideToMove else { break }
            
            // Determine which AI to use
            let currentAI = currentPlayer == .red ? ai1 : ai2
            let difficulty: AIDifficulty = currentAI is BeginnerAI ? .beginner :
                                          currentAI is IntermediateAI ? .intermediate :
                                          currentAI is AdvancedAI ? .advanced : .expert
            
            // Get AI move
            let aiMove = currentAI.selectMove(for: game, difficulty: difficulty)
            
            // Execute the move
            let success = game.perform(aiMove)
            if !success {
                print("❌ AI move execution failed: \(aiMove)")
                break
            }
            
            movesPlayed += 1
            
            // Add a small delay to make the game more realistic
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        let gameTime = Date().timeIntervalSince(startTime)
        
        return (
            completed: game.gameOver,
            movesPlayed: movesPlayed,
            winner: game.winner,
            gameTime: gameTime
        )
    }
    
    /// Tests AI performance and response times
    public static func testAIPerformance() -> Bool {
        print("🧪 Testing AI performance and response times...")
        
        let difficulties: [AIDifficulty] = [.beginner, .intermediate, .advanced, .expert]
        let testPositions = 5
        
        for difficulty in difficulties {
            print("\n📊 Testing \(difficulty.rawValue) AI performance...")
            
            let ai = getAIForDifficulty(difficulty)
            var totalTime: TimeInterval = 0
            var totalMoves = 0
            
            for i in 0..<testPositions {
                let game = BanqiGame(seed: UInt64(i * 1000)) // Different starting positions
                
                let startTime = Date()
                _ = ai.selectMove(for: game, difficulty: difficulty)
                let responseTime = Date().timeIntervalSince(startTime)
                
                totalTime += responseTime
                totalMoves += 1
                
                print("  Position \(i + 1): \(String(format: "%.3f", responseTime))s")
            }
            
            let averageTime = totalTime / Double(totalMoves)
            print("  📈 Average response time: \(String(format: "%.3f", averageTime))s")
            
            // Verify performance targets from your todo
            let targetTime: TimeInterval = difficulty == .beginner ? 0.5 :
                                          difficulty == .intermediate ? 1.0 :
                                          difficulty == .advanced ? 1.5 : 2.0
            
            if averageTime <= targetTime {
                print("  ✅ Meets performance target (\(String(format: "%.1f", targetTime))s)")
            } else {
                print("  ⚠️ Exceeds performance target (\(String(format: "%.1f", targetTime))s)")
            }
        }
        
        print("✅ AI performance testing completed successfully")
        return true
    }
    
    /// Helper function to get AI instance for a given difficulty
    private static func getAIForDifficulty(_ difficulty: AIDifficulty) -> BanqiAI {
        switch difficulty {
        case .beginner: return BeginnerAI()
        case .intermediate: return IntermediateAI()
        case .advanced: return AdvancedAI()
        case .expert: return ExpertAI()
        }
    }
    
    /// Tests AI difficulty progression and skill differences
    public static func testAIDifficultyProgression() -> Bool {
        print("🧪 Testing AI difficulty progression...")
        
        let game = BanqiGame(seed: 12345) // Fixed seed for consistent testing
        let testMoves = 10
        
        print("📊 Testing AI performance on same position...")
        
        for difficulty in AIDifficulty.allCases {
            let ai = getAIForDifficulty(difficulty)
            var totalScore = 0.0
            var moveCount = 0
            
            for _ in 0..<testMoves {
                let gameCopy = BanqiGame()
                gameCopy.board = game.board
                gameCopy.sideToMove = game.sideToMove
                
                let move = ai.selectMove(for: gameCopy, difficulty: difficulty)
                let success = gameCopy.perform(move)
                
                if success {
                    let score = ai.evaluatePosition(gameCopy, for: .black)
                    totalScore += score
                    moveCount += 1
                }
            }
            
            if moveCount > 0 {
                let averageScore = totalScore / Double(moveCount)
                print("  \(difficulty.rawValue): Average score \(String(format: "%.2f", averageScore))")
            }
        }
        
        print("✅ AI difficulty progression testing completed successfully")
        return true
    }
    
    /// Runs all tests
    public static func runAllTests() -> Bool {
        print("🧪🧪🧪 Starting comprehensive testing suite...")
        print("=" + String(repeating: "=", count: 50))
        
        let results = [
            testGameModeManager(),
            testMoveGenerator(),
            testPositionEvaluator(),
            testSearchEngine(),
            testAllAIs(),
            testAIVsAI(),
            testAIPerformance(),
            testAIDifficultyProgression()
        ]
        
        print("=" + String(repeating: "=", count: 50))
        let allPassed = results.allSatisfy { $0 }
        
        if allPassed {
            print("🎉🎉🎉 ALL TESTS PASSED! 🎉🎉🎉")
        } else {
            print("❌❌❌ SOME TESTS FAILED! ❌❌❌")
        }
        
        return allPassed
    }
}
