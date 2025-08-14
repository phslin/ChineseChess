//
//  GameModeManager.swift
//  ChineseChase
//
//  Game Mode Management for Single Player vs Two Player modes
//

import Foundation

/// Represents different game modes
public enum GameMode: String, CaseIterable, Codable {
    case twoPlayer = "Two Players"
    case singlePlayer = "Single Player"
    
    /// Description of the game mode
    public var description: String {
        switch self {
        case .twoPlayer:
            return "Play against another human player"
        case .singlePlayer:
            return "Play against the computer AI"
        }
    }
}

/// Represents the type of player
public enum PlayerType: String, Codable {
    case human = "Human"
    case ai = "AI"
}

/// Represents which player the human will control
public enum HumanPlayer: String, CaseIterable, Codable {
    case red = "Red"
    case black = "Black"
    
    /// Description of the player choice
    public var description: String {
        switch self {
        case .red:
            return "Play as Red Army (moves first)"
        case .black:
            return "Play as Black Army (moves second)"
        }
    }
}

/// Game settings for single player mode
public struct GameSettings: Codable {
    public var aiDifficulty: AIDifficulty
    public var humanPlayer: HumanPlayer
    public var aiThinkingTime: TimeInterval
    
    public init(aiDifficulty: AIDifficulty = .intermediate, 
                humanPlayer: HumanPlayer = .red,
                aiThinkingTime: TimeInterval = 2.0) {
        self.aiDifficulty = aiDifficulty
        self.humanPlayer = humanPlayer
        self.aiThinkingTime = aiThinkingTime
    }
}

/// Game statistics tracking
public struct GameStatistics: Codable {
    public var gamesPlayed: Int
    public var gamesWon: Int
    public var gamesLost: Int
    public var gamesDrawn: Int
    public var averageGameTime: TimeInterval
    public var bestWinTime: TimeInterval?
    public var difficultyLevelsPlayed: [AIDifficulty: Int]
    
    public init() {
        self.gamesPlayed = 0
        self.gamesWon = 0
        self.gamesLost = 0
        self.gamesDrawn = 0
        self.averageGameTime = 0.0
        self.bestWinTime = nil
        self.difficultyLevelsPlayed = [:]
    }
    
    /// Win rate as a percentage
    public var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100.0
    }
    
    /// Loss rate as a percentage
    public var lossRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesLost) / Double(gamesPlayed) * 100.0
    }
    
    /// Draw rate as a percentage
    public var drawRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesDrawn) / Double(gamesPlayed) * 100.0
    }
}

/// Singleton class to manage game modes and settings
public class GameModeManager {
    
    // MARK: - Singleton
    public static let shared = GameModeManager()
    
    private init() {
        loadSettings()
        loadStatistics()
    }
    
    // MARK: - Properties
    public private(set) var currentGameMode: GameMode = .twoPlayer
    public private(set) var currentSettings = GameSettings()
    public private(set) var statistics = GameStatistics()
    
    // MARK: - Game Mode Management
    
    /// Changes the current game mode
    /// - Parameter mode: The new game mode
    public func setGameMode(_ mode: GameMode) {
        currentGameMode = mode
        saveSettings()
    }
    
    /// Gets the current game mode
    public func getCurrentGameMode() -> GameMode {
        return currentGameMode
    }
    
    /// Checks if the current mode is single player
    public var isSinglePlayerMode: Bool {
        return currentGameMode == .singlePlayer
    }
    
    /// Checks if the current mode is two player
    public var isTwoPlayerMode: Bool {
        return currentGameMode == .twoPlayer
    }
    
    // MARK: - Settings Management
    
    /// Updates the AI difficulty setting
    /// - Parameter difficulty: The new AI difficulty level
    public func setAIDifficulty(_ difficulty: AIDifficulty) {
        currentSettings.aiDifficulty = difficulty
        saveSettings()
    }
    
    /// Gets the current AI difficulty
    public func getCurrentAIDifficulty() -> AIDifficulty {
        return currentSettings.aiDifficulty
    }
    
    /// Updates the human player choice
    /// - Parameter player: The new human player choice
    public func setHumanPlayer(_ player: HumanPlayer) {
        currentSettings.humanPlayer = player
        saveSettings()
    }
    
    /// Gets the current human player choice
    public func getCurrentHumanPlayer() -> HumanPlayer {
        return currentSettings.humanPlayer
    }
    
    /// Updates the AI thinking time
    /// - Parameter time: The new thinking time in seconds
    public func setAIThinkingTime(_ time: TimeInterval) {
        currentSettings.aiThinkingTime = time
        saveSettings()
    }
    
    /// Gets the current AI thinking time
    public func getCurrentAIThinkingTime() -> TimeInterval {
        return currentSettings.aiThinkingTime
    }
    
    // MARK: - AI Management
    
    /// Creates an AI instance based on current difficulty
    /// - Returns: The appropriate AI implementation
    public func createAI() -> BanqiAI {
        switch currentSettings.aiDifficulty {
        case .beginner:
            return BeginnerAI()
        case .intermediate:
            return IntermediateAI()
        case .advanced:
            return AdvancedAI()
        case .expert:
            return ExpertAI()
        }
    }
    
    /// Gets the AI difficulty description
    public func getAIDifficultyDescription() -> String {
        return currentSettings.aiDifficulty.description
    }
    
    // MARK: - Statistics Management
    
    /// Records a game result
    /// - Parameters:
    ///   - result: The result of the game (win, loss, or draw)
    ///   - gameTime: The duration of the game
    ///   - difficulty: The AI difficulty if applicable
    public func recordGameResult(result: GameResult, gameTime: TimeInterval, difficulty: AIDifficulty? = nil) {
        statistics.gamesPlayed += 1
        
        switch result {
        case .win:
            statistics.gamesWon += 1
            if let bestTime = statistics.bestWinTime {
                if gameTime < bestTime {
                    statistics.bestWinTime = gameTime
                }
            } else {
                statistics.bestWinTime = gameTime
            }
        case .loss:
            statistics.gamesLost += 1
        case .draw:
            statistics.gamesDrawn += 1
        }
        
        // Update average game time
        let totalTime = statistics.averageGameTime * Double(statistics.gamesPlayed - 1) + gameTime
        statistics.averageGameTime = totalTime / Double(statistics.gamesPlayed)
        
        // Update difficulty level statistics
        if let difficulty = difficulty {
            statistics.difficultyLevelsPlayed[difficulty, default: 0] += 1
        }
        
        saveStatistics()
    }
    
    /// Gets the current statistics
    public func getStatistics() -> GameStatistics {
        return statistics
    }
    
    /// Resets all statistics
    public func resetStatistics() {
        statistics = GameStatistics()
        saveStatistics()
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(currentSettings) {
            UserDefaults.standard.set(encoded, forKey: "GameSettings")
        }
        
        if let encoded = try? JSONEncoder().encode(currentGameMode) {
            UserDefaults.standard.set(encoded, forKey: "CurrentGameMode")
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "GameSettings"),
           let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            currentSettings = settings
        }
        
        if let data = UserDefaults.standard.data(forKey: "CurrentGameMode"),
           let mode = try? JSONDecoder().decode(GameMode.self, from: data) {
            currentGameMode = mode
        }
    }
    
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(encoded, forKey: "GameStatistics")
        }
    }
    
    private func loadStatistics() {
        if let data = UserDefaults.standard.data(forKey: "GameStatistics"),
           let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) {
            statistics = stats
        }
    }
}

// MARK: - Game Result

/// Represents the result of a game
public enum GameResult: String, Codable {
    case win = "Win"
    case loss = "Loss"
    case draw = "Draw"
}
