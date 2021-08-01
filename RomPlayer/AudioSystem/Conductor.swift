//
//  Conductor
//  ROM Player
//
//  Created by Matthew Fecher on 7/20/17.
//  Copyright © 2017 AudioKit Pro. All rights reserved.

import AudioKit
import AudioToolbox
import SoundpipeAudioKit
import AVFoundation
import DunneAudioKit

class Conductor {
    
    // Globally accessible
    static let sharedInstance = Conductor()

    var sequencer: AppleSequencer!
    var sampler1 = Sampler()
    var decimator: Decimator
    var tremolo: Tremolo
    var fatten: Fatten
    var filterSection: FilterSection

    var autoPanMixer: DryWetMixer
    var autopan: Node

    var multiDelay: PingPongDelay
    var masterVolume = Mixer()
    var reverb: CostelloReverb
    var reverbMixer: DryWetMixer
    let midi = MIDI()

    init() {
        
        // MIDI Configure
        midi.createVirtualPorts()
        midi.openInput(name: "Session 1")
        midi.openOutput()
    
        // Session settings
//        AudioFile.cleanTempDirectory()
        Settings.bufferLength = .medium
        Settings.enableLogging = false
        
        // Allow audio to play while the iOS device is muted.
//        Settings.playbackWhileMuted = true
     
        do {
            try Settings.setSession(category: .playAndRecord, with: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
        } catch {
            Log("Could not set session category.")
        }
 
        // Signal Chain
        tremolo = Tremolo(sampler1, waveform: Table(.sine))
        decimator = Decimator(tremolo)
        filterSection = FilterSection(decimator)
        filterSection.output.stop()

        autopan = AutoPan(filterSection)
        autoPanMixer = DryWetMixer(filterSection, autopan)
        autoPanMixer.balance = 0 

        fatten = Fatten(autoPanMixer)
        
        multiDelay = PingPongDelay(fatten)
        
        masterVolume = Mixer(multiDelay)
     
        reverb = CostelloReverb(masterVolume)
        
        reverbMixer = DryWetMixer(masterVolume, reverb, balance: 0.3)
       
        // Set Output & Start AudioKit
//        AudioKit.output = reverbMixer
        let engine = AudioEngine()
        engine.output = reverbMixer
        do {
            try engine.start()
//            try AudioKit.start()
        } catch {
            print("AudioKit.start() failed")
        }
        
        // Set a few sampler parameters
        sampler1.releaseDuration = 0.5
  
        // Init sequencer
        midiLoad("rom_poly")
    }
    
    func addMidiListener(listener: MIDIListener) {
        midi.addListener(listener)
    }

    func playNote(note: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        sampler1.play(noteNumber: note, velocity: velocity)
    }

    func stopNote(note: MIDINoteNumber, channel: MIDIChannel) {
        sampler1.stop(noteNumber: note)
    }

    func useSound(_ sound: String) {
        let soundsFolder = Bundle.main.bundleURL.appendingPathComponent("Sounds/sfz").path.appending("\(sound).sfz")
        soundsFolder.
        sampler1.unloadAllSamples()
        let url = URL(string: soundsFolder)!
        sampler1.loadSFZ(url: url)
//        sampler1.loadSFZ(path: soundsFolder, fileName: sound + ".sfz")
    }
    
    func midiLoad(_ midiFile: String) {
        let path = "Sounds/midi/\(midiFile)"
        sequencer = AppleSequencer(filename: path)
        sequencer.enableLooping()
        sequencer.setGlobalMIDIOutput(midi.endpoints.first!.value) //TODO, fix better
        sequencer.setTempo(100)
    }
    
    func sequencerToggle(_ value: Double) {
        allNotesOff()
        
        if value == 1 {
            sequencer.play()
        } else {
            sequencer.stop()
        }
    }
    
    func allNotesOff() {
        for note in 0 ... 127 {
            sampler1.stop(noteNumber: MIDINoteNumber(note))
        }
    }
}
