//
//  FECResponse.swift
//  BleTrainerControl
//
//  Created by Chris on 02/04/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import Foundation

enum FECResponse: Equatable {
    case calibrationResponse(temp: UInt8, zeroOffset: UInt16?, spindownResp: UInt16?)
    case calibrationProgress(temp: UInt8, zeroOffsetStatus: CalibrationStatus, spindownStatus: CalibrationStatus,
        speedCondition: CalibrationSpeedCondition, tempCondition: CalibrationTemperatureCondition, targetSpeed: UInt16,
        targetSpindown: UInt16)
    case generalFEData(capabilities: FECapabilities, type: EquipmentType, elapsed: UInt8, distance: UInt8,
        heartrate: UInt8, speed: Float)
    case generalSettings(cycleLength: UInt8, inclinePercentage: Float, resistanceLevel: UInt8)
    case trainerSpecific(updates: UInt8, cadence: UInt8, accumulatedPower: UInt16, instantaneousPower: UInt16)
    case basicResistance(resistance: Float)
    case targetPower(target: Float)
    case windResistance(coefficient: UInt8, windspeed: UInt8, factor: UInt8)
    case trackResistance(coefficient: Float, grade: Float)
    case feCapabilities(maxResistance: UInt16, capabilities: FECapabilities)
    case userConfiguration(userWeightKg: Float, bicycleWeightKg: Float, diameterOffset: UInt8,
        wheelDiameterM: Float, ratio: Float)
    case requestData
    case commandStatus(commandId: UInt8, sequence: UInt8, status: UInt8, data: UInt32)
    case manufacturersId(hardwareId: UInt8, manufacturer: UInt16, model: UInt16)
    case productInformation(majorVersion: UInt8, minorVersion: UInt8, serial: UInt32)

    case unknown

    // swiftlint:disable:next cyclomatic_complexity
    init?(from data: Data) {
        // Enough data?
        guard data.count > 4 else { return nil }

        // Valid packet?
        guard data.checksum == 0 else { return nil }

        let bytes = [UInt8](data)
        guard bytes[0] == 0xa4 else { return nil }

        let length = bytes[1]
        //        let msgId = bytes[2]
        //        let channel = bytes[3]

        let payload = [UInt8](data.suffix(from: 4))

        guard payload.count == length else { return nil }

        let page = payload[0]

        switch page {
        case 1: self = FECResponse.calibrationResponse(payload)
        case 2: self = FECResponse.calibrationProgress(payload)
        case 16: self = FECResponse.generalFEData(payload)
        case 17: self = FECResponse.generalSettings(payload)
        case 25: self = FECResponse.trainerSpecific(payload)
        case 48: self = FECResponse.basicResistance(payload)
        case 49: self = FECResponse.targetPower(payload)
        case 50: self = FECResponse.windResistance(payload)
        case 51: self = FECResponse.trackResistance(payload)
        case 54: self = FECResponse.feCapabilities(payload)
        case 55: self = FECResponse.userConfiguration(payload)
        case 70: self = .requestData
        case 71: self = FECResponse.commandStatus(payload)
        case 80: self = FECResponse.manufacturersId(payload)
        case 81: self = FECResponse.productInformation(payload)

        default:
            return nil
        }
    }

    // page 1
    private static func calibrationResponse(_ payload: [UInt8]) -> FECResponse {

        // swiftlint:disable:next nesting
        struct Features: OptionSet {
            let rawValue: UInt8

            static let spindown = Features(rawValue: 1 << 7)
            static let zeroOffset = Features(rawValue: 1 << 6)
        }

        let features = Features(rawValue: payload[1])
        let temp = payload[3]
        let zeroOffset: UInt16? = features.contains(.zeroOffset)
            ? UInt16(payload[4]) | (UInt16(payload[5]) << 8)
            : nil

        let spindown: UInt16? = features.contains(.spindown)
            ? UInt16(payload[6]) | (UInt16(payload[7]) << 8)
            : nil

        return .calibrationResponse(temp: temp, zeroOffset: zeroOffset, spindownResp: spindown)
    }

    // page 2
    private static func calibrationProgress(_ payload: [UInt8]) -> FECResponse {
        let status = payload[1]

        let zeroOffsetStatus = CalibrationStatus(rawValue: (status >> 7) & 0x1)!
        let spindownStatus   = CalibrationStatus(rawValue: (status >> 6) & 0x1)!

        let speedCondition = CalibrationSpeedCondition(rawValue: (payload[2] >> 6) & 0x3)!
        let tempCondition = CalibrationTemperatureCondition(rawValue: (payload[2] >> 4) & 0x3)!

        let temperature = payload[3]

        let targetSpeed = UInt16(payload[4]) | (UInt16(payload[5]) << 8)
        let targetSpindown = UInt16(payload[6]) | (UInt16(payload[7]) << 8)

        return .calibrationProgress(temp: temperature, zeroOffsetStatus: zeroOffsetStatus,
                                    spindownStatus: spindownStatus, speedCondition: speedCondition,
                                    tempCondition: tempCondition, targetSpeed: targetSpeed,
                                    targetSpindown: targetSpindown)
    }

    // page 16
    private static func generalFEData(_ payload: [UInt8]) -> FECResponse {
        let type = EquipmentType(rawValue: payload[1]) ?? .unknown
        let elapsed = payload[2]
        let distance = payload[3]
        let speed = Float(UInt16(payload[4]) | (UInt16(payload[5]) << 8)) * 3.6 / 1000
        let heartrate = payload[6]
        let capabilities = FECapabilities(rawValue: payload[7])

        return .generalFEData(capabilities: capabilities, type: type, elapsed: elapsed,
                              distance: distance, heartrate: heartrate, speed: speed)
    }

    // page 17
    private static func generalSettings(_ payload: [UInt8]) -> FECResponse {
        let cycleLength = payload[3]

        let incline = Float(UInt16(payload[4]) | (UInt16(payload[5]) << 8)) * 0.01
        let resistance = payload[6]

        return .generalSettings(cycleLength: cycleLength,
                                inclinePercentage: incline,
                                resistanceLevel: resistance / 2)
    }

    // page 25
    private static func trainerSpecific(_ payload: [UInt8]) -> FECResponse {
        let updates = payload[1]
        let cadence = payload[2]

        let accumulatedPower = UInt16(payload[3]) | (UInt16(payload[4]) << 8)
        let instantPower = UInt16(payload[5]) | (UInt16(payload[6]) << 8)

        return .trainerSpecific(updates: updates, cadence: cadence,
                                accumulatedPower: accumulatedPower,
                                instantaneousPower: instantPower)
    }

    // page 48
    private static func basicResistance(_ payload: [UInt8]) -> FECResponse {
        let resistance = Float(payload[7]) / 2

        return .basicResistance(resistance: resistance)
    }

    // page 49
    private static func targetPower(_ payload: [UInt8]) -> FECResponse {
        let target = Float(UInt16(payload[6]) | (UInt16(payload[7]) << 8)) / 4

        return .targetPower(target: target)
    }

    // page 50
    private static func windResistance(_ payload: [UInt8]) -> FECResponse {
        let coefficient = payload[5]
        let windspeed = payload[6]
        let factor = payload[7]

        return .windResistance(coefficient: coefficient, windspeed: windspeed, factor: factor)
    }

    // page 51
    private static func trackResistance(_ payload: [UInt8]) -> FECResponse {
        let grade = Float(UInt16(payload[5]) | (UInt16(payload[6]) << 8)) * 0.01
        let coefficient = Float(payload[7]) * 5 * pow(10, -5)

        return .trackResistance(coefficient: coefficient, grade: grade)
    }

    // page 54
    private static func feCapabilities(_ payload: [UInt8]) -> FECResponse {
        let maxResistance = UInt16(payload[5]) | (UInt16(payload[6]) << 8)
        let capabilities = FECapabilities(rawValue: payload[7])

        return .feCapabilities(maxResistance: maxResistance, capabilities: capabilities)
    }

    // page 55
    private static func userConfiguration(_ payload: [UInt8]) -> FECResponse {
        let userWeight = Float(UInt16(payload[1]) | (UInt16(payload[2]) << 8)) / 100
        let wheelOffset = payload[4] & 0x0f
        let bicycleWeight = Float((UInt16(payload[4]) | (UInt16(payload[5]) << 8)) >> 4) / 20

        let wheelDiameter = Float(payload[6]) / 100
        let ratio = Float(payload[7]) * 0.03

        return .userConfiguration(userWeightKg: userWeight,
                                  bicycleWeightKg: bicycleWeight,
                                  diameterOffset: wheelOffset,
                                  wheelDiameterM: wheelDiameter,
                                  ratio: ratio)
    }

    // page 71
    private static func commandStatus(_ payload: [UInt8]) -> FECResponse {
        let commandId = payload[1]
        let sequence = payload[2]
        let status = payload[3]
        let data = (UInt32(payload[4]) << 24)
                 | (UInt32(payload[5]) << 16)
                 | (UInt32(payload[6]) <<  8)
                 | (UInt32(payload[7]) <<  0)

        return .commandStatus(commandId: commandId, sequence: sequence, status: status, data: data)
    }

    // page 80
    private static func manufacturersId(_ payload: [UInt8]) -> FECResponse {
        let hwId = payload[3]
        let manufacturer = UInt16(payload[4]) | (UInt16(payload[5]) << 8)
        let model = UInt16(payload[6]) | (UInt16(payload[7]) << 8)

        return .manufacturersId(hardwareId: hwId, manufacturer: manufacturer, model: model)
    }

    // page 81
    private static func productInformation(_ payload: [UInt8]) -> FECResponse {
        let minor = payload[2]
        let major = payload[3]
        let serial = (UInt32(payload[7]) << 24)
                   | (UInt32(payload[6]) << 16)
                   | (UInt32(payload[5]) <<  8)
                   | (UInt32(payload[4]) <<  0)

        return .productInformation(majorVersion: major, minorVersion: minor, serial: serial)
    }
}
