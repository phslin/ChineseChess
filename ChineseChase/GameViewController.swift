//
//  GameViewController.swift
//  ChineseChase
//
//  Created by Benson Lin on 8/7/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Present a programmatic GameScene sized to the view and set to resize with it
        if let skView = self.view as? SKView {
            let sceneNode = GameScene(size: skView.bounds.size)
            sceneNode.scaleMode = .resizeFill
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.preferredFramesPerSecond = 60
            skView.presentScene(sceneNode)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
