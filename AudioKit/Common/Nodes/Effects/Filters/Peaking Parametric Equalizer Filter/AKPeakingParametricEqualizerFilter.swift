//
//  AKPeakingParametricEqualizerFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// This is an implementation of Zoelzer's parametric equalizer filter.
///
/// - parameter input: Input node to process
/// - parameter centerFrequency: Center frequency.
/// - parameter gain: Amount at which the center frequency value shall be increased or decreased. A value of 1 is a flat response.
/// - parameter q: Q of the filter. sqrt(0.5) is no resonance.
///
public class AKPeakingParametricEqualizerFilter: AKNode, AKToggleable {

    // MARK: - Properties


    internal var internalAU: AKPeakingParametricEqualizerFilterAudioUnit?
    internal var token: AUParameterObserverToken?

    private var centerFrequencyParameter: AUParameter?
    private var gainParameter: AUParameter?
    private var qParameter: AUParameter?

    /// Center frequency.
    public var centerFrequency: Double = 1000 {
        willSet(newValue) {
            if centerFrequency != newValue {
                centerFrequencyParameter?.setValue(Float(newValue), originator: token!)
            }
        }
    }
    /// Amount at which the center frequency value shall be increased or decreased. A value of 1 is a flat response.
    public var gain: Double = 1.0 {
        willSet(newValue) {
            if gain != newValue {
                gainParameter?.setValue(Float(newValue), originator: token!)
            }
        }
    }
    /// Q of the filter. sqrt(0.5) is no resonance.
    public var q: Double = 0.707 {
        willSet(newValue) {
            if q != newValue {
                qParameter?.setValue(Float(newValue), originator: token!)
            }
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    public var isStarted: Bool {
        return internalAU!.isPlaying()
    }

    // MARK: - Initialization

    /// Initialize this equalizer node
    ///
    /// - parameter input: Input node to process
    /// - parameter centerFrequency: Center frequency.
    /// - parameter gain: Amount at which the center frequency value shall be increased or decreased. A value of 1 is a flat response.
    /// - parameter q: Q of the filter. sqrt(0.5) is no resonance.
    ///
    public init(
        _ input: AKNode,
        centerFrequency: Double = 1000,
        gain: Double = 1.0,
        q: Double = 0.707) {

        self.centerFrequency = centerFrequency
        self.gain = gain
        self.q = q

        var description = AudioComponentDescription()
        description.componentType         = kAudioUnitType_Effect
        description.componentSubType      = 0x70657130 /*'peq0'*/
        description.componentManufacturer = 0x41754b74 /*'AuKt'*/
        description.componentFlags        = 0
        description.componentFlagsMask    = 0

        AUAudioUnit.registerSubclass(
            AKPeakingParametricEqualizerFilterAudioUnit.self,
            asComponentDescription: description,
            name: "Local AKPeakingParametricEqualizerFilter",
            version: UInt32.max)

        super.init()
        AVAudioUnit.instantiateWithComponentDescription(description, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitEffect = avAudioUnit else { return }

            self.avAudioNode = avAudioUnitEffect
            self.internalAU = avAudioUnitEffect.AUAudioUnit as? AKPeakingParametricEqualizerFilterAudioUnit

            AKManager.sharedInstance.engine.attachNode(self.avAudioNode)
            input.addConnectionPoint(self)
        }

        guard let tree = internalAU?.parameterTree else { return }

        centerFrequencyParameter = tree.valueForKey("centerFrequency") as? AUParameter
        gainParameter            = tree.valueForKey("gain")            as? AUParameter
        qParameter               = tree.valueForKey("q")               as? AUParameter

        token = tree.tokenByAddingParameterObserver {
            address, value in

            dispatch_async(dispatch_get_main_queue()) {
                if address == self.centerFrequencyParameter!.address {
                    self.centerFrequency = Double(value)
                } else if address == self.gainParameter!.address {
                    self.gain = Double(value)
                } else if address == self.qParameter!.address {
                    self.q = Double(value)
                }
            }
        }
        centerFrequencyParameter?.setValue(Float(centerFrequency), originator: token!)
        gainParameter?.setValue(Float(gain), originator: token!)
        qParameter?.setValue(Float(q), originator: token!)
    }
    
    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    public func start() {
        self.internalAU!.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    public func stop() {
        self.internalAU!.stop()
    }
}
