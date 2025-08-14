//
//  SettingsScene.swift
//  ChineseChase
//
//  Settings scene (placeholder)
//

import SpriteKit

/// Settings scene (placeholder)
public class SettingsScene: SKScene {
    
    override public func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1)
        
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Settings"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .darkGray
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        addChild(titleLabel)
        
        let backButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        backButton.text = "Back to Menu"
        backButton.fontSize = 24
        backButton.fontColor = .blue
        backButton.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        addChild(backButton)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let mainMenuScene = MainMenuScene(size: size)
        mainMenuScene.scaleMode = .resizeFill
        view?.presentScene(mainMenuScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}
