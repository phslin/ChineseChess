//
//  DifficultySelectionScene.swift
//  ChineseChase
//
//  Difficulty selection scene for single player mode
//

import SpriteKit

/// Difficulty selection scene for single player mode
public class DifficultySelectionScene: SKScene {
    
    // MARK: - Properties
    private var gameModeManager = GameModeManager.shared
    private var titleLabel: SKLabelNode!
    private var difficultyButtons: [SKNode] = []
    private var playerColorButtons: [SKNode] = []
    private var startButton: SKNode!
    private var backButton: SKNode!
    
    private var selectedDifficulty: AIDifficulty = .intermediate
    private var selectedPlayerColor: HumanPlayer = .red
    
    // MARK: - Scene Lifecycle
    
    override public func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Title
        titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Choose Your Challenge"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .darkGray
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        addChild(titleLabel)
        
        // Difficulty Section
        let difficultyTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        difficultyTitle.text = "AI Difficulty"
        difficultyTitle.fontSize = 24
        difficultyTitle.fontColor = .darkGray
        difficultyTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        addChild(difficultyTitle)
        
        // Difficulty Buttons
        let difficulties: [AIDifficulty] = [.beginner, .intermediate, .advanced, .expert]
        let difficultyYPositions: [CGFloat] = [0.65, 0.55, 0.45, 0.35]
        
        for (index, difficulty) in difficulties.enumerated() {
            let button = createDifficultyButton(
                difficulty: difficulty,
                position: CGPoint(x: size.width / 2, y: size.height * difficultyYPositions[index]),
                isSelected: difficulty == selectedDifficulty
            )
            difficultyButtons.append(button)
            addChild(button)
        }
        
        // Player Color Section
        let colorTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        colorTitle.text = "Your Color"
        colorTitle.fontSize = 24
        colorTitle.fontColor = .darkGray
        colorTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        addChild(colorTitle)
        
        // Player Color Buttons
        let redButton = createColorButton(
            color: .red,
            text: "Red Army",
            description: "Move first",
            position: CGPoint(x: size.width * 0.35, y: size.height * 0.15),
            isSelected: selectedPlayerColor == .red
        )
        playerColorButtons.append(redButton)
        addChild(redButton)
        
        let blackButton = createColorButton(
            color: .black,
            text: "Black Army",
            description: "Move second",
            position: CGPoint(x: size.width * 0.65, y: size.height * 0.15),
            isSelected: selectedPlayerColor == .black
        )
        playerColorButtons.append(blackButton)
        addChild(blackButton)
        
        // Start Button
        startButton = createButton(
            text: "Start Game",
            description: "Begin your challenge",
            position: CGPoint(x: size.width / 2, y: size.height * 0.05),
            color: .green
        )
        addChild(startButton)
        
        // Back Button
        backButton = createButton(
            text: "Back to Menu",
            description: "Return to main menu",
            position: CGPoint(x: 100, y: size.height - 50),
            color: .gray
        )
        addChild(backButton)
    }
    
    /// Creates a difficulty selection button
    private func createDifficultyButton(difficulty: AIDifficulty, position: CGPoint, isSelected: Bool) -> SKNode {
        let button = SKNode()
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 8)
        background.fillColor = isSelected ? difficulty.color.withAlphaComponent(0.2) : difficulty.color.withAlphaComponent(0.1)
        background.strokeColor = difficulty.color
        background.lineWidth = isSelected ? 3 : 2
        background.position = position
        
        // Main text
        let mainLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mainLabel.text = difficulty.rawValue
        mainLabel.fontSize = 20
        mainLabel.fontColor = difficulty.color
        mainLabel.position = CGPoint(x: 0, y: 8)
        
        // Description text
        let descLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        descLabel.text = difficulty.description
        descLabel.fontSize = 14
        descLabel.fontColor = .darkGray
        descLabel.position = CGPoint(x: 0, y: -10)
        
        button.addChild(background)
        button.addChild(mainLabel)
        button.addChild(descLabel)
        
        // Store difficulty in userData for identification
        button.userData = NSMutableDictionary()
        button.userData?.setValue(difficulty.rawValue, forKey: "difficulty")
        
        return button
    }
    
    /// Creates a color selection button
    private func createColorButton(color: BanqiPieceColor, text: String, description: String, position: CGPoint, isSelected: Bool) -> SKNode {
        let button = SKNode()
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 80), cornerRadius: 8)
        background.fillColor = isSelected ? color.uiColor.withAlphaComponent(0.2) : color.uiColor.withAlphaComponent(0.1)
        background.strokeColor = color.uiColor
        background.lineWidth = isSelected ? 3 : 2
        background.position = position
        
        // Main text
        let mainLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mainLabel.text = text
        mainLabel.fontSize = 18
        mainLabel.fontColor = color.uiColor
        mainLabel.position = CGPoint(x: 0, y: 10)
        
        // Description text
        let descLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        descLabel.text = description
        descLabel.fontSize = 14
        descLabel.fontColor = .darkGray
        descLabel.position = CGPoint(x: 0, y: -10)
        
        button.addChild(background)
        button.addChild(mainLabel)
        button.addChild(descLabel)
        
        // Store color in userData for identification
        button.userData = NSMutableDictionary()
        button.userData?.setValue(color == .red ? "red" : "black", forKey: "color")
        
        return button
    }
    
    /// Creates a general button
    private func createButton(text: String, description: String, position: CGPoint, color: SKColor) -> SKNode {
        let button = SKNode()
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 8)
        background.fillColor = color.withAlphaComponent(0.1)
        background.strokeColor = color
        background.lineWidth = 2
        background.position = position
        
        // Main text
        let mainLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mainLabel.text = text
        mainLabel.fontSize = 18
        mainLabel.fontColor = color
        mainLabel.position = CGPoint(x: 0, y: 5)
        
        // Description text
        let descLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        descLabel.text = description
        descLabel.fontSize = 12
        descLabel.fontColor = .darkGray
        descLabel.position = CGPoint(x: 0, y: -12)
        
        button.addChild(background)
        button.addChild(mainLabel)
        button.addChild(descLabel)
        
        return button
    }
    
    // MARK: - Touch Handling
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        // Check difficulty button taps
        for button in difficultyButtons {
            if nodesAtPoint.contains(where: { $0.parent == button }) {
                handleDifficultySelection(button)
                return
            }
        }
        
        // Check color button taps
        for button in playerColorButtons {
            if nodesAtPoint.contains(where: { $0.parent == button }) {
                handleColorSelection(button)
                return
            }
        }
        
        // Check other button taps
        if nodesAtPoint.contains(where: { $0.parent == startButton }) {
            handleStartGame()
        } else if nodesAtPoint.contains(where: { $0.parent == backButton }) {
            handleBackToMenu()
        }
    }
    
    // MARK: - Button Handlers
    
    private func handleDifficultySelection(_ button: SKNode) {
        guard let difficultyString = button.userData?["difficulty"] as? String,
              let difficulty = AIDifficulty(rawValue: difficultyString) else { return }
        
        // Update selection
        selectedDifficulty = difficulty
        gameModeManager.setAIDifficulty(difficulty)
        
        // Update UI
        updateDifficultyButtons()
    }
    
    private func handleColorSelection(_ button: SKNode) {
        guard let colorString = button.userData?["color"] as? String else { return }
        
        // Update selection
        if colorString == "red" {
            selectedPlayerColor = .red
        } else {
            selectedPlayerColor = .black
        }
        gameModeManager.setHumanPlayer(selectedPlayerColor)
        
        // Update UI
        updateColorButtons()
    }
    
    private func handleStartGame() {
        // Configure game settings
        gameModeManager.setAIDifficulty(selectedDifficulty)
        gameModeManager.setHumanPlayer(selectedPlayerColor)
        
        // Transition to game scene
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func handleBackToMenu() {
        // Transition back to main menu
        let mainMenuScene = MainMenuScene(size: size)
        mainMenuScene.scaleMode = .resizeFill
        view?.presentScene(mainMenuScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    // MARK: - UI Updates
    
    private func updateDifficultyButtons() {
        for button in difficultyButtons {
            guard let difficultyString = button.userData?["difficulty"] as? String,
                  let difficulty = AIDifficulty(rawValue: difficultyString) else { continue }
            
            let isSelected = difficulty == selectedDifficulty
            let background = button.children.first as? SKShapeNode
            
            background?.fillColor = isSelected ? difficulty.color.withAlphaComponent(0.2) : difficulty.color.withAlphaComponent(0.1)
            background?.lineWidth = isSelected ? 3 : 2
        }
    }
    
    private func updateColorButtons() {
        for button in playerColorButtons {
            guard let colorString = button.userData?["color"] as? String else { continue }
            
            let isSelected = (colorString == "red" && selectedPlayerColor == .red) ||
                           (colorString == "black" && selectedPlayerColor == .black)
            
            let color: BanqiPieceColor = colorString == "red" ? .red : .black
            let background = button.children.first as? SKShapeNode
            
            background?.fillColor = isSelected ? color.uiColor.withAlphaComponent(0.2) : color.uiColor.withAlphaComponent(0.1)
            background?.lineWidth = isSelected ? 3 : 2
        }
    }
}

// MARK: - Extensions

extension AIDifficulty {
    /// Color for the difficulty level
    var color: SKColor {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

extension BanqiPieceColor {
    /// UI color for the piece color
    var uiColor: SKColor {
        switch self {
        case .red: return .red
        case .black: return .black
        }
    }
}
