//
//  GameScene.swift
//  Rock Box
//
//  Created by Leonardo Geus on 11/06/15.
//  Copyright (c) 2015 Leonardo Geus. All rights reserved.
////

import SpriteKit
import AVFoundation


struct BitMasks {
    static let planeta:UInt32 = 0x1 << 0
    static let personagem:UInt32 = 0x1 << 1
    static let letra:UInt32 = 0x1 << 2
    static let regiao:UInt32 = 0x1 << 3
    static let estrela:UInt32 = 0x1 << 4
    static let particulas:UInt32 = 0x1 << 5
    static let campo:UInt32 = 0x06
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var jsonResult:NSDictionary!
    
    var planetaIndex = 0
    
    var labelAngulo:SKLabelNode!
    var planeta1:SKSpriteNode!
    var planeta2 = SKSpriteNode()
    var planeta3 = SKSpriteNode()
    var planetaTeste = SKSpriteNode()
    var cameraNode = SKSpriteNode()
    var gameNode = SKSpriteNode()
    var contador:Float = 0
    var jogador = SKSpriteNode(imageNamed: "Personagem_voando_1.png")
    var planetaUser = ""
    var arrayPlanetas = Array<SKSpriteNode>()
    var arrayLetras = Array<SKSpriteNode>()
    var arrayEstrelas = Array<SKSpriteNode>()
    var pausar = false
    
    var palavraDaFaseArray:Array<Character>!
    
    var numeroDaLetraAtual = 0
    var numeroDeEstrelasAtual = 0
    
    var planetaAtual = SKSpriteNode()
    var anguloAtual = CGFloat(M_PI_2)
    
    var swipePoints = (initial:CGPoint(), final:CGPoint(), actual:CGPoint())
    
    var isTouched = false
    var longPressMinInterval = 0.5
    var lastUntouchedTime = CFTimeInterval()
    var lastMovedTouchTime = CFTimeInterval()
    
    var lastUpdateTime = CFTimeInterval()
    
    var moveDelay = 0.1
    var lastMoveTime = CFTimeInterval()
    
    var personagemVoando = [SKTexture]()
    var audioPlayer = AVAudioPlayer()
    
    var jumpTestDelay = 1.0
    var lastJumpTime = CFTimeInterval()
    var isJumping = false
    
    var isChangingPlanet = false
    var numeroEstrelasJson = 0
    
    var alfaSpeaking = false
    
    enum moveDirection{
        case left
        case right
        case planet
    }
    
    override func didMoveToView(view: SKView) {
        
        print(DataManager.instance.faseEscolhida)
        
        numeroDaLetraAtual = 0
        numeroDeEstrelasAtual = 0
        
        
        // Configuracoes do mundo e a camera
        
        
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self
        self.addChild(gameNode)
        gameNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/4)
        gameNode.size = self.size
        gameNode.xScale = 1.5
        gameNode.yScale = 1.5
        gameNode.addChild(cameraNode)

        let backgroundNode = SKSpriteNode(imageNamed: "background.jpg")
        backgroundNode.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        backgroundNode.size = CGSize(width: self.size.width*5.5, height: self.size.height*5.5)
        backgroundNode.zPosition = -10
        gameNode.addChild(backgroundNode)
        
        
        //CRIAR PLANETAS
        let fase = DataManager.instance.arrayDaFase(DataManager.instance.faseEscolhida)
        for planetas in fase {
            var planetasDic = planetas as! Dictionary<String,AnyObject>
            let stringImagem =  planetasDic["imagem"] as! String
            let planetasSprite:SKSpriteNode = criarPlanetasComPosicao(CGPoint(x: CGFloat(planetasDic["coordenadaX"] as! CGFloat), y: CGFloat(planetasDic["coordenadaY"] as! CGFloat)), raio: CGFloat(planetasDic["raioPlaneta"] as! CGFloat), habilitarRegiao: true, raioAtmosfera: Float(planetasDic["raioAtmosfera"] as! Float), falloff: 0.5, strenght: 0.5, imagem: "\(stringImagem)", nome: "Planeta \(arrayPlanetas.count)")
            arrayPlanetas.append(planetasSprite)
        }
        planetaAtual = arrayPlanetas[1]
        
        
        
        
        //CRIAR PERSONAGEM
        
        
        
        jogador.size = CGSize(width: 274/5, height: 471/5)
        
        let origem = planetaAtual.position
        let raio  = planetaAtual.frame.size.height/2 + jogador.size.height/2

        
        let posX = cameraNode.position.x + origem.x + raio * cos(anguloAtual)
        let posY = cameraNode.position.y + origem.y + raio * sin(anguloAtual)
        
        jogador.zRotation = anguloAtual - CGFloat(M_PI_2)
        
        jogador.position = CGPoint(x: posX, y: posY)

        jogador.name = "jogador"
        jogador.physicsBody = SKPhysicsBody(rectangleOfSize: jogador.size)
        jogador.physicsBody?.dynamic = true
        jogador.physicsBody?.mass = 1000
        jogador.physicsBody?.categoryBitMask = BitMasks.personagem
        jogador.physicsBody?.collisionBitMask = BitMasks.planeta
        jogador.physicsBody?.contactTestBitMask = BitMasks.letra | BitMasks.regiao
        jogador.physicsBody?.allowsRotation = false
        jogador.physicsBody?.affectedByGravity = true
        jogador.zPosition = 100
        var animFrames = [SKTexture]()
        for index in 1...4 {
            animFrames.append(SKTexture(imageNamed: String(format:"Personagem_voando_%d.png", index)))
            print(String(format:"Personagem_voando_%2d.png", index), terminator: "")}
        let fps = 8.0
        let anim = SKAction.customActionWithDuration(1.0, actionBlock: { node, time in
            let index = Int((fps * Double(time))) % animFrames.count
            (node as! SKSpriteNode).texture = animFrames[index]})
        jogador.runAction(SKAction.repeatActionForever(anim))
        gameNode.addChild(jogador)
        
        
        
        
        //CRIAR LETRAS
        
        let letras = DataManager.instance.arrayDasLetras(DataManager.instance.faseEscolhida)
        
        for letra in letras {
            var letrasDic = letra as! Dictionary<String,AnyObject>
            
            if letrasDic["planeta"] as! String == "planeta1" {
                
                let letraSprite:SKSpriteNode =  criarLetras(arrayPlanetas[0], angulo: letrasDic["angulo"] as! CGFloat, imagem: letrasDic["imagem"] as! String, nome: letrasDic["nome"] as! String)
                arrayPlanetas.append(letraSprite)
            }
            else  if letrasDic["planeta"] as! String == "planeta2" {
                
                let letraSprite:SKSpriteNode =  criarLetras(arrayPlanetas[1], angulo: letrasDic["angulo"] as! CGFloat, imagem: letrasDic["imagem"] as! String, nome: letrasDic["nome"] as! String)
                arrayPlanetas.append(letraSprite)
            }
            else  if letrasDic["planeta"] as! String == "planeta3" {
                
                let letraSprite:SKSpriteNode =  criarLetras(arrayPlanetas[2], angulo: letrasDic["angulo"] as! CGFloat, imagem: letrasDic["imagem"] as! String, nome: letrasDic["nome"] as! String)
                arrayPlanetas.append(letraSprite)
            }
            else  if letrasDic["planeta"] as! String == "planeta4" {
                
                let letraSprite:SKSpriteNode =  criarLetras(arrayPlanetas[3], angulo: letrasDic["angulo"] as! CGFloat, imagem: letrasDic["imagem"] as! String, nome: letrasDic["nome"] as! String)
                arrayPlanetas.append(letraSprite)
            }
            
        }
        
        
        
        
        
        //CRIAR ESTRELAS
        
        let estrelas = DataManager.instance.arrayDasEstrelas(DataManager.instance.faseEscolhida)
        
        for estrela  in estrelas {
            var estrelasDic = estrela as! Dictionary<String,AnyObject>
            
            if estrelasDic["planeta"] as! String == "planeta1" {
                
                let estrelaSprite:SKSpriteNode =  criarEstrelas(arrayPlanetas[0], angulo: estrelasDic["angulo"] as! CGFloat)
                arrayPlanetas.append(estrelaSprite)
            }
            else  if estrelasDic["planeta"] as! String == "planeta2" {
                
                let estrelaSprite:SKSpriteNode =  criarEstrelas(arrayPlanetas[1], angulo: estrelasDic["angulo"] as! CGFloat)
                arrayPlanetas.append(estrelaSprite)
            }
            else  if estrelasDic["planeta"] as! String == "planeta3" {
                
                let estrelaSprite:SKSpriteNode =  criarEstrelas(arrayPlanetas[2], angulo: estrelasDic["angulo"] as! CGFloat)
                arrayPlanetas.append(estrelaSprite)
            }
            else  if estrelasDic["planeta"] as! String == "planeta4" {
                
                let estrelaSprite:SKSpriteNode =  criarEstrelas(arrayPlanetas[3], angulo: estrelasDic["angulo"] as! CGFloat)
                arrayPlanetas.append(estrelaSprite)
            }
            
        }
        
        let arquivo = (((DataManager.instance.lerArquivoJson())[DataManager.instance.faseEscolhida - 1] as! Dictionary<String,AnyObject>)["palavra"] as! String)
        
        
        
        
        palavraDaFaseArray = Array(arquivo.characters)
        
        
        
        //OUTROS
        
        
        //        let pular = UISwipeGestureRecognizer(target: self, action: Selector("swipeUp:"))
        //        pular.direction = .Up
        //        view.addGestureRecognizer(pular)
        //
        
        
        
        //ESTRELAS PARTÍCULAS
        
        let particulasEstrelas = SKEmitterNode(fileNamed: "stars.sks")
        

        particulasEstrelas!.position = CGPoint(x: -400, y: self.frame.height / 2)
        particulasEstrelas!.zPosition = -1
        particulasEstrelas!.alpha = 0.7
        gameNode.addChild(particulasEstrelas!)
        self.paused = true
     
        //initSprite()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            
            let location = touch.locationInNode(self)
            
            swipePoints.initial = location
            
            swipePoints.actual = swipePoints.initial
            
            isTouched = true
            let positionInScene = touch.locationInNode(self)
            let touchedNode = self.nodeAtPoint(positionInScene)
            
            if let name = touchedNode.name
            {
                if name == "jogador" && !(DataManager.instance.pausar)
                {
                    
                    
                    let random = arc4random_uniform(4)
                    var sound = SKAction()
                    switch random {
                    case 0:
                        sound = SKAction.playSoundFileNamed("vamos_la.wav", waitForCompletion: true)
                    case 1:
                        sound = SKAction.playSoundFileNamed("eu_sou_o_alfa.wav", waitForCompletion: true)
                    case 2:
                        sound = SKAction.playSoundFileNamed("eu_sou_o_alfa2.wav", waitForCompletion: true)
                    case 3:
                        sound = SKAction.playSoundFileNamed("vamos_amiguinhos.wav", waitForCompletion: true)
                    default:
                        sound = SKAction.playSoundFileNamed("vamos_la.wav", waitForCompletion: true)
                    }
                   
                    if (!alfaSpeaking) {
                        alfaSpeaking = true
                        cameraNode.runAction(sound, completion: { () -> Void in
                            self.alfaSpeaking = false
                        })
                    }
                    personagemFelizAnimacao()
                    
                    
                }
            }
        
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            
            let location = touch.locationInNode(self)
            
            lastMovedTouchTime = lastUpdateTime
            
            swipePoints.actual = location
            
        }
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch: AnyObject in touches {
            
            let location = touch.locationInNode(self)
            
            swipePoints.final = location
            
            isTouched = false
            
            if lastUpdateTime - lastMovedTouchTime < 0.2 && !self.paused {
            
                let dx = fabs(swipePoints.final.x - swipePoints.initial.x)
                let dy = fabs(swipePoints.final.y - swipePoints.initial.y)
            
                if (dx > 20 || dy > 20) && !isJumping {
                    let jumpVectorSize = CGFloat(120000)
                    let jumpVector = CGVector(dx: jumpVectorSize * cos(anguloAtual), dy: jumpVectorSize * sin(anguloAtual))
                
                    isJumping = true
                    lastJumpTime = lastUpdateTime
                
                    personagemPulando()

                
                    jogador.physicsBody?.applyImpulse(jumpVector)
                    
//                    let jumpAction = SKAction.moveBy(jumpVector, duration: 0.5)
//                    
//                    jogador.runAction(jumpAction)
                    
                    
                
                }
            }
        }
    }
    
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == BitMasks.personagem && contact.bodyB.categoryBitMask == BitMasks.letra {
            //var bodyA = contact.bodyA
            let bodyB = contact.bodyB
            
            if  (numeroDaLetraAtual < palavraDaFaseArray.count) && String(palavraDaFaseArray[numeroDaLetraAtual]) == bodyB.node!.name
            {
                bodyB.node?.removeFromParent()
                numeroDaLetraAtual++
                updateTheHud()
                self.runAction(SKAction.playSoundFileNamed("letra.wav", waitForCompletion: true))
                personagemFelizAnimacao()
                if numeroDaLetraAtual == palavraDaFaseArray.count
                {
                    audioPlayer2.stop()
                    self.runAction(SKAction.playSoundFileNamed("vitoria.mp3.mp3", waitForCompletion: true))
                    
                    self.paused = true
                    
    
                    numeroEstrelasJson = (DataManager.instance.lerArquivoJson()[DataManager.instance.faseEscolhida - 1] as! Dictionary<String,AnyObject>)["quantasEstrelasPegou"] as! Int
                    if numeroDeEstrelasAtual > numeroEstrelasJson{
                        DataManager.instance.escreverArquivoJson(DataManager.instance.faseEscolhida, quantasEstrelasPegou: numeroDeEstrelasAtual)
                    }
                    
                }
            
            } else
            {
                bodyB.collisionBitMask = 0
            }

            
        }
        
        if contact.bodyA.categoryBitMask == BitMasks.letra && contact.bodyB.categoryBitMask == BitMasks.personagem {
            let bodyA = contact.bodyA
            //var bodyB = contact.bodyB
            
            if (numeroDaLetraAtual < palavraDaFaseArray.count) && String(palavraDaFaseArray[numeroDaLetraAtual]) == bodyA.node!.name
            {
                bodyA.node?.removeFromParent()
                numeroDaLetraAtual++
                self.runAction(SKAction.playSoundFileNamed("letra.wav", waitForCompletion: true))
                personagemFelizAnimacao()
            }
            
        }
        
        
        if contact.bodyA.categoryBitMask == BitMasks.estrela && contact.bodyB.categoryBitMask == BitMasks.personagem {
            let bodyA = contact.bodyA
            //var bodyB = contact.bodyB
            
            bodyA.node?.removeFromParent()
            DataManager.instance.numeroEstrelas++
            numeroDeEstrelasAtual++
            updateTheHud()
            self.runAction(SKAction.playSoundFileNamed("estrela.wav", waitForCompletion: true))
            personagemFelizAnimacao()
            
            
        }
        
        if contact.bodyA.categoryBitMask == BitMasks.personagem && contact.bodyB.categoryBitMask == BitMasks.estrela {
            //var bodyA = contact.bodyA
            let bodyB = contact.bodyB
            bodyB.node?.removeFromParent()
            DataManager.instance.numeroEstrelas++
            numeroDeEstrelasAtual++
            updateTheHud()
            self.runAction(SKAction.playSoundFileNamed("estrela.wav", waitForCompletion: true))
            personagemFelizAnimacao()
            
            
        }
        
        if contact.bodyA.categoryBitMask == BitMasks.personagem && contact.bodyB.categoryBitMask == BitMasks.regiao {
            var personagem = SKSpriteNode()
            var regiao = SKSpriteNode()
            
            if contact.bodyA.categoryBitMask == BitMasks.personagem {
                personagem = contact.bodyA.node as! SKSpriteNode
                regiao = contact.bodyB.node as! SKSpriteNode
            }
            else {
                personagem = contact.bodyB.node as! SKSpriteNode
                regiao = contact.bodyA.node as! SKSpriteNode
            }
            
            if planetaAtual.name != regiao.name {
                for planeta in arrayPlanetas {
                    if planeta.name == regiao.name {
                        planetaAtual = planeta
                        print("trocou para \(planeta.name)")
                        movePlayerWithDirection(.planet)
                    }
                }
                
            }
            
            print(regiao.name)
            
        }
        
        if contact.bodyA.categoryBitMask == BitMasks.personagem || contact.bodyB.categoryBitMask == BitMasks.personagem
            && contact.bodyA.categoryBitMask == BitMasks.planeta || contact.bodyB.categoryBitMask == BitMasks.planeta {
                isChangingPlanet = false
                
                if(lastUpdateTime - lastJumpTime > jumpTestDelay) {
                    isJumping = false
                }
        }
    }
    
    
    func didEndContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == BitMasks.personagem && contact.bodyB.categoryBitMask == BitMasks.letra {
            //var bodyA = contact.bodyA
            let bodyB = contact.bodyB
            
            if !((numeroDaLetraAtual < palavraDaFaseArray.count) && String(palavraDaFaseArray[numeroDaLetraAtual]) == bodyB.node!.name)
            {
                bodyB.collisionBitMask = BitMasks.estrela | BitMasks.personagem
                
            }
            
            
        }
        
        if contact.bodyA.categoryBitMask == BitMasks.letra && contact.bodyB.categoryBitMask == BitMasks.personagem {
            let bodyA = contact.bodyA
            //var bodyB = contact.bodyB
            
            if !(String(palavraDaFaseArray[0]) == bodyA.node!.name && (numeroDaLetraAtual < palavraDaFaseArray.count))
            {
                bodyA.collisionBitMask = BitMasks.estrela | BitMasks.personagem
               
            }
            
        }

    }
    

    
    override func update(currentTime: CFTimeInterval) {
        
        lastUpdateTime = currentTime
        
        handleLongPressWithUpdate(currentTime)
        
//        if DataManager.instance.pausar {
//            self.paused = true
//            
//        }
//        else {
//            self.paused = false
//        }
        
        
        
    }
    
    ///FUNCAO DE CRIAR OS NODES - PLANETAS,ESTRELAS E LETRAS
    
    func criarPlanetasComPosicao(posicao: CGPoint, raio:CGFloat, habilitarRegiao:Bool, raioAtmosfera:Float, falloff:Float, strenght:Float, imagem: String, nome: String) -> SKSpriteNode {
        if #available(iOS 8.0, *) {
            let fieldNode = SKFieldNode.radialGravityField()
            fieldNode.falloff = falloff
            fieldNode.strength = strenght;
            fieldNode.animationSpeed = 0.5
            fieldNode.name = "fieldNode"
            if (habilitarRegiao){fieldNode.region = SKRegion(radius: Float(raio) + raioAtmosfera)}
            fieldNode.position = posicao
            fieldNode.enabled = true
            fieldNode.physicsBody = SKPhysicsBody(circleOfRadius: raio)
            fieldNode.physicsBody?.dynamic = false
            //let fieldCategory: UInt32 = 0x1 << 1
            fieldNode.categoryBitMask = BitMasks.campo
            fieldNode.physicsBody?.allowsRotation = false
            fieldNode.physicsBody?.applyAngularImpulse(100)
            let imageFieldNode = SKSpriteNode(imageNamed: imagem)
            imageFieldNode.name = nome
            imageFieldNode.size = CGSizeMake(raio*2, raio*2)
            imageFieldNode.physicsBody = SKPhysicsBody(circleOfRadius: raio)
            imageFieldNode.physicsBody?.dynamic = false
            imageFieldNode.position = CGPoint(x: 0, y: 0)
            imageFieldNode.physicsBody?.collisionBitMask = BitMasks.planeta
            imageFieldNode.physicsBody?.contactTestBitMask = BitMasks.planeta
            imageFieldNode.physicsBody?.fieldBitMask = BitMasks.planeta
            imageFieldNode.physicsBody?.categoryBitMask = BitMasks.planeta
            imageFieldNode.physicsBody?.affectedByGravity = false
            imageFieldNode.physicsBody?.applyAngularImpulse(100)
            fieldNode.addChild(imageFieldNode)
            fieldNode.zPosition = 10.0
            cameraNode.addChild(fieldNode)
            
            
            let regiaoPlaneta = SKSpriteNode()
            regiaoPlaneta.position = CGPoint(x: 0, y: 0)
            regiaoPlaneta.physicsBody = SKPhysicsBody(circleOfRadius: raio + CGFloat(raioAtmosfera))
            regiaoPlaneta.color = UIColor.redColor()
            regiaoPlaneta.physicsBody?.dynamic = false
            regiaoPlaneta.physicsBody?.affectedByGravity = false
                regiaoPlaneta.physicsBody?.fieldBitMask = 0x0
            regiaoPlaneta.physicsBody?.categoryBitMask = BitMasks.regiao
            regiaoPlaneta.physicsBody?.contactTestBitMask = BitMasks.regiao | BitMasks.personagem | BitMasks.particulas
            regiaoPlaneta.physicsBody?.collisionBitMask = BitMasks.regiao
            regiaoPlaneta.name = nome
            fieldNode.addChild(regiaoPlaneta)
            var particulas = SKEmitterNode()
            switch imagem {
            case "planetaverde.png":
                particulas = SKEmitterNode(fileNamed: "verde.sks")!
            case "planetavermelho.png":
                particulas = SKEmitterNode(fileNamed: "vermelho.sks")!
            case "planetaazul.png":
                particulas = SKEmitterNode(fileNamed: "azul.sks")!
            default:
                particulas = SKEmitterNode(fileNamed: "azul.sks")!
                
            }
            
            if raio < 80 { //condicoes de planeta mt pequeno
                particulas.particleLifetime = 5
                particulas.particleBirthRate = 30
                particulas.speed = 3
                particulas.particleColor = UIColor.redColor()
                particulas.particlePositionRange = CGVector(dx: 1.7*(raio + CGFloat(raioAtmosfera)), dy: 1.7*(raio + CGFloat(raioAtmosfera)))}
            particulas.position = CGPoint(x: 0, y: 0)
            particulas.zPosition = -1
            if raio >= 80 {
                particulas.particlePositionRange = CGVector(dx: 1.7*(raio + CGFloat(raioAtmosfera)), dy: 1.7*(raio + CGFloat(raioAtmosfera)))
            }
            particulas.alpha = 0.7
            particulas.fieldBitMask = BitMasks.particulas | BitMasks.regiao
            
            regiaoPlaneta.addChild(particulas)
            return imageFieldNode


        } else {
            return SKSpriteNode()
        }
      }
    
    func criarLetras(node:SKSpriteNode, angulo:CGFloat, imagem:String, nome:String) -> SKSpriteNode {
        let letra = SKSpriteNode(imageNamed: imagem)
        let raio = node.size.height / 2
        letra.size = CGSize (width: 299/6, height: 299/6)
        letra.position = CGPoint(x: (raio*sin(angulo))+letra.size.height*sin(angulo)/2, y: (raio*cos(angulo)+letra.size.height*cos(angulo)/2))
        letra.physicsBody = SKPhysicsBody(rectangleOfSize: letra.size)
        letra.physicsBody?.affectedByGravity = false
        letra.physicsBody?.dynamic = false
        letra.physicsBody?.mass = 1
        let anguloF = (3.1415 - angulo) + CGFloat(M_PI)
        letra.zRotation = CGFloat(anguloF)
        letra.physicsBody?.collisionBitMask = 0
        letra.physicsBody?.contactTestBitMask = BitMasks.personagem
        letra.physicsBody?.categoryBitMask = BitMasks.letra
        if #available(iOS 8.0, *) {
            letra.physicsBody?.fieldBitMask = BitMasks.letra
        } else {
            // Fallback on earlier versions
        }
        letra.name = nome
        node.addChild(letra)
        
        return letra
        
    }
    
    func criarEstrelas(node:SKSpriteNode, angulo:CGFloat) -> SKSpriteNode{
        let estrela = SKSpriteNode(imageNamed: "estrela.png")
        let raio = node.size.height / 2
        estrela.size = CGSize (width: 299/10, height: 299/10)
        estrela.position = CGPoint(x: (raio*sin(angulo))+estrela.size.height*sin(angulo)/2, y: (raio*cos(angulo)+estrela.size.height*cos(angulo)/2))
        estrela.physicsBody = SKPhysicsBody(rectangleOfSize: estrela.size)
        estrela.physicsBody?.affectedByGravity = false
        estrela.physicsBody?.dynamic = false
         let anguloF = (3.1415 - angulo) + CGFloat(M_PI)
        estrela.zRotation = CGFloat(anguloF)
        estrela.physicsBody?.collisionBitMask = BitMasks.estrela | BitMasks.personagem
        estrela.physicsBody?.contactTestBitMask = BitMasks.estrela | BitMasks.personagem
        estrela.physicsBody?.categoryBitMask = BitMasks.estrela
        if #available(iOS 8.0, *) {
            estrela.physicsBody?.fieldBitMask = BitMasks.estrela
        } else {
            // Fallback on earlier versions
        }
        node.addChild(estrela)
        
        return estrela
    }
    

    
    func movePlayerWithDirection (direction : moveDirection) {
        
        var moveDuration = moveDelay * Double(planetaAtual.frame.size.height/200)
        
        switch (direction) {
        case .left:
            anguloAtual+=0.10
            jogador.xScale = -1.0
            self.runAction(SKAction.playSoundFileNamed("steps.wav", waitForCompletion: true))
        case .right:
            anguloAtual-=0.10
            jogador.xScale = 1.0
            self.runAction(SKAction.playSoundFileNamed("steps.wav", waitForCompletion: true))
        case .planet:
            anguloAtual -= CGFloat(M_PI)
            moveDuration = 10 * moveDelay
            personagemPulando()

        }
        
        if !isChangingPlanet {
            let origem = planetaAtual.parent!.position
            let raio  = planetaAtual.frame.size.height/2 + jogador.size.height/2
            let posX = origem.x + raio * cos(anguloAtual)
            let posY = origem.y + raio * sin(anguloAtual)
        
//            let posX2 = cameraNode.position.x + origem.x + raio * cos(anguloAtual)
//            let posY2 = cameraNode.position.y + origem.y + raio * sin(anguloAtual)
        
        
            let translacao = SKAction.moveTo(CGPoint(x: posX, y: posY), duration: moveDuration)
        
            let rotacao = SKAction.rotateToAngle(anguloAtual - CGFloat(M_PI_2), duration: moveDuration, shortestUnitArc: true)
    
            jogador.runAction(SKAction.group([translacao,rotacao]))
            
            if direction == .planet {
                isChangingPlanet = true
            }
        }
    }
    
    func personagemFelizAnimacao () {
        var animFrames = [SKTexture]()
        for index in 1...2 {
            animFrames.append(SKTexture(imageNamed: String(format:"Personagem_feliz_%d.png", index)))}
        let fps = 8.0
        let anim = SKAction.customActionWithDuration(1.0, actionBlock: { node, time in
            let index = Int((fps * Double(time))) % animFrames.count
            (node as! SKSpriteNode).texture = animFrames[index]})
        jogador.runAction(SKAction.repeatAction(anim, count: 2))
    
    }
    
    func personagemPulando() {
        var animFrames = [SKTexture]()
        for index in 1...7 {
            animFrames.append(SKTexture(imageNamed: String(format:"Personagem_pulando_%d.png", index)))}
        let fps = 8.0
        let anim = SKAction.customActionWithDuration(1.0, actionBlock: { node, time in
            let index = Int((fps * Double(time))) % animFrames.count
            (node as! SKSpriteNode).texture = animFrames[index]})
        
        let random = arc4random_uniform(5)
        var sound = SKAction()
        switch random {
        case 0:
            sound = SKAction.playSoundFileNamed("jump1.wav", waitForCompletion: true)
        case 1:
            sound = SKAction.playSoundFileNamed("jump2.wav", waitForCompletion: true)
        case 2:
            sound = SKAction.playSoundFileNamed("jump1.wav", waitForCompletion: true)
        case 3:
            sound = SKAction.playSoundFileNamed("jump4.wav", waitForCompletion: true)
        case 4:
            sound = SKAction.playSoundFileNamed("jump5.wav", waitForCompletion: true)
        default:
            sound = SKAction.playSoundFileNamed("jump6.wav", waitForCompletion: true)
        }
        self.runAction(sound)
        
        jogador.runAction(SKAction.repeatAction(anim, count: 1))
        
    }
    
    func handleLongPressWithUpdate(currentTime: CFTimeInterval) {
        if(!isTouched || self.paused) {
            lastUntouchedTime = currentTime
            return
        }
        else {
            if (currentTime - lastUntouchedTime > longPressMinInterval) {
                print("longPress!!!")
            
                if (currentTime - lastMoveTime > moveDelay) {
                    print(swipePoints.initial.x)
                    print((jogador.position.x * gameNode.xScale))
                    if swipePoints.actual.x > self.size.height/2 {
                        movePlayerWithDirection(moveDirection.right)
                    }
                    else if swipePoints.actual.x < self.size.height/2 {
                        movePlayerWithDirection(moveDirection.left)
                    }
                    lastMoveTime = currentTime
                }
            }
        }
    }
    
    func centerOnNode(node:SKNode){
        
        let cameraPositionInScene:CGPoint = self.convertPoint(node.position, fromNode: gameNode)
        
        gameNode.position = CGPoint(x:gameNode.position.x + self.frame.width / 2 - cameraPositionInScene.x, y: gameNode.position.y - cameraPositionInScene.y + self.frame.height / 2)
    }
    
    
    override func didSimulatePhysics() {
        self.centerOnNode(jogador)
    }
    
    func updateTheHud () {
        NSNotificationCenter.defaultCenter().postNotificationName("UpdateHud", object: nil)
        
    }
    
    func resetVars () {
        planetaIndex = 0
        contador = 0
        planetaUser = ""
        arrayPlanetas = Array<SKSpriteNode>()
        arrayLetras = Array<SKSpriteNode>()
        arrayEstrelas = Array<SKSpriteNode>()
        pausar = false
        
        
        numeroDaLetraAtual = 0
        numeroDeEstrelasAtual = 0
        
        planetaAtual = SKSpriteNode()
        anguloAtual = CGFloat(M_PI_2)
        
        swipePoints = (initial:CGPoint(), final:CGPoint(), actual:CGPoint())
        
        isTouched = false
        longPressMinInterval = 0.5
        lastUntouchedTime = CFTimeInterval()
        lastMovedTouchTime = CFTimeInterval()
        
        lastUpdateTime = CFTimeInterval()
        
        lastMoveTime = CFTimeInterval()
        
        isJumping = false
        isChangingPlanet = false
        numeroEstrelasJson = 0
    }
    
    
}