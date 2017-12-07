//
//  ViewController.swift
//  test
//
//  Created by Dustin Doan on 11/29/17.
//  Copyright © 2017 Dustin Doan. All rights reserved.
//

import UIKit
import AVFoundation
import GDPerformanceView_Swift
import AudioKit
import FTIndicator
import SnapKit

class ViewController: UIViewController {
    
    
    @IBOutlet var lbNode:UILabel!
    @IBOutlet var lbScore:UILabel!
    @IBOutlet var btPlay:UIButton!
    
    var midiView:MidiView?
    
    @IBOutlet private var frequencyLabel: UILabel!
    @IBOutlet private var amplitudeLabel: UILabel!
    @IBOutlet private var noteNameWithSharpsLabel: UILabel!
    @IBOutlet private var noteNameWithFlatsLabel: UILabel!

    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    
    var player:AVAudioPlayer! = nil
    
    
    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    
    func addMonitor(){
        
        GDPerformanceMonitor.sharedInstance.startMonitoring()
        let performanceView = GDPerformanceMonitor.init()
        performanceView.startMonitoring()
        
        performanceView.configure(configuration: { (textLabel) in
            textLabel?.backgroundColor = .black
            textLabel?.textColor = .yellow
        })
        performanceView.appVersionHidden = true
        performanceView.deviceVersionHidden = true
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //fps
        addMonitor()
        
        midiView = MidiView.creatView()
        midiView?.delegate = self
        
        view.addSubview(midiView!)
        midiView!.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(150)
            make.height.equalTo(150)
        }
        
        midiView?.parseFile()
        
        AKSettings.audioInputEnabled = true
        AKSettings.bufferLength = .medium
        mic = AKMicrophone()
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)
        
        addPlayer()
        
        let scrollTimer = Timer(timeInterval: 0.1, repeats: true) { [unowned self] (time) in

            self.midiView?.schedulerUpdate(currentTime: self.player.currentTime)
            self.updateUI()
            
        }
        
        scrollTimer.fire()
        RunLoop.main.add(scrollTimer, forMode: .commonModes)
        
    }
    
    func addPlayer(){
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch  {
            print("error:", error.localizedDescription)
        }
        
        
        let fileUrl  = Bundle.main.url(forResource: "emgaimua", withExtension: "mp3")
        
        do {
            player = try AVAudioPlayer(contentsOf: fileUrl!)
            player.currentTime = 25
            player.prepareToPlay()
            player.play()
        } catch  {
            print("error:", error.localizedDescription)
        }
        
    }
    
    @IBAction func playOrPause(){
        
        if player.isPlaying{
            
            btPlay.isSelected = false
            player.pause()
            
        } else{
            
            btPlay.isSelected = true
            player.play()
            
        }
        
    }
   
    
    override func viewDidAppear(_ animated: Bool) {
        
        AudioKit.output = silence
        AudioKit.start()
        
    }
    
    
    @objc func updateUI() {
        
        
        if tracker.amplitude > 0.1 {
            
            frequencyLabel.text = String(format: "%0.1f", tracker.frequency)
            
            var frequency = Float(tracker.frequency)
            while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
                frequency /= 2.0
            }
            while frequency < Float(noteFrequencies[0]) {
                frequency *= 2.0
            }
            
            var minDistance: Float = 10_000.0
            var index = 0
            
            for i in 0..<noteFrequencies.count {
                let distance = fabsf(Float(noteFrequencies[i]) - frequency)
                if distance < minDistance {
                    index = i
                    minDistance = distance
                }
            }
            let octave = Int(log2f(Float(tracker.frequency) / frequency))
            
            noteNameWithSharpsLabel.text = "\(noteNamesWithSharps[index])\(octave)"
            noteNameWithFlatsLabel.text = "\(noteNamesWithFlats[index])\(octave)"
            
            midiView?.updateIndicator(frequency: Double(tracker.frequency))
            
        }
        
        amplitudeLabel.text = String(format: "%0.2f", tracker.amplitude)
    }
    

}

extension ViewController: MidiViewDelegate{
    
    func updateScore(score: Int) {
        self.lbScore.text = "Score: \(score)"
    }
    
    func updateNote(node: String) {
        self.lbNode.text = node
    }
    
}

