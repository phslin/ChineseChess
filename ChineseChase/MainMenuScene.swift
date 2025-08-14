//
//  MainMenuScene.swift
//  ChineseChase
//
//  Main menu scene for game mode selection
//

import SpriteKit

/// Main menu scene for game mode selection
public class MainMenuScene: SKScene {
    
    // MARK: - Properties
    private var gameModeManager = GameModeManager.shared
    private var titleLabel: SKLabelNode!
    private var twoPlayerButton: SKNode!
    private var singlePlayerButton: SKNode!
    private var settingsButton: SKNode!
    private var statisticsButton: SKNode!
    
    // MARK: - Scene Lifecycle
    
    override public func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Title
        titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Chinese Chase"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .darkGray
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        addChild(titleLabel)
        
        // Subtitle
        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        subtitleLabel.text = "Dark Chess Strategy Game"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = .gray
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        addChild(subtitleLabel)
        
        // Two Player Button
        twoPlayerButton = createButton(
            text: "Two Players",
            description: "Play against another human player",
            position: CGPoint(x: size.width / 2, y: size.height * 0.6),
            color: .blue
        )
        addChild(twoPlayerButton)
        
        // Single Player Button
        singlePlayerButton = createButton(
            text: "Single Player",
            description: "Play against the computer AI",
            position: CGPoint(x: size.width / 2, y: size.height * 0.45),
            color: .green
        )
        addChild(singlePlayerButton)
        
        // Settings Button
        settingsButton = createButton(
            text: "Settings",
            description: "Configure game preferences",
            position: CGPoint(x: size.width / 2, y: size.height * 0.3),
            color: .orange
        )
        addChild(settingsButton)
        
        // Statistics Button
        statisticsButton = createButton(
            text: "Statistics",
            description: "View your game history",
            position: CGPoint(x: size.width / 2, y: size.height * 0.15),
            color: .purple
        )
        addChild(statisticsButton)
        
        // Version info
        let versionLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        versionLabel.text = "Version 1.0"
        versionLabel.fontSize = 14
        versionLabel.fontColor = .lightGray
        versionLabel.position = CGPoint(x: size.width - 80, y: 20)
        addChild(versionLabel)
    }
    
    /// Creates a button with text and description
    private func createButton(text: String, description: String, position: CGPoint, color: SKColor) -> SKNode {
        let button = SKNode()
        button.position = position
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 80), cornerRadius: 10)
        background.fillColor = color.withAlphaComponent(0.1)
        background.strokeColor = color
        background.lineWidth = 2
        background.position = CGPoint.zero
        
        // Main text
        let mainLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mainLabel.text = text
        mainLabel.fontSize = 24
        mainLabel.fontColor = color
        mainLabel.position = CGPoint(x: 0, y: 10)
        
        // Description text
        let descLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        descLabel.text = description
        descLabel.fontSize = 16
        descLabel.fontColor = .darkGray
        descLabel.position = CGPoint(x: 0, y: -15)
        
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
        
        // Check which button was tapped
        if nodesAtPoint.contains(where: { $0.parent == twoPlayerButton }) {
            handleTwoPlayerSelection()
        } else if nodesAtPoint.contains(where: { $0.parent == singlePlayerButton }) {
            handleSinglePlayerSelection()
        } else if nodesAtPoint.contains(where: { $0.parent == settingsButton }) {
            handleSettingsSelection()
        } else if nodesAtPoint.contains(where: { $0.parent == statisticsButton }) {
            handleStatisticsSelection()
        }
    }
    
    // MARK: - Button Handlers
    
    private func handleTwoPlayerSelection() {
        // Set game mode to two player
        gameModeManager.setGameMode(.twoPlayer)
        
        // Transition to game scene
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func handleSinglePlayerSelection() {
        // Set game mode to single player
        gameModeManager.setGameMode(.singlePlayer)
        
        // Transition to difficulty selection scene
        let difficultyScene = DifficultySelectionScene(size: size)
        difficultyScene.scaleMode = .resizeFill
        view?.presentScene(difficultyScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func handleSettingsSelection() {
        // Transition to settings scene
        let settingsScene = SettingsScene(size: size)
        settingsScene.scaleMode = .resizeFill
        view?.presentScene(settingsScene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func handleStatisticsSelection() {
        // Transition to statistics scene
        let statsScene = StatisticsScene(size: size)
        statsScene.scaleMode = .resizeFill
        view?.presentScene(statsScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}
