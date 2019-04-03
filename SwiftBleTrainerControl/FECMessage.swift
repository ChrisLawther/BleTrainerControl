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
        return self.reduce(0) { $0 ^ $1 }
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

// Calibration status
enum CalibrationStatus: UInt8 {
    case notRequested, pending
}

// Calibration conditions
// swiftlint:disable identifier_name
enum CalibrationTemperatureCondition: UInt8 {
    case notApplicable,
         tooCold,
         ok,
         tooHot
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
    case outOfRange(ClosedRange<Float>, Float)
    case outOfIntegerRange(ClosedRange<Int>, Int)
}

extension FECError: LocalizedError {
    private var errorDescription: String {
        switch self {
        case .message(let msg):
            return msg
        case .outOfIntegerRange(let range, let value):
            return "Invalid value (\(value)) provided, must be \(range)"
        case .outOfRange(let range, let value):
            return "Invalid value (\(value)) provided, must be \(range)"
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
