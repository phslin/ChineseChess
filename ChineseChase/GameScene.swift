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

    private let game = BanqiGame()

    private var boardNode = SKNode()
    private var gridNode = SKNode()
    private var piecesNode = SKNode()
    private var highlightsNode = SKNode()
    private var statusLabel = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var newGameButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var logLabel = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var clearLogButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var seedLabel = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var seedToggleButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var undoButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var redoButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var settingsButton = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var settingsPanel = SKNode()
    private var tutorialOverlay = SKNode()
    private var player1Label = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
    private var player2Label = SKLabelNode(fontNamed: "SFUIDisplay-Regular")
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
    
    // Undo/redo system
    private var gameHistory: [BanqiGame] = []
    private var currentHistoryIndex = -1
    private let maxHistorySize = 50

    private var tileSize: CGFloat = 64
    private var boardOrigin: CGPoint = .zero
    private var selectedPosition: BanqiPosition?
    private var legalTargets: [BanqiPosition] = []
    private var moveLog: [String] = []
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

        statusLabel.fontSize = 18
        statusLabel.fontColor = SKColor(white: 0.1, alpha: 1)
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 8)
        addChild(statusLabel)
        
        logLabel.fontSize = 13
        logLabel.fontColor = SKColor(white: 0.15, alpha: 1)
        logLabel.horizontalAlignmentMode = .center
        logLabel.verticalAlignmentMode = .bottom
        logLabel.numberOfLines = 2
        logLabel.preferredMaxLayoutWidth = size.width * 0.9
        logLabel.position = CGPoint(x: size.width / 2, y: 10)
        addChild(logLabel)

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

        // Clear log button
        clearLogButton.text = "Clear"
        clearLogButton.fontSize = 14
        clearLogButton.fontColor = SKColor(white: 0.3, alpha: 1)
        clearLogButton.horizontalAlignmentMode = .right
        clearLogButton.verticalAlignmentMode = .bottom
        clearLogButton.name = "clearLogButton"
        clearLogButton.zPosition = 5
        clearLogButton.position = CGPoint(x: size.width - 16, y: 10)
        addChild(clearLogButton)

        // Seed controls
        seedLabel.text = "Seed: 12345"
        seedLabel.fontSize = 12
        seedLabel.fontColor = SKColor(white: 0.4, alpha: 1)
        seedLabel.horizontalAlignmentMode = .left
        seedLabel.verticalAlignmentMode = .bottom
        seedLabel.position = CGPoint(x: 16, y: 30)
        addChild(seedLabel)
        
        seedToggleButton.text = "Random"
        seedToggleButton.fontSize = 12
        seedToggleButton.fontColor = SKColor(white: 0.4, alpha: 1)
        seedToggleButton.horizontalAlignmentMode = .left
        seedToggleButton.verticalAlignmentMode = .bottom
        seedToggleButton.name = "seedToggleButton"
        seedToggleButton.zPosition = 5
        seedToggleButton.position = CGPoint(x: 16, y: 50)
        addChild(seedToggleButton)
        
        // Undo/Redo buttons
        undoButton.text = "↶"
        undoButton.fontSize = 16
        undoButton.fontColor = SKColor(white: 0.4, alpha: 1)
        undoButton.horizontalAlignmentMode = .center
        undoButton.verticalAlignmentMode = .bottom
        undoButton.name = "undoButton"
        undoButton.zPosition = 5
        undoButton.position = CGPoint(x: size.width - 60, y: size.height - 16)
        addChild(undoButton)
        
        redoButton.text = "↷"
        redoButton.fontSize = 16
        redoButton.fontColor = SKColor(white: 0.4, alpha: 1)
        redoButton.horizontalAlignmentMode = .center
        redoButton.verticalAlignmentMode = .bottom
        redoButton.name = "redoButton"
        redoButton.zPosition = 5
        redoButton.position = CGPoint(x: size.width - 40, y: size.height - 16)
        addChild(redoButton)
        
        // Settings button
        settingsButton.text = "⚙"
        settingsButton.fontSize = 16
        settingsButton.fontColor = SKColor(white: 0.4, alpha: 1)
        settingsButton.horizontalAlignmentMode = .center
        settingsButton.verticalAlignmentMode = .bottom
        settingsButton.name = "settingsButton"
        settingsButton.zPosition = 5
        settingsButton.position = CGPoint(x: size.width - 80, y: size.height - 16)
        addChild(settingsButton)
        
        // Settings panel
        addChild(settingsPanel)
        
        // Player labels
        player1Label.text = "Player 1 (Red)"
        player1Label.fontSize = 14
        player1Label.fontColor = SKColor.red
        player1Label.horizontalAlignmentMode = .left
        player1Label.verticalAlignmentMode = .top
        player1Label.position = CGPoint(x: 16, y: size.height - 40)
        addChild(player1Label)
        
        player2Label.text = "Player 2 (Black)"
        player2Label.fontSize = 14
        player2Label.fontColor = SKColor.black
        player2Label.horizontalAlignmentMode = .left
        player2Label.verticalAlignmentMode = .top
        player2Label.position = CGPoint(x: 16, y: size.height - 60)
        addChild(player2Label)
        
        // Tutorial overlay
        addChild(tutorialOverlay)
        
        layoutBoard()
        renderBoard()
        renderAllPieces()
        updateStatus()
        
        // Show tutorial on first run
        if showTutorial {
            showTutorialOverlay()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 12)
        logLabel.position = CGPoint(x: size.width / 2, y: 12)
        newGameButton.position = CGPoint(x: 16, y: size.height - 16)
        clearLogButton.position = CGPoint(x: size.width - 16, y: 10)
        seedLabel.position = CGPoint(x: 16, y: 30)
        seedToggleButton.position = CGPoint(x: 16, y: 50)
        undoButton.position = CGPoint(x: size.width - 60, y: size.height - 16)
        redoButton.position = CGPoint(x: size.width - 40, y: size.height - 16)
        layoutBoard()
        renderBoard()
        positionAllNodes()
        updateStatus()
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
        
        // Handle Clear Log button
        if nodesAtPoint.contains(where: { $0 == clearLogButton }) {
            moveLog.removeAll()
            updateLogLabel()
            return
        }
        
        // Handle Seed Toggle button
        if nodesAtPoint.contains(where: { $0 == seedToggleButton }) {
            useDeterministicSeed.toggle()
            seedToggleButton.text = useDeterministicSeed ? "Deterministic" : "Random"
            return
        }
        
        // Handle Undo button
        if nodesAtPoint.contains(where: { $0 == undoButton }) {
            if currentHistoryIndex > 0 {
                currentHistoryIndex -= 1
                restoreGameState()
            }
            return
        }
        
        // Handle Redo button
        if nodesAtPoint.contains(where: { $0 == redoButton }) {
            if currentHistoryIndex < gameHistory.count - 1 {
                currentHistoryIndex += 1
                restoreGameState()
            }
            return
        }
        
        // Handle Settings button
        if nodesAtPoint.contains(where: { $0 == settingsButton }) {
            showSettingsPanel()
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

        if let hitPos = gridPosition(from: nodesAtPoint) {
            handleTap(at: hitPos)
        } else if let gridPos = positionFor(point: location) {
            handleTap(at: gridPos)
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
    }

    private func clearSelection() {
        selectedPosition = nil
        legalTargets = []
        highlightsNode.removeAllChildren()
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
        
        // Save game state before applying action
        saveGameState()
        
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
                appendLog(.flip(at: at))
            }
        case .move(let from, let to):
            if game.perform(.move(from: from, to: to)) {
                movePieceNode(from: from, to: to)
                appendLog(.move(from: from, to: to))
            }
        case .capture(let from, let to):
            if game.perform(.capture(from: from, to: to)) {
                capturePieceNode(from: from, to: to)
                appendLog(.capture(from: from, to: to))
            }
        }
        updateStatus()
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
        guard let node = nodeFor(position: from) else { return }
        node.userData?["col"] = NSNumber(value: to.column)
        node.userData?["row"] = NSNumber(value: to.row)
        let target = centerPoint(for: to)
        let move = SKAction.move(to: target, duration: 0.22).withTimingMode(.easeInEaseOut)
        node.run(move)
    }

    private func capturePieceNode(from: BanqiPosition, to: BanqiPosition) {
        // Remove target
        if let captured = nodeFor(position: to) {
            let fade = SKAction.fadeOut(withDuration: 0.15)
            let scale = SKAction.scale(to: 0.6, duration: 0.15)
            captured.run(SKAction.group([fade, scale])) { [weak captured] in
                captured?.removeFromParent()
            }
        }
        // Move attacker
        movePieceNode(from: from, to: to)
    }

    private func updateStatus() {
        if game.gameOver {
            if let winner = game.winner {
                statusLabel.text = winner == .red ? "Player 1 (Red) wins!" : "Player 2 (Black) wins!"
                showEndgameBanner(winner: winner)
            } else {
                statusLabel.text = "Game over"
                hideEndgameBanner()
            }
            return
        }
        hideEndgameBanner()
        if let stm = game.sideToMove {
            statusLabel.text = stm == .red ? "Player 1 (Red) to move" : "Player 2 (Black) to move"
        } else {
            statusLabel.text = "Tap a tile to flip a piece"
        }
        updateLogLabel()
    }

    // MARK: - Move log

    private func appendLog(_ action: BanqiAction) {
        let entry: String
        switch action {
        case .flip(let at):
            if let p = game.piece(at: at) {
                entry = "flip \(charForLog(p))@\(coord(at))"
            } else {
                entry = "flip@\(coord(at))"
            }
        case .move(let from, let to):
            if let p = game.piece(at: to) {
                entry = "\(charForLog(p)) \(coord(from))→\(coord(to))"
            } else {
                entry = "move \(coord(from))→\(coord(to))"
            }
        case .capture(let from, let to):
            if let p = game.piece(at: to) {
                entry = "\(charForLog(p)) \(coord(from))×\(coord(to))"
            } else {
                entry = "cap \(coord(from))×\(coord(to))"
            }
        }
        moveLog.append(entry)
        if moveLog.count > 20 { moveLog.removeFirst(moveLog.count - 20) }
        updateLogLabel()
    }

    private func updateLogLabel() {
        let last = moveLog.suffix(8)
        // Break into two lines for readability
        let midpoint = (last.count + 1) / 2
        let top = last.prefix(midpoint).joined(separator: "   ")
        let bottom = last.suffix(last.count - midpoint).joined(separator: "   ")
        logLabel.text = bottom.isEmpty ? top : top + "\n" + bottom
    }

    private func coord(_ p: BanqiPosition) -> String {
        let files = ["a", "b", "c", "d"]
        let file = files[max(0, min(3, p.column))]
        // ranks start at 1 from bottom by our coordinate system
        let rank = p.row + 1
        return "\(file)\(rank)"
    }

    private func charForLog(_ piece: BanqiPiece) -> String {
        characterFor(piece: piece)
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
    
    // MARK: - Undo/Redo
    
    private func saveGameState() {
        // Remove any future history if we're not at the end
        if currentHistoryIndex < gameHistory.count - 1 {
            gameHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        // Create a copy of the current game state
        let gameCopy = BanqiGame(seed: currentSeed)
        gameCopy.board = game.board
        gameCopy.sideToMove = game.sideToMove
        gameCopy.gameOver = game.gameOver
        gameCopy.winner = game.winner
        gameCopy.lastAction = game.lastAction
        
        gameHistory.append(gameCopy)
        currentHistoryIndex = gameHistory.count - 1
        
        // Limit history size
        if gameHistory.count > maxHistorySize {
            gameHistory.removeFirst()
            currentHistoryIndex -= 1
        }
        
        updateUndoRedoButtons()
    }
    
    private func restoreGameState() {
        guard currentHistoryIndex >= 0 && currentHistoryIndex < gameHistory.count else { return }
        
        let savedGame = gameHistory[currentHistoryIndex]
        game.board = savedGame.board
        game.sideToMove = savedGame.sideToMove
        game.gameOver = savedGame.gameOver
        game.winner = savedGame.winner
        game.lastAction = savedGame.lastAction
        
        selectedPosition = nil
        legalTargets.removeAll()
        highlightsNode.removeAllChildren()
        renderAllPieces()
        updateStatus()
        updateUndoRedoButtons()
    }
    
    private func updateUndoRedoButtons() {
        undoButton.fontColor = currentHistoryIndex > 0 ? SKColor(white: 0.4, alpha: 1) : SKColor(white: 0.2, alpha: 0.5)
        redoButton.fontColor = currentHistoryIndex < gameHistory.count - 1 ? SKColor(white: 0.4, alpha: 1) : SKColor(white: 0.2, alpha: 0.5)
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
        showTutorial = defaults.object(forKey: "showTutorial") == nil // Show tutorial on first run
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

    private func resetGame(seed: UInt64? = nil) {
        let seedToUse = useDeterministicSeed ? currentSeed : nil
        game.reset(seed: seedToUse)
        selectedPosition = nil
        legalTargets.removeAll()
        moveLog.removeAll()
        highlightsNode.removeAllChildren()
        
        // Initialize game history
        gameHistory.removeAll()
        currentHistoryIndex = -1
        saveGameState() // Save initial state
        
        renderBoard()
        renderAllPieces()
        updateStatus()
    }
}

private extension SKAction {
    func withTimingMode(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
