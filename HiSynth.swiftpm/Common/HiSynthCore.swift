//
//  HiSynthCore.swift
//
//
//  Created by Bill Chen on 2023/4/3.
//
import AVFoundation
import Foundation
import AudioKit
import SoundpipeAudioKit
import Keyboard
import SporthAudioKit

enum HSWaveform {
    case sine
    case square
    case saw
    case triangle
    case pulse

    private func pulseWave(pulseSize: Float = 0.25) -> [Table.Element] {
        var table = [Table.Element](zeros: 4096)
        for i in 0..<4096 {
            table[i] = i < Int(4096.0 * (pulseSize)) ? Float(1): Float(-1)
        }
        return table
    }

    func getTable() -> Table {
        switch self {
        case .sine:
            return Table(.sine)
        case .square:
            return Table(.square)
        case .saw:
            return Table(.sawtooth)
        case .triangle:
            return Table(.triangle)
        case .pulse:
            return Table(pulseWave())
        }
    }

    func getSymbolImageName() -> String {
        let names: [HSWaveform: String] = [
            .sine: "wave-sine",
            .square: "wave-square",
            .saw: "wave-saw",
            .triangle: "wave-triangle",
            .pulse: "wave-pulse"
        ]
        return names[self]!
    }

    func getReadableName() -> String {
        let names: [HSWaveform: String] = [
            .sine: "Sine",
            .square: "Square",
            .saw: "Saw",
            .triangle: "Triangle",
            .pulse: "Pulse"
        ]
        return names[self]!
    }
}

class OscillatorControllerTest: ObservableObject {
    @Published var waveform = HSWaveform.sine
    @Published var level: Float = 0.5

    var mixer = Mixer()
    var oscMixer = Mixer()
    var oscPool: [DynamicOscillator] = []
    var envPool: [AmplitudeEnvelope] = []
    var lfos: [OperationEffect] = []
    var oscCount = 8

    /// MIDINotenumber -> oscNumber or nil for not playing. Used for voice allocation
    var allocated: [Int8: Int] = [:]

    /// MIDINoteNumber stack for tracking voice stealing
    var voices: [Int8] = []

    /// Track noteOff tasks controlling releaseing oscillators that can be cancelled.
    var noteTasks: [Int8: DispatchWorkItem] = [:]

    var oscillatorQueue = DispatchQueue(label: "io.billc.hisynth.oscillator", qos: .userInteractive)

    init(waveform: HSWaveform = HSWaveform.saw, level: Float = 0.8) {
        self.waveform = waveform
        self.level = level
        // Load oscillators
        for _ in 0..<oscCount {
            let osc = DynamicOscillator()
            osc.setWaveform(waveform.getTable())
            osc.amplitude = 0.0
            osc.start()
            let env = AmplitudeEnvelope(osc)
            env.attackDuration = 0.5
            env.releaseDuration = 0.5
            env.start()
            oscPool.append(osc)
            envPool.append(env)

            oscMixer.addInput(env)
        }
        // AM LFO
        let lfo = OperationEffect(oscMixer) { osc, parameters in
            parameters.forEach{ print($0.description) }
            let oscillator = Operation.sineWave(frequency: 3).scale(minimum: 0, maximum: 1)

            let amped = osc
            return amped.lowPassFilter(halfPowerPoint: oscillator * parameters[0])
        }
        lfo.start()
        lfos.append(lfo)

        lfo.parameter1 = 5000

        let reverbed = Reverb(lfo)
        mixer.addInput(reverbed)
    }

    func noteOn(_ pitch: Pitch) {
        // Cancel previous release task
        if let previousTask = noteTasks[pitch.midiNoteNumber] {
            previousTask.cancel()
        }

        // Find the first not playing osc for voice allocation
        let oscIndex = (0..<oscCount).first{ !Set(allocated.values).contains($0) }
        if let oscIndex = oscIndex {
            let osc = oscPool[oscIndex]
            osc.frequency = AUValue(pitch.midiNoteNumber).midiNoteToFrequency()
            envPool[oscIndex].openGate()
            osc.amplitude = level
            allocated[pitch.midiNoteNumber] = oscIndex
            voices.append(pitch.midiNoteNumber)
            // Start lfo for syncing if it is the first note of the gruop
            if voices.count == 1 {
                lfos[0].start()
            }
        } else {
            // No enough oscillators. Perform voice stealing
            let toStealNote = voices.first
            if let toStealNote = toStealNote {
                guard let toStealOscIndex = allocated[toStealNote] else {
                    print("Error: Voice stealing error, can not find the oscillator to stop. toStealNote: \(toStealNote).")
                    return
                }
                print("Info: Maximum polyphony reached. Stealing note \(toStealNote).")
                oscPool[toStealOscIndex].frequency = AUValue(pitch.midiNoteNumber).midiNoteToFrequency()
                allocated[toStealNote] = toStealOscIndex
                envPool[toStealOscIndex].openGate()
//                lfos[toStealOscIndex].start()
                voices.removeFirst()
                voices.append(pitch.midiNoteNumber)
            } else {
                print("Warning: no voices to steal.")
            }
        }
    }

    func noteOff(_ pitch: Pitch) {
        print(allocated)
        print(voices)
        let oscIndex = allocated[pitch.midiNoteNumber]
        if let oscIndex = oscIndex {
            //            oscPool[oscIndex].amplitude = 0.0
//            lfos[oscIndex].stop()
            envPool[oscIndex].closeGate()
            // Asynchrolly set allocated voice to nil after sustain finishes.
            let task = DispatchWorkItem {
                self.allocated[pitch.midiNoteNumber] = nil
            }
            oscillatorQueue.asyncAfter(deadline: .now() + Double(envPool[oscIndex].releaseDuration) + 0.1, execute: task)
            noteTasks[pitch.midiNoteNumber] = task
        } else {
            print("Warning: noteOff called on a note that is not playing.")
        }
        self.voices.removeAll { $0 == pitch.midiNoteNumber }
    }

}

class LFOController: ObservableObject {

}


class FilterController: ObservableObject {

}

class SFXController: ObservableObject {

}

class HiSynthCore: ObservableObject, HasAudioEngine {
    var engine = AudioEngine()
    var polyOscillators: [PolyOscillator]

    @Published var oscillatorController: OscillatorController
    @Published var envelopeController: EnvelopeController
    @Published var lfoController = LFOController()
    @Published var filterController = FilterController()
    @Published var sfxController = SFXController()

    init() {
        polyOscillators = [PolyOscillator(), PolyOscillator()]
        oscillatorController = OscillatorController(oscs: polyOscillators)
        envelopeController = EnvelopeController(oscs: polyOscillators)
        engine.output = envelopeController.outputNode
        do {
            try engine.start()
        } catch {
            print("Error: engine start failed.")
        }
    }
    func noteOn(pitch: Pitch, point: CGPoint) {
        print("Note on:", pitch.midiNoteNumber)
        oscillatorController.noteOn(pitch)
    }

    func noteOff(pitch: Pitch) {
        print("Pitch off:", pitch.midiNoteNumber)
        oscillatorController.noteOff(pitch)
    }
}