//
//  AKCostelloReverb.swift
//  AudioKit
//
//  Autogenerated by scripts by Aurelius Prochazka. Do not edit directly.
//  Copyright (c) 2015 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/** 8 delay line stereo FDN reverb, with feedback matrix based upon physical
 modeling scattering junction of 8 lossless waveguides of equal characteristic
 impedance. */
public struct AKCostelloReverb: AKNode {

    // MARK: - Properties
    public var avAudioNode: AVAudioNode
    private var internalAU: AKCostelloReverbAudioUnit?
    private var token: AUParameterObserverToken?

    private var feedbackParameter: AUParameter?
    private var cutoffFrequencyParameter: AUParameter?

    /** Feedback level in the range 0 to 1. 0.6 gives a good small 'live' room sound,
     0.8 a small hall, and 0.9 a large hall. A setting of exactly 1 means infinite
     length, while higher values will make the opcode unstable. */
    public var feedback: Double = 0.6 {
        didSet {
            feedbackParameter?.setValue(Float(feedback), originator: token!)
        }
    }
    /** Low-pass cutoff frequency. */
    public var cutoffFrequency: Double = 4000 {
        didSet {
            cutoffFrequencyParameter?.setValue(Float(cutoffFrequency), originator: token!)
        }
    }

    // MARK: - Initializers

    /** Initialize this reverb node */
    public init(
        _ input: AKNode,
        feedback: Double = 0.6,
        cutoffFrequency: Double = 4000) {

        self.feedback = feedback
        self.cutoffFrequency = cutoffFrequency

        var description = AudioComponentDescription()
        description.componentType         = kAudioUnitType_Effect
        description.componentSubType      = 0x72767363 /*'rvsc'*/
        description.componentManufacturer = 0x41754b74 /*'AuKt'*/
        description.componentFlags        = 0
        description.componentFlagsMask    = 0

        AUAudioUnit.registerSubclass(
            AKCostelloReverbAudioUnit.self,
            asComponentDescription: description,
            name: "Local AKCostelloReverb",
            version: UInt32.max)

        self.avAudioNode = AVAudioNode()
        AVAudioUnit.instantiateWithComponentDescription(description, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitEffect = avAudioUnit else { return }

            self.avAudioNode = avAudioUnitEffect
            self.internalAU = avAudioUnitEffect.AUAudioUnit as? AKCostelloReverbAudioUnit

            AKManager.sharedInstance.engine.attachNode(self.avAudioNode)
            AKManager.sharedInstance.engine.connect(input.avAudioNode, to: self.avAudioNode, format: AKManager.format)
        }

        guard let tree = internalAU?.parameterTree else { return }

        feedbackParameter        = tree.valueForKey("feedback")        as? AUParameter
        cutoffFrequencyParameter = tree.valueForKey("cutoffFrequency") as? AUParameter

        token = tree.tokenByAddingParameterObserver {
            address, value in

            dispatch_async(dispatch_get_main_queue()) {
                if address == self.feedbackParameter!.address {
                    self.feedback = Double(value)
                } else if address == self.cutoffFrequencyParameter!.address {
                    self.cutoffFrequency = Double(value)
                }
            }
        }
        feedbackParameter?.setValue(Float(feedback), originator: token!)
        cutoffFrequencyParameter?.setValue(Float(cutoffFrequency), originator: token!)
    }
}