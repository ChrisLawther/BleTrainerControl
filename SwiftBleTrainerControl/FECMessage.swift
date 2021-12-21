//
//  FECMessage.swift
//  BleTrainerControl
//
//  Created by Chris on 02/04/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import Foundation

extension Data {
    // Simple checksum for FE-C - just an XOR'ing of all the bytes
    func checksummed() -> Data {
        return self + [self.checksum]
    }

    var checksum: UInt8 {
        return self.reduce(0, ^)
    }
}

extension UInt16 {
    func bytes() -> (msb: UInt8, lsb: UInt8) {
        return (
            msb: UInt8(self >> 8),
            lsb: UInt8(self & 0xff)
        )
    }
}

struct CalibrationRequest: OptionSet {
    let rawValue: UInt8

    static let zeroOffsetCalibration = CalibrationRequest(rawValue: 1 << 6)
    static let spindownCalibration = CalibrationRequest(rawValue: 1 << 7)
}

// Calibration status
enum CalibrationStatus: UInt8 {
    case notRequested, pending
}

// Calibration conditions
// swiftlint:disable identifier_name
enum CalibrationTemperatureCondition: UInt8 {
    case notApplicable,
         tooLow,
         ok,
         tooHigh
}

enum CalibrationSpeedCondition: UInt8 {
    case notApplicable,
         tooSlow,
         ok,
         reserved
}
// swiftlint:enable identifier_name

////Calibration response
//#define CALIBRATION_RESPONSE_FAILURE_NOT_ATTEMPTED 0
//#define CALIBRATION_RESPONSE_SUCCESS 1
enum CalibrationResponse {
    case notAttempted,
         success
}

enum FECError: Error {
    case message(String)
    case outOfRange(String, ClosedRange<Double>, Double)
    case outOfIntegerRange(String, ClosedRange<Int>, Int)
}

extension FECError: LocalizedError {
    private var errorDescription: String {
        switch self {
        case .message(let msg):
            return msg
        case .outOfIntegerRange(let variable, let range, let value):
            return "Invalid '\(variable)' value (\(value)) provided, must be \(range)"
        case .outOfRange(let variable, let range, let value):
            return "Invalid '\(variable)' value (\(value)) provided, must be \(range)"
        }
    }
}

enum EquipmentType: UInt8 {
    case general = 16
    case treadmill = 19
    case elliptical = 20
    case stationaryBike = 21
    case rower = 22
    case climber = 23
    case nordicSkier = 24
    case trainer = 25
    case unknown = 255
}

// Page 16 capabilities
struct GeneralFECapabilities: OptionSet {
    let rawValue: UInt8

    // NOTE: Due to the way these values "overlap" in their bit-usage, they should
    //       be checked in descending order (in other words .handContactHrm (valid)
    //       has the same value as .antPlusHrm + .emHrm (invalid))
    static let antPlusHrm = GeneralFECapabilities(rawValue: 1)
    static let emHrm = GeneralFECapabilities(rawValue: 2)
    static let handContactHrm = GeneralFECapabilities(rawValue: 3)

    static let distanceTravelled = GeneralFECapabilities(rawValue: 1 << 2)
    static let virtualSpeed = GeneralFECapabilities(rawValue: 1 << 3)
}

struct FECapabilities: OptionSet {
    let rawValue: UInt8

    // Q. Are these one structure, or two? They don't appear together, but
    //    they also don't overlap in their bit usage?
    // "Section 1"
    static let basicResistanceMode = FECapabilities(rawValue: 1 << 0)
    static let targetPowerMode = FECapabilities(rawValue: 1 << 1)
    static let simulationMode = FECapabilities(rawValue: 1 << 2)
    // "Section 2"
    static let virtualSpeed = FECapabilities(rawValue: 1 << 4)
    static let distanceTravelled = FECapabilities(rawValue: 1 << 5)
    static let hrDataSource = FECapabilities(rawValue: 3 << 6)
}

enum FEState: UInt8 {
    case reserved
    case asleep
    case ready
    case inUse
    case finished
}

struct MetabolicCapabilities: OptionSet {
    let rawValue: UInt8

    static let accumulatedCalories = MetabolicCapabilities(rawValue: 1)
}

struct TrainerStatus: OptionSet {
    let rawValue: UInt8

    static let powerCalibrationRequired = TrainerStatus(rawValue: 1 << 0)
    static let resistanceCalibrationRequired = TrainerStatus(rawValue: 1 << 1)
    static let userConfigurationRequired = TrainerStatus(rawValue: 1 << 2)
}

/// Used by a smart trainer to report whether it is able to hit the demanded
/// target power
///
/// - achievingPower: the trainer is operating at the target power, or no target power set.
/// - speedTooLow: User’s cycling speed is too low to achieve target power (they should probably change to a higher gear)
/// - speedTooHigh: User’s cycling speed is too high to achieve target power (to maintain current cadence, they should change to a lower gear)
/// - undetermined: Undetermined (maximum or minimum) target power limit reached
enum TrainerFlags: UInt8 {

    case achievingPower
    case speedTooLow
    case speedTooHigh
    case undetermined
}

/// Windspeed is stored/transmitted as a UInt8, but corresponds to a
/// km/h value in the range -127..127. This performs that conversion.
///
/// - Parameter value: the UInt8 value
/// - Returns: signed value, in km/h
func windSpeed(from value: UInt8) -> Int8 {
    return Int8(bitPattern: value &- 127)
}


/// Windspeed (km/h) is in the range -127..127, but stored/transmitted
/// as a UInt8. This performs that conversion.
///
/// - Parameter windSpeed: the windspeed, in km/h (-127...127)
/// - Returns: unsigned representation for transmission
func unsignedSpeedValue(from windSpeed: Int8) -> UInt8 {
    return UInt8(bitPattern: windSpeed &+ 127)
}
