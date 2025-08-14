# Single Player Feature Plan - Chinese Chase

## Overview
Add a single-player mode where the human player can play against an AI computer opponent in the Banqi (Dark Chess) game.

## Current Game Structure Analysis
Based on the existing codebase:
- **Game Engine**: `BanqiGame` class handles game logic, board state, and move validation
- **UI Layer**: `GameScene` manages the visual representation and user interactions
- **Game Flow**: Currently supports two human players with turn-based gameplay
- **Move System**: Supports flip, move, and capture actions with legal move validation

## Feature Requirements

### 1. Game Mode Selection
- Add a main menu or game mode selector
- Options: "Two Players" (existing) vs "Single Player" (new)
- Single player mode selection screen with difficulty levels

### 2. AI Implementation
- **Difficulty Levels**:
  - **Beginner**: Random moves with basic piece value awareness
  - **Intermediate**: Strategic thinking with 2-3 move lookahead
  - **Advanced**: Deep search algorithms with opening book knowledge
  - **Expert**: Advanced AI with endgame tablebase support

### 3. AI Engine Architecture
```swift
protocol BanqiAI {
    func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction
    func evaluatePosition(_ game: BanqiGame) -> Double
}

enum AIDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}
```

### 4. Core AI Components

#### 4.1 Move Generation
- Generate all legal moves for AI's current position
- Filter moves based on basic tactical principles
- Prioritize captures and piece development

#### 4.2 Position Evaluation
- **Piece Values**: General (9), Advisor (2), Elephant (2), Chariot (9), Horse (4), Cannon (4.5), Soldier (1)
- **Positional Factors**: Center control, piece mobility, king safety
- **Tactical Factors**: Captures, threats, piece coordination

#### 4.3 Search Algorithms
- **Beginner**: Random selection from legal moves
- **Intermediate**: 2-ply minimax with alpha-beta pruning
- **Advanced**: 4-6 ply search with move ordering
- **Expert**: Iterative deepening with transposition tables

### 5. UI/UX Enhancements

#### 5.1 Game Mode Selection
- Main menu with animated transitions
- Difficulty selection with visual indicators
- Player color selection (Red vs Black)

#### 5.2 In-Game Features
- AI thinking indicator (spinner/loading animation)
- Move hints for beginner players
- Undo move functionality (limited to player's last move)
- AI move visualization with arrows/animations

#### 5.3 Settings & Customization
- AI difficulty adjustment during gameplay
- AI thinking time limits
- Sound effects for AI moves
- Visual feedback for AI decision making

### 6. Technical Implementation

#### 6.1 New Classes to Create
```swift
// AI Engine
class BanqiAIEngine: BanqiAI
class MoveGenerator
class PositionEvaluator
class SearchEngine

// Game Mode Management
class GameModeManager
class SinglePlayerGameController

// UI Components
class MainMenuScene
class DifficultySelectionScene
class GameModeSelectionScene
```

#### 6.2 Modified Existing Classes
- **GameScene**: Add AI move handling and game mode support
- **GameViewController**: Add scene transitions for menu system
- **BanqiGame**: Add AI player support and game state management

#### 6.3 Data Persistence
- Save/load single player games
- Track AI difficulty preferences
- Store game statistics and win/loss records

### 7. AI Difficulty Implementation Details

#### 7.1 Beginner AI
```swift
class BeginnerAI: BanqiAI {
    func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        let legalMoves = generateLegalMoves(for: game)
        let captureMoves = legalMoves.filter { /* is capture */ }
        
        // Prefer captures, then random moves
        if !captureMoves.isEmpty {
            return captureMoves.randomElement()!
        }
        return legalMoves.randomElement()!
    }
}
```

#### 7.2 Intermediate AI
```swift
class IntermediateAI: BanqiAI {
    func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        // 2-ply minimax search
        let searchDepth = 2
        return minimaxSearch(game: game, depth: searchDepth)
    }
}
```

#### 7.3 Advanced AI
```swift
class AdvancedAI: BanqiAI {
    func selectMove(for game: BanqiGame, difficulty: AIDifficulty) -> BanqiAction {
        // 4-6 ply search with move ordering
        let searchDepth = 4
        return iterativeDeepeningSearch(game: game, maxDepth: searchDepth)
    }
}
```

### 8. User Experience Flow

1. **App Launch** → Main Menu
2. **Main Menu** → Game Mode Selection
3. **Game Mode Selection** → Single Player Mode
4. **Single Player Mode** → Difficulty Selection
5. **Difficulty Selection** → Player Color Choice
6. **Game Setup** → AI vs Human Gameplay
7. **Gameplay** → AI moves with visual feedback
8. **Game End** → Results screen with replay option

### 9. Performance Considerations

- **AI Response Time**: Target < 2 seconds for all difficulty levels
- **Memory Usage**: Efficient move generation and position storage
- **Battery Life**: Optimize AI calculations for mobile devices
- **Smooth Animations**: 60 FPS gameplay with AI move animations

### 10. Testing Strategy

#### 10.1 Unit Tests
- AI move generation accuracy
- Position evaluation consistency
- Search algorithm correctness
- Game state management

#### 10.2 Integration Tests
- AI vs AI gameplay
- Human vs AI move validation
- Game flow and state transitions

#### 10.3 User Testing
- Difficulty level appropriateness
- AI response time satisfaction
- Overall gameplay experience

### 11. Future Enhancements

- **Learning AI**: AI that adapts to player's skill level
- **Opening Book**: Pre-calculated strong opening moves
- **Endgame Database**: Perfect play for simplified positions
- **Online Multiplayer**: AI as a fallback for disconnected players
- **Replay System**: Save and analyze AI vs Human games

### 12. Implementation Timeline

#### Phase 1 (Week 1-2): Foundation
- Create AI engine architecture
- Implement basic move generation
- Add game mode selection UI

#### Phase 2 (Week 3-4): Core AI
- Implement Beginner and Intermediate AI
- Add position evaluation
- Integrate AI with game flow

#### Phase 3 (Week 5-6): Advanced Features
- Implement Advanced and Expert AI
- Add move animations and visual feedback
- Polish user experience

#### Phase 4 (Week 7-8): Testing & Polish
- Comprehensive testing
- Performance optimization
- Bug fixes and refinements

### 13. Success Metrics

- **AI Response Time**: < 2 seconds for 95% of moves
- **Game Balance**: AI win rates appropriate for each difficulty level
- **User Engagement**: Single player mode usage > 40% of total gameplay
- **Performance**: No frame rate drops during AI calculations
- **User Satisfaction**: > 4.5/5 rating for AI gameplay experience

## Conclusion

The single-player feature will significantly enhance the Chinese Chase game by providing an engaging solo experience with multiple difficulty levels. The modular AI architecture allows for easy difficulty scaling and future improvements, while maintaining the core game mechanics that players already enjoy.
