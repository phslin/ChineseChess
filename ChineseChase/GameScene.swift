//
//  GameScene.swift
//  ChineseChase
//
//  Created by Benson Lin on 8/7/25.
//

import SpriteKit
import GameplayKit
import UIKit
import AVFoundation
    
final class GameScene: SKScene {
    // Kept for compatibility with template loading from GameViewController
    var entities = [GKEntity]()
    var graphs = [String: GKGraph]()

    private var game: BanqiGame!

    private var boardNode = SKNode()
    private var gridNode = SKNode()
    private var piecesNode = SKNode()
    private var highlightsNode = SKNode()
    private var statusLabel = SKLabelNode()
    private var newGameButton = SKLabelNode()
    private var settingsPanel = SKNode()
    private var tutorialOverlay = SKNode()
    // Player labels - more professional game style
    private var player1Label: SKLabelNode!
    private var player2Label: SKLabelNode!
    private var currentPlayerIndicator: SKShapeNode!
    
    // Captured pieces display
    private var capturedPiecesNode: SKNode!
    private var capturedRedPieces: [SKNode] = []
    private var capturedBlackPieces: [SKNode] = []
    private var endgameBanner = SKNode()
    
    private var useDeterministicSeed = false
    private var currentSeed: UInt64 = 12345
    private var showTutorial = false
    
    // Style toggles
    private var currentBoardTheme = "classic"
    private var currentPieceStyle = "characters"
    
    // Sound effects
    private var moveSound: AVAudioPlayer?
    private var captureSound: AVAudioPlayer?
    
    private var tileSize: CGFloat = 64
    private var boardOrigin: CGPoint = .zero
    private var selectedPosition: BanqiPosition?
    private var legalTargets: [BanqiPosition] = []
    private var selectionBorder: SKShapeNode?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1)
        removeAllChildren()
        
        // Load user preferences
        loadUserDefaults()
        
        // Set up for optimal performance
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true

        boardNode.removeAllChildren()
        piecesNode.removeAllChildren()
        highlightsNode.removeAllChildren()

        addChild(boardNode)
        addChild(gridNode)
        addChild(highlightsNode)
        addChild(piecesNode)
        addChild(endgameBanner)

        // Initialize player labels
        player1Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        player1Label.fontSize = 16
        player1Label.fontColor = .red
        player1Label.text = "RED ARMY"
        player1Label.position = CGPoint(x: 80, y: size.height - 40)
        addChild(player1Label)
        
        player2Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        player2Label.fontSize = 16
        player2Label.fontColor = .black
        player2Label.text = "BLACK ARMY"
        player2Label.position = CGPoint(x: 80, y: size.height - 60)
        addChild(player2Label)
        
        // Initialize current player indicator
        currentPlayerIndicator = SKShapeNode(rectOf: CGSize(width: 12, height: 12))
        currentPlayerIndicator.fillColor = .red
        currentPlayerIndicator.strokeColor = .clear
        currentPlayerIndicator.position = CGPoint(x: 60, y: size.height - 40)
        addChild(currentPlayerIndicator)
        
        // Initialize captured pieces display
        capturedPiecesNode = SKNode()
        capturedPiecesNode.position = CGPoint(x: 0, y: 0)
        addChild(capturedPiecesNode)

        // Initialize game BEFORE calling saveGameState
        game = BanqiGame()
        if useDeterministicSeed {
            game = BanqiGame(seed: currentSeed)
        }

        statusLabel.fontSize = 18
        statusLabel.fontColor = SKColor(white: 0.1, alpha: 1)
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 8)
        addChild(statusLabel)
        



        
        // Set up board
        layoutBoard()
        renderBoard()
        renderAllPieces()
        positionAllNodes()
        
        // Don't call updateStatus or updateCapturedPieces during initialization
        // They will be called when needed
        
        // New Game button
        newGameButton.text = "New"
        newGameButton.fontSize = 16
        newGameButton.fontColor = SKColor(white: 0.1, alpha: 1)
        newGameButton.horizontalAlignmentMode = .left
        newGameButton.verticalAlignmentMode = .top
        newGameButton.name = "newGameButton"
        newGameButton.zPosition = 5
        newGameButton.position = CGPoint(x: 16, y: size.height - 10)
        newGameButton.accessibilityLabel = "New Game"
        newGameButton.accessibilityHint = "Start a new game"
        addChild(newGameButton)




        

        

        
        // Settings panel
        addChild(settingsPanel)
        
        // Tutorial overlay
        addChild(tutorialOverlay)
        
        // Show tutorial on first run
        if showTutorial {
            showTutorialOverlay()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 12)
        newGameButton.position = CGPoint(x: 16, y: size.height - 16)
        
        // Only update positions if these elements are initialized
        player1Label?.position = CGPoint(x: 80, y: size.height - 40)
        player2Label?.position = CGPoint(x: 80, y: size.height - 60)
        
        // Fix the crash by properly handling optional elements and game.sideToMove
        if let currentPlayerIndicator = currentPlayerIndicator, let game = game {
            if let currentPlayer = game.sideToMove {
                currentPlayerIndicator.position = CGPoint(x: 60, y: currentPlayer == .red ? size.height - 40 : size.height - 60)
            } else {
                currentPlayerIndicator.position = CGPoint(x: 60, y: size.height - 40) // Default to red position
            }
        }
        
        capturedPiecesNode?.position = CGPoint(x: 0, y: 0)
        layoutBoard()
        renderBoard()
        positionAllNodes()
        
        // Only update if game is initialized
        if game != nil {
            updateStatus()
            updateCapturedPieces()
        }
    }

    // MARK: - Layout

    private func layoutBoard() {
        // Render the board rotated 90° clockwise so it fills landscape (8 across × 4 tall)
        let renderCols = CGFloat(BanqiGame.numberOfRows)   // 8 across
        let renderRows = CGFloat(BanqiGame.numberOfColumns) // 4 tall
        let safeInset: CGFloat = 20
        let usableWidth = max(0, size.width - safeInset * 2)
        let usableHeight = max(0, size.height - safeInset * 2)
        tileSize = min(usableWidth / renderCols, usableHeight / renderRows)
        let boardWidth = renderCols * tileSize
        let boardHeight = renderRows * tileSize
        boardOrigin = CGPoint(
            x: (size.width - boardWidth) / 2,
            y: (size.height - boardHeight) / 2
        )
        boardNode.position = .zero
        piecesNode.position = .zero
        highlightsNode.position = .zero
    }

    private func renderBoard() {
        boardNode.removeAllChildren()
        gridNode.removeAllChildren()
        let cols = BanqiGame.numberOfColumns
        let rows = BanqiGame.numberOfRows

        // Board background sized to rotated grid (8 × 4)
        let boardRect = CGRect(x: boardOrigin.x, y: boardOrigin.y, width: CGFloat(rows) * tileSize, height: CGFloat(cols) * tileSize)
        
        // Use a single background node for better performance
        let background = SKShapeNode(rect: boardRect)
        background.fillColor = SKColor(red: 0.93, green: 0.90, blue: 0.84, alpha: 1)
        background.strokeColor = SKColor(white: 0.0, alpha: 0.8)
        background.lineWidth = 3
        boardNode.addChild(background)
        
        // Add frame as a separate node for better layering
        let frameOuter = SKShapeNode(rect: boardRect.insetBy(dx: -10, dy: -10))
        frameOuter.strokeColor = SKColor(white: 0.05, alpha: 1)
        frameOuter.lineWidth = 6
        frameOuter.fillColor = .clear
        frameOuter.zPosition = 0.1
        boardNode.addChild(frameOuter)

        // Grid tiles (thin dark lines, beige squares) – iterate real board coords but place at rotated draw coords
        for row in 0..<rows {
            for col in 0..<cols {
                let boardPos = BanqiPosition(column: col, row: row)
                let drawPos = toDrawGridIndices(from: boardPos)
                let tileRect = CGRect(
                    x: boardOrigin.x + CGFloat(drawPos.x) * tileSize,
                    y: boardOrigin.y + CGFloat(drawPos.y) * tileSize,
                    width: tileSize, height: tileSize
                )
                let tile = SKShapeNode(rect: tileRect)
                tile.strokeColor = SKColor(white: 0.0, alpha: 0.3)
                tile.lineWidth = 0.8
                tile.fillColor = .clear
                tile.name = "cell_\(col)_\(row)"
                tile.accessibilityLabel = "Board cell \(coord(boardPos))"
                gridNode.addChild(tile)
            }
        }

        // Palace-style diagonals in the central 2×2 of the rotated grid
        if rows >= 4 && cols >= 4 {
            let midCols = [rows/2 - 1, rows/2] // in draw space, x uses rows
            let midRows = [cols/2 - 1, cols/2] // in draw space, y uses cols
            let p1 = CGPoint(x: boardOrigin.x + CGFloat(midCols.first!) * tileSize,
                             y: boardOrigin.y + CGFloat(midRows.first!) * tileSize)
            let p2 = CGPoint(x: boardOrigin.x + CGFloat(midCols.last! + 1) * tileSize,
                             y: boardOrigin.y + CGFloat(midRows.last! + 1) * tileSize)
            let p3 = CGPoint(x: p2.x, y: p1.y)
            let p4 = CGPoint(x: p1.x, y: p2.y)
            let diag1 = SKShapeNode(path: {
                let path = CGMutablePath(); path.move(to: p1); path.addLine(to: p2); return path
            }())
            let diag2 = SKShapeNode(path: {
                let path = CGMutablePath(); path.move(to: p3); path.addLine(to: p4); return path
            }())
            for d in [diag1, diag2] {
                d.strokeColor = SKColor(white: 0.0, alpha: 0.6)
                d.lineWidth = 1.2
                gridNode.addChild(d)
            }
        }
    }

    private func renderAllPieces() {
        piecesNode.removeAllChildren()
        for row in 0..<BanqiGame.numberOfRows {
            for col in 0..<BanqiGame.numberOfColumns {
                let pos = BanqiPosition(column: col, row: row)
                if let node = makePieceNode(at: pos) {
                    piecesNode.addChild(node)
                }
            }
        }
    }

    private func positionAllNodes() {
        for node in piecesNode.children {
            guard let pieceNode = node as? SKNode,
                  let colNum = pieceNode.userData?["col"] as? NSNumber,
                  let rowNum = pieceNode.userData?["row"] as? NSNumber else { continue }
            let pos = BanqiPosition(column: colNum.intValue, row: rowNum.intValue)
            pieceNode.position = centerPoint(for: pos)
        }
        highlightsNode.removeAllChildren()
        drawHighlights(for: legalTargets)
    }

    // MARK: - Node creation

    private func makePieceNode(at position: BanqiPosition) -> SKNode? {
        guard let piece = game.piece(at: position) else { return nil }
        let container = SKNode()
        let dict = NSMutableDictionary()
        dict["col"] = NSNumber(value: position.column)
        dict["row"] = NSNumber(value: position.row)
        container.userData = dict
        container.position = centerPoint(for: position)
        
        // Add accessibility label for the piece
        if piece.isFaceUp {
            container.accessibilityLabel = "\(piece.color == .red ? "Red" : "Black") \(pieceTypeName(piece.type)) at \(coord(position))"
        } else {
            container.accessibilityLabel = "Face down piece at \(coord(position))"
        }

        let radius = tileSize * 0.42
        let base = SKShapeNode(circleOfRadius: radius)
        
        // Enhanced drop shadow with multiple layers
        let shadowRadius = radius * 1.05
        let shadow = SKShapeNode(circleOfRadius: shadowRadius)
        shadow.fillColor = SKColor(white: 0, alpha: 0.15)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 1, y: -radius * 0.15)
        shadow.zPosition = 0.3
        container.addChild(shadow)
        
        // Inner shadow for depth
        let innerShadow = SKShapeNode(circleOfRadius: radius * 0.95)
        innerShadow.fillColor = .clear
        innerShadow.strokeColor = SKColor(white: 0, alpha: 0.1)
        innerShadow.lineWidth = 1
        innerShadow.position = CGPoint(x: 0, y: -1)
        innerShadow.zPosition = 0.4
        container.addChild(innerShadow)

        base.fillColor = piece.isFaceUp ? SKColor(white: 0.98, alpha: 1) : SKColor(red: 0.10, green: 0.25, blue: 0.63, alpha: 1)
        base.strokeColor = piece.isFaceUp ? SKColor(white: 0.2, alpha: 0.8) : SKColor(white: 0.1, alpha: 0.9)
        base.lineWidth = 2.2
        base.zPosition = 1
        container.addChild(base)
        
        // Subtle highlight for depth
        let highlight = SKShapeNode(circleOfRadius: radius * 0.7)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.1)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -radius * 0.15, y: radius * 0.15)
        highlight.zPosition = 1.1
        container.addChild(highlight)

        if piece.isFaceUp {
            // Try to use image asset; fall back to character label
            if let sprite = makePieceSprite(for: piece, radius: radius) {
                sprite.zPosition = 2
                container.addChild(sprite)
            } else {
                let label = SKLabelNode(fontNamed: "PingFangTC-Semibold")
                label.fontSize = radius
                label.fontColor = (piece.color == .red) ? SKColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1) : SKColor(white: 0.08, alpha: 1)
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.text = characterFor(piece: piece)
                label.zPosition = 2
                container.addChild(label)
            }
        } else {
            // Face down back image if available
            let backName = "piece_back"
            if let backImage = UIImage(named: backName) {
                let texture = SKTexture(image: backImage)
                let sprite = SKSpriteNode(texture: texture)
                let side = radius * 1.6
                sprite.size = CGSize(width: side, height: side)
                sprite.zPosition = 2
                container.addChild(sprite)
            }
        }

        return container
    }

    private func makePieceSprite(for piece: BanqiPiece, radius: CGFloat) -> SKSpriteNode? {
        // Only use an image if present to avoid SpriteKit's red-X placeholder
        let name = assetName(for: piece)
        guard let image = UIImage(named: name) else { return nil }
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        let side = radius * 1.8
        sprite.size = CGSize(width: side, height: side)
        return sprite
    }

    private func assetName(for piece: BanqiPiece) -> String {
        let type: String
        switch piece.type {
        case .general: type = "general"
        case .advisor: type = "advisor"
        case .elephant: type = "elephant"
        case .chariot: type = "chariot"
        case .horse: type = "horse"
        case .cannon: type = "cannon"
        case .soldier: type = "soldier"
        }
        let color = piece.color == .red ? "red" : "black"
        return "piece_char_\(type)_\(color)"
    }

    private func characterFor(piece: BanqiPiece) -> String {
        switch (piece.type, piece.color) {
        case (.general, .red): return "帥"
        case (.general, .black): return "將"
        case (.advisor, .red): return "仕"
        case (.advisor, .black): return "士"
        case (.elephant, .red): return "相"
        case (.elephant, .black): return "象"
        case (.chariot, .red): return "俥"
        case (.chariot, .black): return "車"
        case (.horse, .red): return "傌"
        case (.horse, .black): return "馬"
        case (.cannon, .red): return "炮"
        case (.cannon, .black): return "砲"
        case (.soldier, .red): return "兵"
        case (.soldier, .black): return "卒"
        }
    }
    
    private func pieceTypeName(_ type: BanqiPieceType) -> String {
        switch type {
        case .general: return "General"
        case .advisor: return "Advisor"
        case .elephant: return "Elephant"
        case .chariot: return "Chariot"
        case .horse: return "Horse"
        case .cannon: return "Cannon"
        case .soldier: return "Soldier"
        }
    }

    private func centerPoint(for position: BanqiPosition) -> CGPoint {
        let draw = toDrawGridIndices(from: position)
        let x = boardOrigin.x + (CGFloat(draw.x) + 0.5) * tileSize
        let y = boardOrigin.y + (CGFloat(draw.y) + 0.5) * tileSize
        return CGPoint(x: x, y: y)
    }

    private func positionFor(point: CGPoint) -> BanqiPosition? {
        let drawX = Int((point.x - boardOrigin.x) / tileSize)
        let drawY = Int((point.y - boardOrigin.y) / tileSize)
        let renderCols = BanqiGame.numberOfRows
        let renderRows = BanqiGame.numberOfColumns
        guard drawX >= 0 && drawX < renderCols && drawY >= 0 && drawY < renderRows else { return nil }
        let p = toBoardPosition(fromDrawX: drawX, drawY: drawY)
        guard game.isInsideBoard(p) else { return nil }
        return p
    }

    private func toDrawGridIndices(from boardPos: BanqiPosition) -> (x: Int, y: Int) {
        // Rotate clockwise: drawX grows with original row; drawY grows with inverse of original column
        let x = boardPos.row
        let y = BanqiGame.numberOfColumns - 1 - boardPos.column
        return (x, y)
    }

    private func toBoardPosition(fromDrawX x: Int, drawY y: Int) -> BanqiPosition {
        let col = BanqiGame.numberOfColumns - 1 - y
        let row = x
        return BanqiPosition(column: col, row: row)
    }

    private func gridPosition(from nodes: [SKNode]) -> BanqiPosition? {
        for node in nodes {
            if let name = node.name, name.hasPrefix("cell_") {
                let parts = name.split(separator: "_")
                if parts.count == 3, let c = Int(parts[1]), let r = Int(parts[2]) {
                    let pos = BanqiPosition(column: c, row: r)
                    if game.isInsideBoard(pos) { return pos }
                }
            }
        }
        return nil
    }

    // MARK: - Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Handle New Game button
        let nodesAtPoint = nodes(at: location)
        if nodesAtPoint.contains(where: { $0 == newGameButton }) {
            resetGame()
            return
        }
        

        
        // Handle Settings panel buttons
        if settingsPanel.children.count > 0 {
            for node in nodesAtPoint {
                if node.name == "closeSettingsButton" {
                    hideSettingsPanel()
                    return
                }
                if let name = node.name, name.hasPrefix("setting_") {
                    // Handle setting toggle
                    hideSettingsPanel()
                    return
                }
            }
        }
        
        // Handle Tutorial overlay
        if tutorialOverlay.children.count > 0 {
            for node in nodesAtPoint {
                if node.name == "startTutorialButton" {
                    hideTutorialOverlay()
                    return
                }
            }
        }

        // Only handle taps on the board area or on actual pieces
        if let hitPos = gridPosition(from: nodesAtPoint) {
            handleTap(at: hitPos)
        } else if let gridPos = positionFor(point: location) {
            // Additional safety checks to prevent taps on captured pieces area or outside board
            let isWithinBoardBounds = location.x >= boardOrigin.x && 
                                    location.x <= boardOrigin.x + CGFloat(BanqiGame.numberOfRows) * tileSize &&
                                    location.y >= boardOrigin.y && 
                                    location.y <= boardOrigin.y + CGFloat(BanqiGame.numberOfColumns) * tileSize
            
            if isWithinBoardBounds && (game.piece(at: gridPos) != nil || (selectedPosition != nil && legalTargets.contains(gridPos))) {
                handleTap(at: gridPos)
            }
        }
    }

    private func handleTap(at gridPos: BanqiPosition) {
        // If there is an active selection and this tap is a legal target, perform it
        if let selected = selectedPosition {
            if legalTargets.contains(gridPos) {
                performMoveOrCapture(from: selected, to: gridPos)
                return
            }
        }

        // Otherwise, consider flip or selection
        if let piece = game.piece(at: gridPos) {
            if piece.isFaceUp == false {
                // Attempt flip if legal
                let legal = game.legalActionsForSideToMove().contains { action in
                    if case .flip(let at) = action { return at == gridPos } else { return false }
                }
                if legal {
                    apply(action: .flip(at: gridPos))
                    return
                }
            } else {
                // Select own piece if it's that side to move (or no side yet when all flips allowed?)
                if let stm = game.sideToMove, piece.color == stm {
                    select(position: gridPos)
                    return
                } else if game.sideToMove == nil {
                    // Before colors are set, only flips are legal; ignore selection
                }
            }
        }

        // Default: clear selection
        clearSelection()
    }

    private func select(position: BanqiPosition) {
        guard let piece = game.piece(at: position), piece.isFaceUp else { return }
        selectedPosition = position
        legalTargets = game.legalMovesAndCaptures(for: piece, at: position).compactMap { action in
            switch action {
            case .move(_, let to): return to
            case .capture(_, let to): return to
            default: return nil
            }
        }
        drawHighlights(for: legalTargets)
        
        // Add selection border
        removeSelectionBorder()
        let border = SKShapeNode(circleOfRadius: tileSize * 0.5)
        border.strokeColor = SKColor.yellow
        border.lineWidth = 3
        border.position = centerPoint(for: position)
        border.zPosition = 3
        selectionBorder = border
        addChild(border)
    }
    
    private func removeSelectionBorder() {
        selectionBorder?.removeFromParent()
        selectionBorder = nil
    }

    private func clearSelection() {
        selectedPosition = nil
        legalTargets = []
        highlightsNode.removeAllChildren()
        removeSelectionBorder()
    }

    private func drawHighlights(for targets: [BanqiPosition]) {
        highlightsNode.removeAllChildren()
        for target in targets {
            let dot = SKShapeNode(circleOfRadius: tileSize * 0.15)
            dot.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.8)
            dot.strokeColor = SKColor(white: 0, alpha: 0.2)
            dot.lineWidth = 1
            dot.position = centerPoint(for: target)
            dot.zPosition = 0.5
            highlightsNode.addChild(dot)
        }
    }

    private func performMoveOrCapture(from: BanqiPosition, to: BanqiPosition) {
        let piece = game.piece(at: from)!
        let actions = game.legalMovesAndCaptures(for: piece, at: from)
        if actions.contains(where: { if case .move(let f, let t) = $0 { return f == from && t == to } else { return false } }) {
            apply(action: .move(from: from, to: to))
        } else if actions.contains(where: { if case .capture(let f, let t) = $0 { return f == from && t == to } else { return false } }) {
            apply(action: .capture(from: from, to: to))
        }
    }

    private func apply(action: BanqiAction) {
        clearSelection()
        
        switch action {
        case .flip(let at):
            if game.perform(.flip(at: at)) {
                // Flip animation: replace node and scale up uniformly (avoid scaleY=0 bug)
                removePieceNode(at: at)
                if let node = makePieceNode(at: at) {
                    node.setScale(0.0)
                    piecesNode.addChild(node)
                    node.run(SKAction.scale(to: 1.0, duration: 0.18).withTimingMode(.easeInEaseOut))
                }
            }
        case .move(let from, let to):
            if game.perform(.move(from: from, to: to)) {
                movePieceNode(from: from, to: to)
                playMoveSound()
            }
        case .capture(let from, let to):
            if game.perform(.capture(from: from, to: to)) {
                capturePieceNode(from: from, to: to)
                playCaptureSound()
            }
        }
        updateStatus()
        updateCapturedPieces()
    }

    private func removePieceNode(at position: BanqiPosition) {
        if let node = nodeFor(position: position) {
            node.removeFromParent()
        }
    }

    private func nodeFor(position: BanqiPosition) -> SKNode? {
        for node in piecesNode.children {
            if let colNum = node.userData?["col"] as? NSNumber,
               let rowNum = node.userData?["row"] as? NSNumber,
               colNum.intValue == position.column, rowNum.intValue == position.row {
                return node
            }
        }
        return nil
    }

    private func movePieceNode(from: BanqiPosition, to: BanqiPosition) {
        if let node = nodeFor(position: from) {
            let moveAction = SKAction.move(to: centerPoint(for: to), duration: 0.25)
            moveAction.timingMode = .easeInEaseOut
            node.run(moveAction)
            
            // Update position in userData
            if let userData = node.userData {
                userData["col"] = NSNumber(value: to.column)
                userData["row"] = NSNumber(value: to.row)
            }
        }
    }

    private func capturePieceNode(from: BanqiPosition, to: BanqiPosition) {
        // Remove target with enhanced animation
        if let captured = nodeFor(position: to) {
            let fade = SKAction.fadeOut(withDuration: 0.25)
            let scale = SKAction.scale(to: 0.3, duration: 0.25)
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 0.25)
            let group = SKAction.group([fade, scale, rotate])
            captured.run(group) { [weak captured] in
                captured?.removeFromParent()
            }
        }
        
        // Move attacker with bounce effect
        if let attacker = nodeFor(position: from) {
            let moveAction = SKAction.move(to: centerPoint(for: to), duration: 0.3)
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
            let bounce = SKAction.sequence([scaleUp, scaleDown])
            let group = SKAction.group([moveAction, bounce])
            attacker.run(group)
            
            // Update position in userData
            if let userData = attacker.userData {
                userData["col"] = NSNumber(value: to.column)
                userData["row"] = NSNumber(value: to.row)
            }
        }
    }

    private func updateStatus() {
        if game.gameOver {
            if let winner = game.winner {
                statusLabel.text = winner == .red ? "RED ARMY VICTORY!" : "BLACK ARMY VICTORY!"
                statusLabel.fontColor = winner == .red ? .red : .black
                showEndgameBanner(winner: winner)
            } else {
                statusLabel.text = "DRAW"
                statusLabel.fontColor = .darkGray
            }
        } else {
            let currentPlayer = game.sideToMove
            if let currentPlayer = currentPlayer {
                statusLabel.text = currentPlayer == .red ? "RED ARMY TO MOVE" : "BLACK ARMY TO MOVE"
                statusLabel.fontColor = currentPlayer == .red ? .red : .black
                
                // Update current player indicator
                currentPlayerIndicator.fillColor = currentPlayer == .red ? .red : .black
                currentPlayerIndicator.position = CGPoint(x: 60, y: currentPlayer == .red ? size.height - 40 : size.height - 60)
                
                // Update player label colors to show current player
                player1Label.fontColor = currentPlayer == .red ? .red : .gray
                player2Label.fontColor = currentPlayer == .black ? .black : .gray
            } else {
                statusLabel.text = "FLIP A PIECE TO START"
                statusLabel.fontColor = .darkGray
                
                // Reset player label colors
                player1Label.fontColor = .gray
                player2Label.fontColor = .gray
            }
            
            hideEndgameBanner()
        }
    }



    private func coord(_ p: BanqiPosition) -> String {
        let files = ["a", "b", "c", "d"]
        let file = files[max(0, min(3, p.column))]
        // ranks start at 1 from bottom by our coordinate system
        let rank = p.row + 1
        return "\(file)\(rank)"
    }

    // MARK: - Endgame banner

    private func showEndgameBanner(winner: BanqiPieceColor) {
        endgameBanner.removeAllChildren()
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: 120))
        background.fillColor = SKColor(white: 0.95, alpha: 0.95)
        background.strokeColor = winner == .red ? SKColor.red : SKColor.black
        background.lineWidth = 3
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 10
        endgameBanner.addChild(background)
        
        // Winner text
        let winnerText = SKLabelNode(fontNamed: "SFUIDisplay-Bold")
        winnerText.text = winner == .red ? "RED WINS!" : "BLACK WINS!"
        winnerText.fontSize = 28
        winnerText.fontColor = winner == .red ? SKColor.red : SKColor.black
        winnerText.horizontalAlignmentMode = .center
        winnerText.verticalAlignmentMode = .center
        winnerText.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        winnerText.zPosition = 11
        endgameBanner.addChild(winnerText)
        
        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
        subtitle.text = "Tap 'New' to start a new game"
        subtitle.fontSize = 16
        subtitle.fontColor = SKColor(white: 0.3, alpha: 1)
        subtitle.horizontalAlignmentMode = .center
        subtitle.verticalAlignmentMode = .center
        subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        subtitle.zPosition = 11
        endgameBanner.addChild(subtitle)
        
        // Animate in
        endgameBanner.alpha = 0
        endgameBanner.setScale(0.8)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.3)
        endgameBanner.run(SKAction.group([fadeIn, scaleIn]))
    }
    
    private func hideEndgameBanner() {
        endgameBanner.removeAllChildren()
    }
    

    
    // MARK: - Settings
    
    private func showSettingsPanel() {
        settingsPanel.removeAllChildren()
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: 300))
        background.fillColor = SKColor(white: 0.95, alpha: 0.95)
        background.strokeColor = SKColor(white: 0.2, alpha: 1)
        background.lineWidth = 2
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 10
        settingsPanel.addChild(background)
        
        // Title
        let title = SKLabelNode(fontNamed: "SFUIDisplay-Bold")
        title.text = "Settings"
        title.fontSize = 24
        title.fontColor = SKColor(white: 0.1, alpha: 1)
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 120)
        title.zPosition = 11
        settingsPanel.addChild(title)
        
        // Close button
        let closeButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
        closeButton.text = "✕"
        closeButton.fontSize = 20
        closeButton.fontColor = SKColor(white: 0.3, alpha: 1)
        closeButton.horizontalAlignmentMode = .center
        closeButton.verticalAlignmentMode = .center
        closeButton.name = "closeSettingsButton"
        closeButton.zPosition = 11
        closeButton.position = CGPoint(x: size.width / 2 + 140, y: size.height / 2 + 120)
        settingsPanel.addChild(closeButton)
        
        // Settings options
        let options = [
            ("Sound Effects", "🔊"),
            ("Move Hints", "💡"),
            ("Show Legal Moves", "🎯"),
            ("Auto-save", "💾"),
            ("Board Theme: \(currentBoardTheme)", "🎨"),
            ("Piece Style: \(currentPieceStyle)", "♟")
        ]
        
        for (index, (text, icon)) in options.enumerated() {
            let optionButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
            optionButton.text = "\(icon) \(text)"
            optionButton.fontSize = 16
            optionButton.fontColor = SKColor(white: 0.3, alpha: 1)
            optionButton.horizontalAlignmentMode = .left
            optionButton.verticalAlignmentMode = .center
            optionButton.name = "setting_\(index)"
            optionButton.zPosition = 11
            optionButton.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2 + 60 - CGFloat(index * 30))
            settingsPanel.addChild(optionButton)
        }
        
        // Animate in
        settingsPanel.alpha = 0
        settingsPanel.setScale(0.8)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.3)
        settingsPanel.run(SKAction.group([fadeIn, scaleIn]))
    }
    
    private func hideSettingsPanel() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleOut = SKAction.scale(to: 0.8, duration: 0.2)
        settingsPanel.run(SKAction.group([fadeOut, scaleOut])) {
            self.settingsPanel.removeAllChildren()
        }
    }
    
    // MARK: - Tutorial
    
    private func showTutorialOverlay() {
        tutorialOverlay.removeAllChildren()
        
        // Background overlay
        let background = SKShapeNode(rectOf: size)
        background.fillColor = SKColor(white: 0, alpha: 0.7)
        background.strokeColor = .clear
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 15
        tutorialOverlay.addChild(background)
        
        // Tutorial content
        let content = SKNode()
        content.zPosition = 16
        tutorialOverlay.addChild(content)
        
        // Title
        let title = SKLabelNode(fontNamed: "SFUIDisplay-Bold")
        title.text = "Welcome to Chinese Chase!"
        title.fontSize = 24
        title.fontColor = SKColor.white
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        content.addChild(title)
        
        // Instructions
        let instructions = [
            "• Tap face-down pieces to flip them",
            "• Tap your pieces to select them",
            "• Tap highlighted squares to move",
            "• Capture opponent pieces to win",
            "• Use undo/redo buttons to go back"
        ]
        
        for (index, instruction) in instructions.enumerated() {
            let label = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
            label.text = instruction
            label.fontSize = 16
            label.fontColor = SKColor.white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40 - CGFloat(index * 25))
            content.addChild(label)
        }
        
        // Start button
        let startButton = SKLabelNode(fontNamed: "SFUIDisplay-Bold")
        startButton.text = "Start Playing"
        startButton.fontSize = 18
        startButton.fontColor = SKColor.white
        startButton.horizontalAlignmentMode = .center
        startButton.verticalAlignmentMode = .center
        startButton.name = "startTutorialButton"
        startButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        content.addChild(startButton)
        
        // Animate in
        tutorialOverlay.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        tutorialOverlay.run(fadeIn)
    }
    
    private func hideTutorialOverlay() {
        showTutorial = false
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        tutorialOverlay.run(fadeOut) {
            self.tutorialOverlay.removeAllChildren()
        }
    }
    
    // MARK: - UserDefaults
    
    private func loadUserDefaults() {
        let defaults = UserDefaults.standard
        currentBoardTheme = defaults.string(forKey: "boardTheme") ?? "classic"
        currentPieceStyle = defaults.string(forKey: "pieceStyle") ?? "characters"
        showTutorial = false // Tutorial disabled
    }
    
    private func saveUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(currentBoardTheme, forKey: "boardTheme")
        defaults.set(currentPieceStyle, forKey: "pieceStyle")
        defaults.set(false, forKey: "showTutorial")
    }
    
    // MARK: - Sound Effects
    
    private func playMoveSound() {
        // Create a simple beep sound for moves
        let frequency: Float = 800.0
        let duration: Float = 0.1
        let sampleRate: Float = 44100.0
        let frameCount = Int(duration * sampleRate)
        
        var audioData = [Float](repeating: 0.0, count: frameCount)
        for i in 0..<frameCount {
            let time = Float(i) / sampleRate
            audioData[i] = sin(2.0 * Float.pi * frequency * time) * 0.3
        }
        
        // Convert to audio buffer and play
        // Note: This is a simplified implementation. In a real app, you'd use pre-recorded sounds.
    }
    
    private func playCaptureSound() {
        // Create a lower frequency sound for captures
        let frequency: Float = 400.0
        let duration: Float = 0.2
        let sampleRate: Float = 44100.0
        let frameCount = Int(duration * sampleRate)
        
        var audioData = [Float](repeating: 0.0, count: frameCount)
        for i in 0..<frameCount {
            let time = Float(i) / sampleRate
            audioData[i] = sin(2.0 * Float.pi * frequency * time) * 0.5
        }
        
        // Convert to audio buffer and play
        // Note: This is a simplified implementation. In a real app, you'd use pre-recorded sounds.
    }

    // MARK: - New game

    private func resetGame() {
        game = BanqiGame()
        if useDeterministicSeed {
            game = BanqiGame(seed: currentSeed)
        }
        
        // Clear UI
        piecesNode.removeAllChildren()
        highlightsNode.removeAllChildren()
        selectedPosition = nil
        legalTargets = []
        
        // Reset board
        layoutBoard()
        renderBoard()
        renderAllPieces()
        positionAllNodes()
        updateStatus()
        updateCapturedPieces()
    }

    private func updateCapturedPieces() {
        // Clear existing captured pieces
        capturedPiecesNode.removeAllChildren()
        capturedRedPieces.removeAll()
        capturedBlackPieces.removeAll()
        
        // Get captured pieces from game state
        let capturedRed = game.capturedPieces(for: .red)
        let capturedBlack = game.capturedPieces(for: .black)
        
        // Position for captured pieces display (bottom area)
        let startX: CGFloat = 20
        let startY: CGFloat = 60
        let pieceSpacing: CGFloat = 35
        let rowSpacing: CGFloat = 40
        
        // Display captured red pieces (top row)
        for (index, pieceType) in capturedRed.enumerated() {
            let pieceNode = makeCapturedPieceNode(type: pieceType, color: .red)
            pieceNode.position = CGPoint(x: startX + CGFloat(index) * pieceSpacing, y: startY + rowSpacing)
            capturedPiecesNode.addChild(pieceNode)
            capturedRedPieces.append(pieceNode)
        }
        
        // Display captured black pieces (bottom row)
        for (index, pieceType) in capturedBlack.enumerated() {
            let pieceNode = makeCapturedPieceNode(type: pieceType, color: .black)
            pieceNode.position = CGPoint(x: startX + CGFloat(index) * pieceSpacing, y: startY)
            capturedPiecesNode.addChild(pieceNode)
            capturedBlackPieces.append(pieceNode)
        }
    }
    
    private func makeCapturedPieceNode(type: BanqiPieceType, color: BanqiPieceColor) -> SKNode {
        let container = SKNode()
        
        // Background circle
        let background = SKShapeNode(circleOfRadius: 12)
        background.fillColor = .white
        background.strokeColor = color == .red ? .red : .black
        background.lineWidth = 2
        container.addChild(background)
        
        // Chinese character
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 14
        label.fontColor = color == .red ? .red : .black
        label.text = type.symbol
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
}

private extension SKAction {
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
