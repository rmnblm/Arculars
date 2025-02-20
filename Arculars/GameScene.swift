//
//  GameScene.swift
//  Arculars
//
//  Created by Roman Blum on 09/03/15.
//  Copyright (c) 2015 RMNBLM. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import GameKit
import AudioToolbox

class GameScene: SKScene, SKPhysicsContactDelegate, TimerBarDelegate, HealthBarDelegate, PowerupDelegate {
    
    // MARK: - GAME SETTINGS
    let initMultiplicatorEasy = 1
    let initMultiplicatorNormal = 2
    let initMultiplicatorHard = 3
    
    let initEndlessHealthEasy = 3
    let initEndlessHealthNormal = 3
    let initEndlessHealthHard = 3
    
    let initTimedTimeEasy = 25.0
    let initTimedTimeNormal = 20.0
    let initTimedTimeHard = 15.0
    
    let initPointsCircleZero = 5
    let initPointsCircleOne = 4
    let initPointsCircleTwo = 3
    let initPointsCircleThree = 2
    let initPointsCircleFour = 1
    
    // MARK: - VARIABLE DECLARATIONS
    weak var sceneDelegate : SceneDelegate?
    
    private let circlePosition : CGPoint!
    private let ballPosition : CGPoint!
    private let scorePosition : CGPoint!
    
    var gameMode : GameMode!
    
    private let hit1 = SKAction.playSoundFileNamed("hit1.wav", waitForCompletion: false)
    private let hit2 = SKAction.playSoundFileNamed("hit2.wav", waitForCompletion: false)
    
    // Node and all it's descendants while playing
    private var rootNode = SKNode()
    
    private var shootArea : SKShapeNode!
    
    private var circles = [Circle]()
    private var availableColors = [UIColor]()
    private var activeBalls = [Ball]()
    private var hitSounds = [SKAction]()
    private var nextBall : Ball!
    private var ballRadius : CGFloat!
    private var score : Score!
    private var powerupDescription : SKLabelNode!
    private var isGameOver = false
    private var currentPowerup : Powerup!
    private var healthBar : HealthBar!
    private var timerBar : TimerBar!
    private var isTimerBarExpired = false
    private var btnStop : SKShapeNode!
    
    private var endlessHealth = 0
    private var timedTime = 0.0
    private var multiplicator = 1
    private var powerupMultiplicator = 1
    
    // Variables for Stats
    private var stats_starttime : NSDate!
    
    // MARK: - SCENE SPECIFIC FUNCTIONS
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize) {
        // Init positions
        var offset : CGFloat = size.height / 12
        circlePosition = CGPoint(x: 0, y: (size.height / 4) - offset)
        ballPosition = CGPoint(x: 0, y: -(size.height / 2) + (2 * offset))
        scorePosition = CGPoint(x: 0, y: (size.height / 2) - offset)
        
        super.init(size: size)
        
        // Setup Scene
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = ThemeHandler.Instance.getCurrentColors().BackgroundColor
        
        // Add Root Node
        addChild(rootNode)
        
        // Init Shoot Area:
        // This is to prevent unattended shooting when opening notification or control center
        shootArea = SKShapeNode(rect: CGRect(x: -frame.width / 2, y: -(frame.height / 2) + 30, width: frame.width, height: frame.height - 60))
        shootArea.lineWidth = 0
        addChild(shootArea)
        
        // Setup Scene Physics
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVectorMake(0, 0)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectMake(-(size.width / 2), -(size.height / 2), size.width, size.height))
        physicsBody?.categoryBitMask = PhysicsCategory.border.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.ball.rawValue
        physicsBody?.collisionBitMask = 0
        physicsBody?.dynamic = true
        
        // Preload sounds
        hitSounds.append(hit1)
        hitSounds.append(hit2)
        
        initScene()
    }

    override func didMoveToView(view: SKView) {
        reset()
        for circle in circles {
            circle.fadeIn()
        }
    }
    
    deinit {
        #if DEBUG
            println("GameScene deinit is called")
        #endif
    }
    
    // MARK: - INITIALIZATION FUNCTIONS
    private func initScene() {
        ballRadius = size.height / 64
        
        score = Score(position: scorePosition)
        score.fontSize = size.height / 20
        rootNode.addChild(score)
        
        powerupDescription = SKLabelNode()
        powerupDescription.fontColor = ThemeHandler.Instance.getCurrentColors().PowerupColor
        powerupDescription.fontName = Fonts.FontNameLight
        powerupDescription.fontSize = size.height / 64
        powerupDescription.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        powerupDescription.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        powerupDescription.position = CGPoint(x: scorePosition.x, y: scorePosition.y - score.frame.height)
        addChild(powerupDescription)
        
        var stopLabel = SKLabelNode(text: "X")
        stopLabel.fontSize = size.height / 20
        stopLabel.fontName = "GillSans-Light"
        stopLabel.fontColor = ThemeHandler.Instance.getCurrentColors().ScoreColor
        stopLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        stopLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        btnStop = SKShapeNode(rectOfSize: CGSize(width: stopLabel.frame.width * 1.5, height: stopLabel.frame.height * 2))
        btnStop.addChild(stopLabel)
        btnStop.position = CGPoint(x: (size.width / 2) - (size.width / 16), y: scorePosition.y)
        btnStop.lineWidth = 0
        rootNode.addChild(btnStop)
    }
    
    // MARK: - RESET FUNCTIONS
    private func reset() {
        isTimerBarExpired = false
        
        score?.reset()
        StatsHandler.updateLastscore(0, gameMode: gameMode)
        
        currentPowerup = nil;
        healthBar?.removeFromParent()
        timerBar?.removeFromParent()
        
        ///////
        var randclockwise = getRandomBoolean()
        var difficulty = SettingsHandler.getDifficulty()
        switch difficulty {
        case .Easy:
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorTwo, clockwise: randclockwise, points: initPointsCircleTwo).setSpeed(1.9, max: 2.3)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorThree, clockwise: !randclockwise, points: initPointsCircleThree).setSpeed(1.7, max: 2.1)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorFour, clockwise: randclockwise, points: initPointsCircleFour).setSpeed(1.5, max: 1.9)
            
            multiplicator = initMultiplicatorEasy
            timedTime = initTimedTimeEasy
            endlessHealth = initEndlessHealthEasy
            break
        case .Normal:
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorOne, clockwise: randclockwise, points: initPointsCircleOne).setSpeed(2.2, max: 2.6)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorTwo, clockwise: !randclockwise, points: initPointsCircleTwo).setSpeed(2.0, max: 2.4)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorThree, clockwise: randclockwise, points: initPointsCircleThree).setSpeed(1.8, max: 2.2)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorFour, clockwise: !randclockwise, points: initPointsCircleFour).setSpeed(1.6, max: 2.0)
            
            multiplicator = initMultiplicatorNormal
            timedTime = initTimedTimeNormal
            endlessHealth = initEndlessHealthNormal
            break
        case .Hard:
            addCircle(ThemeHandler.Instance.getCurrentColors().DisabledColor, clockwise: randclockwise, points: initPointsCircleZero).setSpeed(2.3, max: 2.8)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorOne, clockwise: !randclockwise, points: initPointsCircleOne).setSpeed(2.0, max: 2.5)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorTwo, clockwise: randclockwise, points: initPointsCircleTwo).setSpeed(1.8, max: 2.3)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorThree, clockwise: !randclockwise, points: initPointsCircleThree).setSpeed(1.6, max: 2.1)
            addCircle(ThemeHandler.Instance.getCurrentColors().AppColorFour, clockwise: randclockwise, points: initPointsCircleFour).setSpeed(1.4, max: 1.9)
            
            multiplicator = initMultiplicatorHard
            timedTime = initTimedTimeHard
            endlessHealth = initEndlessHealthHard
            break
        }
        
        if gameMode == GameMode.Timed {
            initTimerBar()
            timerBar?.start()
        } else if gameMode == GameMode.Endless {
            initHealthBar()
        }
        ///////
        
        resetCircleColors()
        stats_starttime = NSDate()
        startPowerupTimer()
        isGameOver = false
    }
    
    private func resetCircleColors() {
        availableColors.removeAll()
        for circle in circles {
            circle.resetColor()
            availableColors.append(circle.nodeColor)
        }
        
        nextBall?.removeFromParent()
        addBall()
    }
    
    private func initTimerBar() {
        var barHeight = size.height / 48
        timerBar = TimerBar(size: CGSize(width: size.width, height: barHeight), color: ThemeHandler.Instance.getCurrentColors().BarColor, max: timedTime)
        timerBar.position = CGPoint(x: -size.width / 2, y: (size.height / 2) - (barHeight / 2))
        timerBar.delegate = self
        rootNode.addChild(timerBar)
    }
    
    private func initHealthBar() {
        var barHeight = size.height / 48
        healthBar = HealthBar(size: CGSize(width: size.width, height: barHeight), color: ThemeHandler.Instance.getCurrentColors().BarColor, max: endlessHealth)
        healthBar.position = CGPoint(x: -size.width / 2, y: (size.height / 2) - (barHeight / 2))
        healthBar.delegate = self
        rootNode.addChild(healthBar)
    }
    
    // MARK: - TOUCH FUNCTIONS
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(rootNode)
            if (!btnStop.containsPoint(location)) && (shootArea.containsPoint(location)) {
                if !isGameOver && !isTimerBarExpired {
                    StatsHandler.updateFiredBallsBy(1)
                    shootBall()
                    addBall()
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(rootNode)
            if (btnStop.containsPoint(location)) {
                gameover()
            }
        }
    }
    
    // MARK: - GAME FUNCTIONS
    private func addBall() {
        nextBall = Ball(color: getRandomBallColor(), position: ballPosition, radius: ballRadius)
        rootNode.addChild(nextBall.fadeIn())
    }
    
    private func shootBall() {
        activeBalls.insert(nextBall, atIndex: 0)
        nextBall.shoot((circlePosition.y - ballPosition.y) * 2)
    }
    
    // MARK: - COLLISION DETECTION
    func didBeginContact(contact: SKPhysicsContact) {
        if isGameOver { return }
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch (contactMask) {
        case PhysicsCategory.ball.rawValue | PhysicsCategory.arc.rawValue:
            var ball : Ball
            var circle : Circle
            
            if contact.bodyA.categoryBitMask == PhysicsCategory.ball.rawValue {
                ball = contact.bodyA.node as! Ball
                circle = contact.bodyB.node?.parent as! Circle // parent because the arc's parent
            } else {
                ball = contact.bodyB.node as! Ball
                circle = contact.bodyA.node?.parent as! Circle // parent because the arc's parent
            }
            ballDidCollideWithCircle(ball, circle: circle)
            
            break
        case PhysicsCategory.border.rawValue | PhysicsCategory.ball.rawValue:
            var ball : Ball
            
            if contact.bodyA.categoryBitMask == PhysicsCategory.ball.rawValue {
                ball = contact.bodyA.node as! Ball
            } else{
                ball = contact.bodyB.node as! Ball
            }
            
            ballDidCollideWithBorder(ball)
            break
        case PhysicsCategory.powerup.rawValue | PhysicsCategory.ball.rawValue:
            var ball : Ball
            
            if contact.bodyA.categoryBitMask == PhysicsCategory.ball.rawValue {
                ball = contact.bodyA.node as! Ball
            } else{
                ball = contact.bodyB.node as! Ball
            }
            
            ballDidCollideWithPowerup(ball)
            break
        default:
            return
        }
    }
    
    private func ballDidCollideWithCircle(ball: Ball, circle: Circle) {
        activeBalls.removeLast()
        // set the physicscategory to none to prevent additional contacts
        ball.physicsBody!.categoryBitMask = PhysicsCategory.none.rawValue
        ball.removeFromParent()
        
        if (ball.nodeColor == circle.nodeColor) {
            StatsHandler.updateCorrectCollisionsBy(1)
            runSound()
            var points = circle.pointsPerHit * multiplicator * powerupMultiplicator
            score.increaseByWithColor(points, color: ball.nodeColor)
            
            if gameMode == GameMode.Timed {
                timerBar?.addTime(Double(circle.pointsPerHit))
            }
        } else {
            runVibration()
            if gameMode == GameMode.Timed {
                timerBar?.addTime(-Double(circle.pointsPerHit))
            } else if gameMode == GameMode.Endless {
                healthBar?.decrement()
            }
        }
    }
    
    private func ballDidCollideWithBorder(ball: Ball) {
        StatsHandler.updateNoCollisionsBy(1)
        activeBalls.removeLast()
        ball.removeFromParent()
    }
    
    private func ballDidCollideWithPowerup(ball: Ball) {
        StatsHandler.updateCollectedPowerupsBy(1)
        activeBalls.removeLast()
        ball.removeFromParent()
        handlePowerup()
    }
    
    // MARK: - GAMEOVER FUNCTIONS
    private func gameover() {
        isGameOver = true
        var endScore = score.getScore()
        
        var playedGames = StatsHandler.getPlayedGames()
        if (playedGames > 0 && playedGames % 6 == 0) {
            if (!PurchaseHandler.hasRemovedAds()) {
                AdTapsy.showInterstitial(sceneDelegate as! UIViewController)
            }
        }
        
        runVibration()
        
        nextBall?.removeFromParent()
        for ball in activeBalls {
            ball.removeFromParent()
        }
        
        timerBar?.stop()
        currentPowerup?.stop()
        stopPowerupTimer()
        
        var playedtime = Int(NSDate().timeIntervalSinceDate(stats_starttime))
        StatsHandler.updatePlayedTimeBy(playedtime)
        StatsHandler.updateTotalPointsBy(endScore)
        StatsHandler.updateLastscore(endScore, gameMode: gameMode)
        StatsHandler.updateHighscore(endScore, gameMode: gameMode)
        StatsHandler.incrementPlayedGames()
        
        sceneDelegate!.showGameoverScene(gameMode)
    }
    
    // MARK: - TIMERBAR DELEGATE    
    func timerBarZero() {
        gameover()
    }
    
    // MARK: - HEALTHBAR DELEGATE
    func healthBarZero() {
        gameover()
    }
    
    // MARK: - USER FEEDBACK FUNCTIONS
    private func runSound() {
        var state = SettingsHandler.getSoundSetting()
        if state {
            var sound = hitSounds[Int(arc4random_uniform(UInt32(hitSounds.count)))]
            runAction(sound)
        }
    }
    
    private func runVibration() {
        var state = SettingsHandler.getVibrationSetting()
        if state {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    // MARK: - HANDLING POWERUPS
    private func startPowerupTimer() {
        var interval = NSTimeInterval(arc4random_uniform(20) + 10)
        var wait = SKAction.waitForDuration(interval)
        var run = SKAction.runBlock({
            self.powerupTimerTick()
        })
        runAction(SKAction.repeatActionForever(SKAction.sequence([wait, run])), withKey: "powerupExpirationTimer")
    }
    
    private func stopPowerupTimer() {
        removeActionForKey("powerupExpirationTimer")
    }
    
    private func powerupTimerTick() {
        stopPowerupTimer()
        
        var type = randomPowerupType()
        currentPowerup = Powerup(radius: ballRadius * 2, type: type)
        currentPowerup.position = circlePosition
        currentPowerup.delegate = self
        rootNode.addChild(currentPowerup)
        currentPowerup.fadeIn()
    }
    
    private func handlePowerup() {
        var type = currentPowerup.powerupType!
        powerupDescription.text = type.description.uppercaseString
        
        switch type {
        case .None:
            break
        case .DoublePoints:
            powerupMultiplicator = 2
            currentPowerup.startWith(15)
            break
        case .TriplePoints:
            powerupMultiplicator = 3
            currentPowerup.startWith(15)
            break
        case .FullTime:
            timerBar?.start()
            powerupZero()
            break
        case .FullLifes:
            if (healthBar != nil && healthBar!.isFull()) {
                score.increaseByWithColor(10, color: ThemeHandler.Instance.getCurrentColors().PowerupColor)
            } else {
                healthBar?.reset()
            }
            powerupZero()
            break
        case .Unicolor:
            for circle in circles {
                circle.setColor(ThemeHandler.Instance.getCurrentColors().PowerupColor)
            }
            nextBall?.setColor(ThemeHandler.Instance.getCurrentColors().PowerupColor)
            availableColors.removeAll()
            availableColors.append(ThemeHandler.Instance.getCurrentColors().PowerupColor)
            currentPowerup.startWith(5)
            break
        case .ExtraPoints10:
            score.increaseByWithColor(10, color: ThemeHandler.Instance.getCurrentColors().PowerupColor)
            powerupZero()
            break
        case .ExtraPoints30:
            score.increaseByWithColor(30, color: ThemeHandler.Instance.getCurrentColors().PowerupColor)
            powerupZero()
            break
        case .ExtraPoints50:
            score.increaseByWithColor(50, color: ThemeHandler.Instance.getCurrentColors().PowerupColor)
            powerupZero()
            break
        default:
            break
        }
    }
    
    func powerupExpired() {
        currentPowerup.removeFromParent()
        currentPowerup.stop()
        currentPowerup = nil
        startPowerupTimer()
    }
    
    func powerupZero() {
        powerupMultiplicator = 1
        currentPowerup.stop()
        currentPowerup.fadeOut()
        
        resetCircleColors()
        
        currentPowerup = nil
        powerupDescription.text = ""
        
        startPowerupTimer()
    }
    
    
    func randomPowerupType() -> PowerupType {
        var powerups : [PowerupType : UInt32]!
        if gameMode == GameMode.Endless { powerups = PowerupsEndless }
        else if gameMode == GameMode.Timed { powerups = PowerupsTimed }
        else { return PowerupType.None }
        
        var maxOccurence : UInt32 = 0
        for occurence in powerups.values {
            maxOccurence = maxOccurence + occurence
        }
        
        var current : UInt32 = 1
        var result : UInt32 = arc4random_uniform(maxOccurence) + 1
        for (powerupType, occurence) in powerups {
            if result >= current && result < (current + occurence) {
                return powerupType
            }
            current = current + occurence
        }
        return PowerupType.None
    }
    
    // MARK: - HELPER FUNCTIONS
    private func getRandomBallColor() -> UIColor {
        var random = Int(arc4random_uniform(UInt32(availableColors.count)));
        var color = availableColors[random]
        return color
    }
    
    private func getRandomBoolean() -> Bool {
        var random = arc4random_uniform(9)
        return (random % 2) == 0
    }
    
    private func addCircle(color: UIColor, clockwise: Bool, points: Int) -> Circle {
        var radius : CGFloat!
        var thickness : CGFloat!
        
        if circles.count == 0 {
            radius = size.height / 16
            thickness = size.height / 32
        }
        else {
            var lastradius = circles.last!.radius
            var lastthickness = circles.last!.thickness
            
            radius = lastradius + lastthickness
            thickness = lastthickness
        }
        var c = Circle(position: circlePosition, radius: radius, thickness: thickness, clockwise: clockwise, pointsPerHit: points, color: color)
        circles.append(c)
        rootNode.addChild(c)
        return c
    }
}
