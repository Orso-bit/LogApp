//
//  MotionManager.swift
//  Log
//
//  Created by Giovanni Jr Di Fenza on 21/05/25.
//

import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 0.05
    private let filterFactor: Double = 0.2
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    private var filteredPitch: Double = 0.0
    private var filteredRoll: Double = 0.0
    
    init() {
        motionManager.deviceMotionUpdateInterval = updateInterval
    }
    
    func startUpdating() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion, error == nil else { return }
                
                // Convert radians to degrees
                let currentPitch = motion.attitude.pitch * 180 / .pi
                let currentRoll = motion.attitude.roll * 180 / .pi
                
                // Apply smoothing filter
                self.filteredPitch = self.applyLowPassFilter(input: currentPitch, filtered: self.filteredPitch)
                self.filteredRoll = self.applyLowPassFilter(input: currentRoll, filtered: self.filteredRoll)
                
                // Update published variables
                self.pitch = self.filteredPitch
                self.roll = self.filteredRoll
            }
        }
    }
    
    private func applyLowPassFilter(input: Double, filtered: Double) -> Double {
        return filtered * (1.0 - filterFactor) + input * filterFactor
    }
    
    func stopUpdating() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    deinit {
        stopUpdating()
    }
}
