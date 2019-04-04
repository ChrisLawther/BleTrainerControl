//
//  FECResponse.swift
//  BleTrainerControl
//
//  Created by Chris on 02/04/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import Foundation

enum FECResponse: Equatable {

    //
    case calibrationResponse(temp: Float, zeroOffset: UInt16?, spindownMs: UInt16?)

    //
    case calibrationProgress(temp: Float,
        zeroOffsetStatus: CalibrationStatus,
        spindownStatus: CalibrationStatus,
        speedCondition: CalibrationSpeedCondition,
        tempCondition: CalibrationTemperatureCondition,
        targetSpeedMs: Float,
        targetSpindownms: UInt16)

    //
    case generalFEData(capabilities: GeneralFECapabilities,
        type: EquipmentType,
        elapsed: Float,
        distanceM: UInt8,
        heartrate: UInt8,
        speedMs: Float,
        feState: FEState,
        lapToggle: UInt8
    )

    //
    case generalMetabolicData(mets: Float, burnRate: Float, calories: UInt8,
        capabilities: MetabolicCapabilities, state: FEState)

    //
    case generalSettings(cycleLength: UInt8, inclinePercentage: Float, resistanceLevel: UInt8)

    //
    case stationaryBikeSpecific(cadence: UInt8, power: UInt16, state: FEState)

    //
    case trainerSpecific(updates: UInt8,
        cadence: UInt8,
        accumulatedPower: UInt16,
        instantaneousPower: UInt16,
        status: TrainerStatus,
        flags: TrainerFlags,
        state: FEState
    )

    case trainerSpecificTorque(count: UInt8,
        revolutions: UInt8,
        period: Float,
        torqueNm: Float,
        state: FEState
    )

    //
    case basicResistance(resistance: Float)

    //
    case targetPower(target: Float)

    //
    case windResistance(coefficient: Float, windspeed: Int8, factor: Float)

    //
    case trackResistance(coefficient: Float, grade: Float)

    //
    case feCapabilities(maxResistance: UInt16, capabilities: FECapabilities)

    //
    case userConfiguration(userWeightKg: Float, bicycleWeightKg: Float, diameterOffset: UInt8,
        wheelDiameterM: Float, ratio: Float)

    //
    case requestData

    //
    case commandStatus(commandId: UInt8, sequence: UInt8, status: UInt8, data: UInt32)

    //
    case manufacturersId(hardwareId: UInt8, manufacturer: UInt16, model: UInt16)

    //
    case productInformation(majorVersion: UInt8, minorVersion: UInt8, serial: UInt32)

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
        case 21: self = FECResponse.stationaryBikeSpecific(payload)
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

    // 7.4.1 Data Page 1 (0x01) – Calibration Request and Response Page (p.40)
    private static func calibrationResponse(_ payload: [UInt8]) -> FECResponse {
        let features = CalibrationRequest(rawValue: payload[1])
        let temperature = Float(payload[3] / 2) - 25

        let zeroOffset: UInt16? = features.contains(.zeroOffsetCalibration)
            ? UInt16(payload[4]) | (UInt16(payload[5]) << 8)
            : nil

        let spindown: UInt16? = features.contains(.spindownCalibration)
            ? UInt16(payload[6]) | (UInt16(payload[7]) << 8)
            : nil

        return .calibrationResponse(temp: temperature, zeroOffset: zeroOffset, spindownMs: spindown)
    }

    // 7.4.2 Data Page 2 (0x02) – Calibration in Progress (p.42)
    private static func calibrationProgress(_ payload: [UInt8]) -> FECResponse {
        let status = payload[1]

        let zeroOffsetStatus = CalibrationStatus(rawValue: (status >> 7) & 0x1)!
        let spindownStatus   = CalibrationStatus(rawValue: (status >> 6) & 0x1)!

        let speedCondition = CalibrationSpeedCondition(rawValue: (payload[2] >> 6) & 0x3)!
        let tempCondition = CalibrationTemperatureCondition(rawValue: (payload[2] >> 4) & 0x3)!

        let temperature = Float(payload[3] / 2) - 25

        let targetSpeedMs = Float(UInt16(payload[4]) | (UInt16(payload[5]) << 8)) / 1000
        let targetSpindown = UInt16(payload[6]) | (UInt16(payload[7]) << 8)

        return .calibrationProgress(temp: temperature,
                                    zeroOffsetStatus: zeroOffsetStatus,
                                    spindownStatus: spindownStatus,
                                    speedCondition: speedCondition,
                                    tempCondition: tempCondition,
                                    targetSpeedMs: targetSpeedMs,
                                    targetSpindownms: targetSpindown)
    }

    // 7.5.2 Data Page 16 (0x10) – General FE Data (p.44)
    private static func generalFEData(_ payload: [UInt8]) -> FECResponse {
        let type = EquipmentType(rawValue: payload[1]) ?? .unknown
        let elapsed = Float(payload[2]) / 4
        let distance = payload[3]
        let speed = Float(UInt16(payload[4]) | (UInt16(payload[5]) << 8)) / 1000
        let heartrate = payload[6]
        let capabilities = GeneralFECapabilities(rawValue: payload[7] & 0xf)

        let feState = FEState(rawValue: (payload[7] >> 4) & 0x3)!
        let lapToggle = (payload[7] >> 7) & 0x1

        return .generalFEData(capabilities: capabilities,
                              type: type,
                              elapsed: elapsed,
                              distanceM: distance,
                              heartrate: heartrate,
                              speedMs: speed,
                              feState: feState,
                              lapToggle: lapToggle
        )
    }



    // 7.5.4 Data Page 18 (0x12) – General FE Metabolic Data (p.50)
    private static func generalMetabolicData(_ payload: [UInt8]) -> FECResponse {
        let mets = Float(UInt16(payload[2]) | (UInt16(payload[3]) << 8)) * 0.01
        let burnRate = Float(UInt16(payload[4]) | (UInt16(payload[5]) << 8)) * 0.1
        let calories = payload[6]
        let capabilities = MetabolicCapabilities(rawValue: payload[7] & 3)
        let state = FEState(rawValue: (payload[7] >> 4) & 0xf) ?? .reserved

        return .generalMetabolicData(mets: mets,
                                     burnRate: burnRate,
                                     calories: calories,
                                     capabilities: capabilities,
                                     state: state)
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

    // 7.6.3 Page 21 (0x15) – Specific Stationary Bike Data (p.55)
    // NOTE: This is like a spin-class bike, *not* what a smart Turbo-trainer appears as.
    private static func stationaryBikeSpecific(_ payload: [UInt8]) -> FECResponse {
        let cadence = payload[4]
        let power = UInt16(payload[5]) | (UInt16(payload[6]) << 8)
        let state = FEState(rawValue: (payload[7] >> 4) & 0xf) ?? .reserved

        return .stationaryBikeSpecific(cadence: cadence, power: power, state: state)
    }

    // 7.6.7 Page 25 (0x19) – Specific Trainer Data (p.60)
    private static func trainerSpecific(_ payload: [UInt8]) -> FECResponse {
        let updates = payload[1]
        let cadence = payload[2]

        let accumulatedPower = UInt16(payload[3]) | (UInt16(payload[4]) << 8)
        let instantPower = UInt16(payload[5]) | (UInt16(payload[6] & 0xf) << 8)
        let status = TrainerStatus(rawValue: payload[6] >> 4)
        let flags = TrainerFlags(rawValue: payload[7] & 0xf) ?? .undetermined
        let state = FEState(rawValue: payload[7] >> 4) ?? .reserved

        return .trainerSpecific(updates: updates, cadence: cadence,
                                accumulatedPower: accumulatedPower,
                                instantaneousPower: instantPower,
                                status: status,
                                flags: flags,
                                state: state
        )
    }

    // 7.6.8 Page 26 (0x1A) – Specific Trainer Torque Data (p.63)
    private static func trainerSpecificTorque(_ payload: [UInt8]) -> FECResponse {
        let count = payload[1]
        let revolutions = payload[2]
        let wheelPeriod = Float(UInt16(payload[3]) | (UInt16(payload[4]) << 8)) / 2048
        let torqueNm = Float(UInt16(payload[5]) | (UInt16(payload[6]) << 8)) / 32

        let state = FEState(rawValue: payload[7] >> 4) ?? .reserved

        return .trainerSpecificTorque(count: count,
                                        revolutions: revolutions,
                                        period: wheelPeriod,
                                        torqueNm: torqueNm,
                                        state: state
        )
    }

    // 7.8.1 Data Page 48 (0x30) – Basic Resistance (p.68)
    private static func basicResistance(_ payload: [UInt8]) -> FECResponse {
        let resistance = Float(payload[7]) / 2

        return .basicResistance(resistance: resistance)
    }

    // 7.8.2 Data Page 49 (0x31) – Target Power (p.69)
    private static func targetPower(_ payload: [UInt8]) -> FECResponse {
        let target = Float(UInt16(payload[6]) | (UInt16(payload[7]) << 8)) / 4

        return .targetPower(target: target)
    }

    // 7.8.3 Data Page 50 (0x32) – Wind Resistance (p.70)
    private static func windResistance(_ payload: [UInt8]) -> FECResponse {
        let coefficient = Float(payload[5]) * 0.01
        let windspeed = windSpeed(from: payload[6])
        let factor = Float(payload[7]) * 0.01

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
