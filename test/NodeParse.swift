//
//  LyricParse.swift
//  LiveLabel
//
//  Created by Degree on 10/4/17.
//  Copyright © 2017 HeheData. All rights reserved.
//

import UIKit

struct Nodes {
    var starTime:Float = 0
    var endTime:Float = 0
    var node = String()
    var midi = 0
}

class NodeParse: NSObject {

    var lines = [Nodes]()
    var highestNode = 0
    var lowestNode = 150
    
   func parse(fromFile path: String)  {

        do {
            let raw = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            let rawLines = raw.components(separatedBy: "\n")
           self.parseRawLRC(rawLines)
            
        } catch  {
            print("Error", error.localizedDescription)
        }
        
    }
    
    func parse(fromString raw: String){
        
        let rawLines = raw.components(separatedBy: "\n")
        self.parseRawLRC(rawLines)
        
    }
    
    func getCurrentRow(forTime currentTime: Double) -> Int {
        
        var currentRow: Int = 0
        
        for currentLine in lines {

            if currentTime > Double(currentLine.starTime ){
                if currentTime < Double(currentLine.endTime ){
                    return currentRow
                }
            }
            
            currentRow += 1
            
        }
        return -1
    }

     func parseRawLRC(_ rawLines: [String]){

        lines = [Nodes]()
        
        for rawLine: String in rawLines {
            //[00:31.216-00:31.621]D6 74
            
            if (rawLine != "" && rawLine.count > 2) {
                
                if let node = parserOneLine(rawLine: rawLine) {
                    lines.append(node)
                }
                
            }

        }
 
    }
    
    func parserOneLine(rawLine:String)->Nodes?{
        
        var node = Nodes()
        
        let timestampedWords = rawLine.components(separatedBy: "]")
//        print("word", timestampedWords)
        
        guard timestampedWords.count > 1 else{
            return nil
        }
    
        //time process //[00:31.216-00:31.621
        var timeStr = timestampedWords[0]
        timeStr = timeStr.replacingOccurrences(of: "[", with: "") //remove [
        let timeArrStr = timeStr.components(separatedBy: "-")
        
        node.starTime = stringToTime(inputStr: timeArrStr[0])
        node.endTime = stringToTime(inputStr: timeArrStr[1])
        
        //word process //D6 74
        var textStr = timestampedWords[1]
        textStr = textStr.replacingOccurrences(of: "\r", with: "")
        let textArr = textStr.components(separatedBy: " ")
        
        node.node = textArr[0]
        if let value = Int(textArr[1]) {
            node.midi = value
            updateHightAndLowestNode(value: value)
        }
 
        return node
        
    }
    
    func updateHightAndLowestNode(value:Int){
        
        if value > highestNode{
            highestNode = value
        }
        
        if value < lowestNode{
            lowestNode = value
        }
        
    }

    func stringToTime(inputStr:String)->Float{
        //00:31.216
        
        var time: Float = 0.0
        var timeComponents = inputStr.components(separatedBy: ":")
        if timeComponents.count == 2 {
            let minutes = Int(timeComponents[0]) ?? 0
            let seconds = Float(timeComponents[1]) ?? 0.0
            time = Float(minutes * 60) + seconds
//            print("minutes:", minutes)
//            print("second:", seconds)
//            print("time:", time)
        }
        
        return time
        
    }

}
