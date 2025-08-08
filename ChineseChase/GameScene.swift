//
//  GameScene.swift
//  ChineseChase
//
//  Created by Benson Lin on 8/7/25.
//

import SpriteKit
import GameplayKit

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

    private var tileSize: CGFloat = 64
    private var boardOrigin: CGPoint = .zero
    private var selectedPosition: BanqiPosition?
    private var legalTargets: [BanqiPosition] = []
    private var moveLog: [String] = []

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.1, alpha: 1)
        removeAllChildren()

        boardNode.removeAllChildren()
        piecesNode.removeAllChildren()
        highlightsNode.removeAllChildren()

        addChild(boardNode)
        addChild(gridNode)
        addChild(highlightsNode)
        addChild(piecesNode)

        statusLabel.fontSize = 20
        statusLabel.fontColor = .white
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 12)
        addChild(statusLabel)
        
        logLabel.fontSize = 14
        logLabel.fontColor = SKColor(white: 0.9, alpha: 0.9)
        logLabel.horizontalAlignmentMode = .center
        logLabel.verticalAlignmentMode = .bottom
        logLabel.numberOfLines = 2
        logLabel.preferredMaxLayoutWidth = size.width * 0.9
        logLabel.position = CGPoint(x: size.width / 2, y: 12)
        addChild(logLabel)

        // New Game button
        newGameButton.text = "New"
        newGameButton.fontSize = 16
        newGameButton.fontColor = SKColor(white: 0.95, alpha: 1)
        newGameButton.horizontalAlignmentMode = .left
        newGameButton.verticalAlignmentMode = .top
        newGameButton.name = "newGameButton"
        newGameButton.zPosition = 5
        newGameButton.position = CGPoint(x: 16, y: size.height - 16)
        addChild(newGameButton)

        layoutBoard()
        renderBoard()
        renderAllPieces()
        updateStatus()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - 12)
        logLabel.position = CGPoint(x: size.width / 2, y: 12)
        newGameButton.position = CGPoint(x: 16, y: size.height - 16)
        layoutBoard()
        renderBoard()
        positionAllNodes()
        updateStatus()
    }

    // MARK: - Layout

    private func layoutBoard() {
        let cols = CGFloat(BanqiGame.numberOfColumns)
        let rows = CGFloat(BanqiGame.numberOfRows)
        let usableWidth = size.width * 0.9
        let usableHeight = size.height * 0.82
        tileSize = min(usableWidth / cols, usableHeight / rows)
        let boardWidth = cols * tileSize
        let boardHeight = rows * tileSize
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

        // Board background (beige with thick border to match sample)
        let boardRect = CGRect(x: boardOrigin.x, y: boardOrigin.y, width: CGFloat(cols) * tileSize, height: CGFloat(rows) * tileSize)
        let frameOuter = SKShapeNode(rect: boardRect.insetBy(dx: -10, dy: -10))
        frameOuter.strokeColor = SKColor(white: 0.05, alpha: 1)
        frameOuter.lineWidth = 6
        frameOuter.fillColor = .clear
        boardNode.addChild(frameOuter)

        let background = SKShapeNode(rect: boardRect)
        background.fillColor = SKColor(red: 0.93, green: 0.90, blue: 0.84, alpha: 1)
        background.strokeColor = SKColor(white: 0.0, alpha: 0.8)
        background.lineWidth = 3
        boardNode.addChild(background)

        // Grid tiles (thin dark lines, beige squares)
        for row in 0..<rows {
            for col in 0..<cols {
                let rect = CGRect(x: boardOrigin.x + CGFloat(col) * tileSize,
                                  y: boardOrigin.y + CGFloat(row) * tileSize,
                                  width: tileSize,
                                  height: tileSize)
                let tile = SKShapeNode(rect: rect)
                tile.fillColor = SKColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
                tile.strokeColor = SKColor(white: 0.0, alpha: 0.6)
                tile.lineWidth = 1.2
                tile.name = "cell_\(col)_\(row)"
                gridNode.addChild(tile)
            }
        }

        // Palace-style diagonals in the central 2x2 (visual flair similar to sample)
        if rows >= 4 && cols >= 4 {
            let midCols = [cols/2 - 1, cols/2]
            let midRows = [rows/2 - 1, rows/2]
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

        let radius = tileSize * 0.42
        let base = SKShapeNode(circleOfRadius: radius)
        // Drop shadow
        let shadow = SKShapeNode(circleOfRadius: radius)
        shadow.fillColor = SKColor(white: 0, alpha: 0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -radius * 0.12)
        shadow.zPosition = 0.5
        container.addChild(shadow)

        base.fillColor = piece.isFaceUp ? SKColor(white: 0.98, alpha: 1) : SKColor(red: 0.10, green: 0.25, blue: 0.63, alpha: 1)
        base.strokeColor = piece.isFaceUp ? SKColor(white: 0.2, alpha: 0.8) : SKColor(white: 0.1, alpha: 0.9)
        base.lineWidth = 2.2
        base.zPosition = 1
        container.addChild(base)

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
            let texture = SKTexture(imageNamed: backName)
            if texture.size().width > 2 && texture.size().height > 2 {
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
        let name = assetName(for: piece)
        let texture = SKTexture(imageNamed: name)
        if texture.size().width <= 2 || texture.size().height <= 2 { return nil }
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

    private func centerPoint(for position: BanqiPosition) -> CGPoint {
        let x = boardOrigin.x + (CGFloat(position.column) + 0.5) * tileSize
        let y = boardOrigin.y + (CGFloat(position.row) + 0.5) * tileSize
        return CGPoint(x: x, y: y)
    }

    private func positionFor(point: CGPoint) -> BanqiPosition? {
        let col = Int((point.x - boardOrigin.x) / tileSize)
        let row = Int((point.y - boardOrigin.y) / tileSize)
        let p = BanqiPosition(column: col, row: row)
        guard game.isInsideBoard(p) else { return nil }
        return p
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
        switch action {
        case .flip(let at):
            if game.perform(.flip(at: at)) {
                // Flip animation: replace node
                removePieceNode(at: at)
                if let node = makePieceNode(at: at) {
                    node.setScale(0.0)
                    piecesNode.addChild(node)
                    node.run(SKAction.sequence([
                        SKAction.scaleX(to: 0.0, duration: 0.0),
                        SKAction.scaleX(to: 0.0, duration: 0.05),
                        SKAction.scaleX(to: 1.0, duration: 0.18).withTimingMode(.easeInEaseOut)
                    ]))
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
                statusLabel.text = winner == .red ? "Red wins" : "Black wins"
            } else {
                statusLabel.text = "Game over"
            }
            return
        }
        if let stm = game.sideToMove {
            statusLabel.text = stm == .red ? "Red to move" : "Black to move"
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

    // MARK: - New game

    private func resetGame(seed: UInt64? = nil) {
        game.reset(seed: seed)
        selectedPosition = nil
        legalTargets.removeAll()
        moveLog.removeAll()
        highlightsNode.removeAllChildren()
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
