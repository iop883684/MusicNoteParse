//
//  MidiView.swift
//  test
//
//  Created by Dustin Doan on 12/1/17.
//  Copyright © 2017 Dustin Doan. All rights reserved.
//

import UIKit
import FTIndicator

protocol MidiViewDelegate:NSObjectProtocol {
    func updateNote(node:String)
    func updateScore(score:Int)
}

class MidiView: UIView {
    
    @IBOutlet var scrollView:UIScrollView!
    @IBOutlet var indicator:UIView!
    @IBOutlet var topIndicatorConstraint:NSLayoutConstraint!
    
    weak var delegate:MidiViewDelegate?
    let parser = NodeParse()
    
    var score = 0
    var scoreIncrease = 0
    var currentMidi = 0
    var currentRow = -1
    
    var emitterLayer:CAEmitterLayer = CAEmitterLayer()
    let emitterCell = CAEmitterCell()
    
    class func creatView()->MidiView{
        
        let views = Bundle.main.loadNibNamed("MidiView", owner: self, options: nil)
        let view = views?.first as! MidiView
        return view
        
    }
    
    func parseFile(){
        
        let file = Bundle.main.url(forResource: "emgai", withExtension: "lrc")
        
        parser.parse(fromFile: file!.path)
        print("low \(parser.lowestNode) - hight \(parser.highestNode)")
        
        genLayout(lines: parser.lines)
        
    }
    
    func genLayout(lines:[Nodes]){
        
        let scale:CGFloat = 60.0
        
        let lastLine = lines.last!
        let width = CGFloat(lastLine.endTime)*scale
        scrollView.contentSize = CGSize(width: width + 100,
                                        height: scrollView.frame.height)
        
        for line in lines{
//            print(line)
            let frameLength = CGFloat(line.endTime - line.starTime)*scale
            let x = CGFloat(line.starTime)*scale + 100
            
            let y = getYposition(value: line.midi)
            
            let frame = CGRect(x: x, y: y, width: frameLength, height: 10)
//            print(frame, "\n")
            
            let stepView = UIView(frame:frame)
            stepView.backgroundColor = randomColor()
            scrollView.addSubview(stepView)
            
        }
        
        startEffect()
        
    }
    
    func randomColor()->UIColor{
        
        let random = CGFloat(arc4random()%150 + 55)
        
        let color = UIColor(red: 1,
                            green: random/255.0,
                            blue: random/255.0, alpha: 1)
        
        return color
    }
    
    
    func getYposition(value:Int)->CGFloat{
        
        let height = CGFloat(parser.highestNode - parser.lowestNode)
        let currentNode = CGFloat(value - parser.lowestNode)
        
        // chuyen sang he quy chieu moi
        let posY = (self.frame.height-20) - currentNode/height * (self.frame.height-20)
        
        return CGFloat(posY + 5) // value 5 -> 145
    }
    
    func schedulerUpdate(currentTime:Double){
        
        let position = (currentTime + 0.4) * 60
        //            let point = CGPoint(x: position, y: 0)
        //            self.scrollView.setContentOffset(point, animated: true)
        UIView.animate(withDuration: 0.1, delay: 0,
                       options: UIViewAnimationOptions.curveLinear, animations: {
                        self.scrollView.contentOffset.x = CGFloat(position)
        }, completion: nil)
        
        let row = parser.getCurrentRow(forTime: currentTime + 0.4)
        
        if self.currentRow != row{
            
            self.currentRow = row
            if self.scoreIncrease > 0{
                FTIndicator.showToastMessage("+\(self.scoreIncrease)")
                self.score += self.scoreIncrease
                self.scoreIncrease = 0
                
                delegate?.updateScore(score: score)
            }
            
            if row >= 0{
                delegate?.updateNote(node: parser.lines[row].node)
                self.currentMidi = self.parser.lines[row].midi
            } else{
                delegate?.updateNote(node: "")
                self.currentMidi = 0
            }
            
        }
        
    }
    
    func updateIndicator(frequency:Double){
        
        var note =  frequency.frequencyToMIDINote()
        print("node: ",note)

        //check score
        let compare = note - Double(currentMidi)
        if compare > -2 && compare < 2{
            scoreIncrease += 2
            emitterLayer.birthRate = 2
            
        } else if compare > -5 && compare < 5 {
            scoreIncrease += 1
            emitterLayer.birthRate = 1
        } else{
            emitterLayer.birthRate = 0
        }
        
        let heightest = Double(parser.highestNode)
        let lowest = Double(parser.lowestNode)
        if note > heightest {
            note = heightest
        }
        
        if note < lowest{
            note = lowest
        }
        let y = getYposition(value: Int(note))
        topIndicatorConstraint.constant = y
        emitterLayer.emitterPosition = CGPoint(x:100, y:y)
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }
    
    func startEffect(){

        emitterLayer.emitterPosition = CGPoint(x:100, y: self.frame.height - 10)
        emitterLayer.renderMode = kCAEmitterLayerAdditive
        
        emitterCell.emissionLongitude = CGFloat(Double.pi)
        emitterCell.contents = UIImage(named: "Triangle")?.cgImage
        emitterCell.scale = 0.4;
        emitterCell.emissionLatitude = 0
        emitterCell.lifetime = 1
        emitterCell.birthRate = 10
        emitterCell.velocity = 100
        emitterCell.velocityRange = 50
        emitterCell.xAcceleration = -150
        emitterCell.emissionRange = CGFloat(Double.pi / 2)
        emitterCell.color = UIColor.orange.cgColor;
        
        emitterCell.alphaSpeed = -0.7;
        emitterCell.scaleSpeed = -0.1;
        emitterCell.scaleRange = 0.1;
        emitterCell.beginTime = 0.01;
        
        emitterCell.redRange = 0.9;
        emitterCell.greenRange = 0.9;
        emitterCell.blueRange = 0.9;
        emitterCell.name = "base"
        

        self.emitterLayer.emitterCells = [emitterCell]
        self.layer.addSublayer(emitterLayer)

        
    }

}
