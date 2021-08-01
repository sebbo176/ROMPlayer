//
//  Fatten.swift
//  ROM Player
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2016 AudioKit. All rights reserved.
//

import AudioKit
import AudioToolbox
import SoundpipeAudioKit
import AVFoundation

class Fatten: Node {

    var connections: [Node] = []
    var avAudioNode: AVAudioNode

    var dryWetMix: DryWetMixer
    var delay: Delay
    var pannedDelay: Panner
    var pannedSource: Panner
    var wet: Mixer
    var inputMixer = Mixer()

    var inputNode: AVAudioNode {
        return inputMixer.avAudioNode
    }
    
    init(_ input: Node) {
        self.connections.append(inputMixer)
//        input.connect(to: inputMixer)
        delay = Delay(inputMixer, time: 0.04, dryWetMix: 1)
        pannedDelay = Panner(delay, pan: 1)
        pannedSource = Panner(inputMixer, pan: -1)
        wet = Mixer(pannedDelay, pannedSource)
        dryWetMix = DryWetMixer(inputMixer, wet, balance: 0)
//        super.init()
        self.avAudioNode = dryWetMix.avAudioNode
    }

}
