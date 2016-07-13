import SpriteKit
import XCPlayground


let sceneView = SKView(frame:CGRect(x: 0, y: 0, width: 850, height: 638))
let scene = SKScene(fileNamed: "GameScene")
scene!.scaleMode = .AspectFill
sceneView.presentScene(scene)
scene!.physicsWorld.gravity = CGVectorMake(0, -0.05)

XCPShowView("Balloons", view: sceneView)


//让大炮开火
let images = [
    "blue", "heart-blue", "star-blue",
    "green", "star-green", "heart-pink",
    "heart-red", "orange", "red",
    "star-gold", "star-pink", "star-red",
    "yellow"
]
let textures: [SKTexture] = images.map { SKTexture(imageNamed: "balloon-\($0)") }

var configureBalloonPhysics: ((balloon: SKSpriteNode) -> Void)?
func createRandomBalloon() -> SKSpriteNode {
    let choice = Int(arc4random_uniform(UInt32(textures.count)))
    let balloon = SKSpriteNode(texture: textures[choice])
    configureBalloonPhysics?(balloon: balloon)
    
    return balloon
}


let BalloonCategory: UInt32 = 1 << 1
configureBalloonPhysics = { balloon in
    balloon.physicsBody = SKPhysicsBody(texture: balloon.texture!, size: balloon.size)
    balloon.physicsBody!.linearDamping = 0.5
    balloon.physicsBody!.mass = 0.1
    balloon.physicsBody!.categoryBitMask = BalloonCategory
    balloon.physicsBody!.contactTestBitMask = BalloonCategory
}

let displayBalloon: (SKSpriteNode, SKNode) -> Void = { balloon, cannon in
    balloon.position = cannon.childNodeWithName("mouth")!.convertPoint(CGPointZero, toNode: scene!)
    scene!.addChild(balloon)
}

let fireBalloon: (SKSpriteNode, SKNode) -> Void = { balloon, cannon in
    let impulseMagnitude: CGFloat = 70.0
    
    let xComponent = cos(cannon.zRotation) * impulseMagnitude
    let yComponent = sin(cannon.zRotation) * impulseMagnitude
    let impulseVector = CGVector(dx: xComponent, dy: yComponent)
    
    balloon.physicsBody!.applyImpulse(impulseVector)
}

func fireCannon(cannon: SKNode) {
    let balloon = createRandomBalloon()
    
    displayBalloon(balloon, cannon)
    fireBalloon(balloon, cannon)
}

let leftBalloonCannon = scene!.childNodeWithName("//left_cannon")
let rightBalloonCannon = scene!.childNodeWithName("//right_cannon")

let wait = SKAction.waitForDuration(1.0, withRange: 0.05)
let pause = SKAction.waitForDuration(0.55, withRange: 0.05)

let left = SKAction.runBlock { fireCannon(leftBalloonCannon!) }
let right = SKAction.runBlock { fireCannon(rightBalloonCannon!) }

let leftFire = SKAction.sequence([wait, left, pause, left, pause, left, wait])
let rightFire = SKAction.sequence([pause, right, pause, right, pause, right, wait])

leftBalloonCannon!.runAction(SKAction.repeatActionForever(leftFire))
rightBalloonCannon!.runAction(SKAction.repeatActionForever(rightFire))


//撞击效果
let balloonPop = (1...4).map {
    SKTexture(imageNamed: "explode_0\($0)")
}

let removeBalloonAction: SKAction = SKAction.sequence([
    SKAction.animateWithTextures(balloonPop, timePerFrame: 1 / 30.0),
    SKAction.removeFromParent()
    ])

let GroundCategory: UInt32 = 1 << 2
let ground = scene!.childNodeWithName("//ground")
ground!.physicsBody!.categoryBitMask = GroundCategory

class PhysicsContactDelegate: NSObject, SKPhysicsContactDelegate {
    func didBeginContact(contact: SKPhysicsContact) {
        let categoryA = contact.bodyA.categoryBitMask
        let categoryB = contact.bodyB.categoryBitMask
        
        if (categoryA & BalloonCategory != 0) && (categoryB & BalloonCategory != 0) {
            contact.bodyA.node!.runAction(removeBalloonAction)
        }
    }
}

let contactDelegate = PhysicsContactDelegate()
scene!.physicsWorld.contactDelegate = contactDelegate

