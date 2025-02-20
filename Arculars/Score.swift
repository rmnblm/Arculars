//
//  Score.swift
//  Arculars
//
//  Created by Roman Blum on 14/03/15.
//  Copyright (c) 2015 RMNBLM. All rights reserved.
//

import SpriteKit

class Score : SKLabelNode {
    
    private var currentScore : Int = 0
    
    init(position: CGPoint) {
        super.init()
        
        self.zPosition = 2
        self.fontName = Fonts.FontNameBold
        self.fontColor = ThemeHandler.Instance.getCurrentColors().ScoreColor
        self.position = position
        self.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        self.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        updateText()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startDecremtTimer(interval: NSTimeInterval) {
        var wait = SKAction.waitForDuration(interval)
        var run = SKAction.runBlock({
            self.decrement()
        })
        runAction(SKAction.repeatActionForever(SKAction.sequence([wait, run])), withKey: "decrementTimer")
    }
    
    func stopDecremtTimer() {
        removeActionForKey("decrementTimer")
    }
    
    private func decrement() {
        if currentScore > 0 {
            currentScore = currentScore - 1
        }
        updateText()
    }
    
    private func updateText() {
        self.text = "SCORE \(currentScore)"
    }
    
    func increaseByWithColor(newScore: Int, color: UIColor) {
        self.currentScore += newScore
        
        var label : SKLabelNode!
        
        if newScore >= 0 {
            label = SKLabelNode(text: "+\(newScore)")
        } else {
            label = SKLabelNode(text: "\(newScore)")
        }
        
        // Calculate position
        var x = (self.frame.width / 2) + (label.frame.width / 2) + 8 
        
        label.position = CGPoint(x: x, y: 0)
        label.fontSize = fontSize
        label.fontColor = color
        label.fontName = Fonts.FontNameBold
        label.xScale = 0.0
        label.yScale = 0.0
        label.zPosition = 1
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        self.addChild(label)
        
        var fadeIn = SKAction.scaleTo(1.0, duration: 0.1)
        var wait = SKAction.waitForDuration(0.2)
        var fadeOut = SKAction.group([SKAction.moveTo(CGPoint(x: (self.frame.width / 2), y: 0), duration: 0.2), SKAction.fadeAlphaTo(0.0, duration: 0.2)])
        var sequence = SKAction.sequence([fadeIn, wait, fadeOut])
        
        label.runAction(sequence, completion: {()
            label.removeFromParent()
            self.updateText()
        })
    }
    
    func getScore() -> Int {
        return currentScore
    }
    
    func reset() {
        currentScore = 0
        updateText()
    }
}