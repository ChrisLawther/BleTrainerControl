//
//  FECResponseTests.swift
//  BleTrainerControlTests
//
//  Created by Chris on 01/04/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

// swiftlint:disable file_length

import XCTest

private extension Array where Element == UInt8 {
    var checksum: UInt8 {
        return self.reduce(0, {$0 ^ $1})
    }
}

extension UInt16 {
    var hiLo: (UInt8, UInt8) {
        return (UInt8((self & 0xff00) >> 8), UInt8((self & 0x00ff) >> 0))
    }
}

extension UInt32 {
    // swiftlint:disable:next large_tuple
    var nibbles: (UInt8, UInt8, UInt8, UInt8) {
        return (
            UInt8((self >> 24) & 0xff),
            UInt8((self >> 16) & 0xff),
            UInt8((self >> 8) & 0xff),
            UInt8((self >> 0) & 0xff)
        )
    }
}

enum CBUUIDs {
    static let vortexPrimary = CBUUID(string: "669AA305-0C08-969E-E211-86AD5062675F")
    static let fecRead = CBUUID(string: "6E40FEC2-B5A3-F393-E0A9-E50E24DCCA9E")
    static let fecWrite = CBUUID(string: "6E40FEC3-B5A3-F393-E0A9-E50E24DCCA9E")
}

enum TestData {
    static func page1(temp: UInt8, zeroOffset: UInt16? = nil, spindownResp: UInt16? = nil) -> Data {
        let features: UInt8 = (spindownResp != nil ? 1 : 0) << 7
                            | (zeroOffset   != nil ? 1 : 0) << 6

        let zero = zeroOffset ?? 0
        let spindown = spindownResp ?? 0

        let (zeroHi, zeroLo) = zero.hiLo
        let (spinHi, spinLo) = spindown.hiLo

        let packet = [0xa4, 0x09, 0x00, 0x00,
                      1, features, 0x00, temp,
                      zeroLo, zeroHi, spinLo, spinHi]

        return Data(packet + [packet.checksum])
    }

    static func page2(temp: UInt8, speedCondition: UInt8, tempCondition: UInt8,
                      targetSpeed: UInt16, targetSpindown: UInt16) -> Data {

        let status: UInt8 = (1 << 7) | (1 << 6)
        let conditions: UInt8 = UInt8(speedCondition & 0x03) << 6
            | UInt8(tempCondition & 0x03) << 4

        let (speedHi, speedLo) = targetSpeed.hiLo
        let (spinHi, spinLo) = targetSpindown.hiLo

        let packet = [0xa4, 0x09, 0x00, 0x00,
                      2, status, conditions, temp,
                      speedLo, speedHi, spinLo, spinHi]

        return Data(packet + [packet.checksum])
    }

    // swiftlint:disable:next function_parameter_count
    static func page16(capabilities: FECapabilities, type: EquipmentType, elapsed: UInt8,
                       distance: UInt8, heartrate: UInt8, speed: UInt16) -> Data {

        let (speedHi, speedLo) = speed.hiLo

        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               16, type.rawValue, elapsed, distance,
                               speedLo, speedHi, heartrate, capabilities.rawValue]

        return Data(packet + [packet.checksum])
    }

    static func page17(cycleLength: UInt8, incline: UInt16, resistanceLevel: UInt8) -> Data {

        let (inclineHi, inclineLo) = incline.hiLo

        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               17, 0, 0, cycleLength,
                               inclineLo, inclineHi, resistanceLevel, 0]

        return Data(packet + [packet.checksum])
    }

    static func page25(updates: UInt8, cadence: UInt8, power: UInt16, instantaneous: UInt16) -> Data {
        let (accumulatedHi, accumulatedLo) = power.hiLo
        let (instantHi, instantLo) = instantaneous.hiLo

        // NOTE: The Obj-C implementation does some funky and possibly wrong stuff,
        //       bit-twiddling (in string form!)
        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               25, updates, cadence, accumulatedLo,
                               accumulatedHi, instantLo, instantHi, 0]

        return Data(packet + [packet.checksum])
    }

    static func page48(resistance: UInt8) -> Data {
        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               48, 0, 0, 0,
                               0, 0, 0, resistance]

        return Data(packet + [packet.checksum])
    }

    static func page49(target: UInt16) -> Data {
        let (powerHi, powerLo) = target.hiLo

        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               49, 0, 0, 0,
                               0, 0, powerLo, powerHi]

        return Data(packet + [packet.checksum])
    }

    static func page50(coefficient: UInt8, windSpeed: UInt8, factor: UInt8) -> Data {
        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               50, 0, 0, 0,
                               0, coefficient, windSpeed, factor]

        return Data(packet + [packet.checksum])
    }

    static func page51(grade: UInt16, resistance: UInt8) -> Data {
        let (gradeHi, gradeLo) = grade.hiLo

        // NOTE: Obj-C implementation *was* getting resistance from byte 6 (now 7)
        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               51, 0, 0, 0,
                               0, gradeLo, gradeHi, resistance]

        return Data(packet + [packet.checksum])
    }

    static func page54(max: UInt16, capabilities: FECapabilities) -> Data {
        let (maxHi, maxLo) = max.hiLo

        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               54, 0, 0, 0,
                               0, maxLo, maxHi, capabilities.rawValue]

        return Data(packet + [packet.checksum])
    }

    static func page55(userWeight: UInt16, bicycleWeight: UInt16, diameterOffset: UInt8,
                       wheel diameter: UInt8, ratio: UInt8) -> Data {

        assert(diameterOffset < 16, "diameterOffset is a 4-bit value")
        let (userHi, userLo) = userWeight.hiLo

        let weightAndOffset = (bicycleWeight << 4) | UInt16((diameterOffset & 0x0f))

        let (bikeHi, bikeLo) = weightAndOffset.hiLo

        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               55, userLo, userHi, 0,
                               bikeLo, bikeHi, diameter, ratio]

        return Data(packet + [packet.checksum])
    }

    static func page71(commandId: UInt8, sequence: UInt8, status: UInt8, data: UInt32) -> Data {

        // swiftlint:disable:next identifier_name
        let (data_3, data_2, data_1, data_0) = data.nibbles

        // NOTE: Obj-C implementation doesn't attempt to endian-swap this 32-bit value
        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               71, commandId, sequence, status,
                               data_3, data_2, data_1, data_0]

        return Data(packet + [packet.checksum])
    }

    static func page80(hwId: UInt8, manufacturer: UInt16, model: UInt16) -> Data {
        let (manuHi, manuLo) = manufacturer.hiLo
        let (modelHi, modelLo) = model.hiLo

        // NOTE: Obj-C implementation doesn't attempt to endian-swap this 32-bit value
        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               80, 0, 0, hwId,
                               manuLo, manuHi, modelLo, modelHi]

        return Data(packet + [packet.checksum])
    }

    static func page81(major: UInt8, minor: UInt8, serial: UInt32) -> Data {
        // swiftlint:disable:next identifier_name
        let (serial_3, serial_2, serial_1, serial_0) = serial.nibbles

        let packet: [UInt8] = [0xa4, 0x09, 0x00, 0x00,
                               81, 0, minor, major,
                               serial_0, serial_1, serial_2, serial_3]

        return Data(packet + [packet.checksum])
    }
}

class TrainerManagerTests: XCTestCase {

    func testPage1WithAllDataIsCorrectlyDecoded() {
        let btle = BTLETrainerManager()

        let temp: UInt8 = 60
        let zeroOffset: UInt16 = 0x0123
        let spindown: UInt16 = 0x1234
        let data = TestData.page1(temp: temp, zeroOffset: zeroOffset, spindownResp: spindown)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        let expectedTemp = Float(temp / 2 - 25)

        XCTAssertEqual(1, btle.zeroOffsetCalibrationResponse)
        XCTAssertEqual(Int(zeroOffset), btle.zeroOffsetResponse)
        XCTAssertEqual(1, btle.spinDownCalibrationResponse)
        XCTAssertEqual(Float(spindown), btle.spinDownTimeResponseSeconds)
        XCTAssertEqual(expectedTemp, btle.temperatureResponseDegC)

        let response = FECResponse(from: data)

        if case let .calibrationResponse(decodedTemp, decodedOffset, decodedSpindown)? = response {
            XCTAssertEqual(temp, decodedTemp)
            XCTAssertEqual(zeroOffset, decodedOffset)
            XCTAssertEqual(spindown, decodedSpindown)
        } else {
            XCTFail("Data didn't decode as .calibrationResponse")
        }
    }

    func testPage1WithoutSpindownIsCorrectlyDecoded() {
        let btle = BTLETrainerManager()

        let temp: UInt8 = 60
        let zeroOffset: UInt16 = 0x0123
        let data = TestData.page1(temp: temp, zeroOffset: zeroOffset)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        let expectedTemp = Float(temp / 2 - 25)

        XCTAssertEqual(1, btle.zeroOffsetCalibrationResponse)
        XCTAssertEqual(Int(zeroOffset), btle.zeroOffsetResponse)
        XCTAssertEqual(0, btle.spinDownCalibrationResponse)
        XCTAssertEqual(0, btle.spinDownTimeResponseSeconds)
        XCTAssertEqual(expectedTemp, btle.temperatureResponseDegC)
    }

    func testPage1WithoutZeroOffsetIsCorrectlyDecoded() {
        let btle = BTLETrainerManager()

        let temp: UInt8 = 60
        let spindown: UInt16 = 0x5555
        let data = TestData.page1(temp: temp, spindownResp: spindown)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        let expectedTemp = Float(temp / 2 - 25)

        XCTAssertEqual(0, btle.zeroOffsetCalibrationResponse)
        XCTAssertEqual(0, btle.zeroOffsetResponse)
        XCTAssertEqual(1, btle.spinDownCalibrationResponse)
        XCTAssertEqual(Float(spindown), btle.spinDownTimeResponseSeconds)
        XCTAssertEqual(expectedTemp, btle.temperatureResponseDegC)
    }

    func testPage2() {
        let btle = BTLETrainerManager()

        let spindown: UInt16 = 0x3456
        let speed: UInt16 = 0x5555
        let temp: UInt8 = 60

        let speedCondition: UInt8 = 0x01
        let tempCondition: UInt8 = 0x02

        let data = TestData.page2(temp: temp, speedCondition: speedCondition,
                                  tempCondition: tempCondition, targetSpeed: speed, targetSpindown: spindown)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        let expectedTemp = Float(temp / 2 - 25)
        XCTAssertEqual(expectedTemp, btle.currentTemperatureDegC)

        XCTAssertEqual(Int(speedCondition), btle.speedCondition)
        XCTAssertEqual(Int(tempCondition), btle.temperatureCondition)

        let expectedKmh = Float(speed) * 3.6 / 1000
        XCTAssertEqual(expectedKmh, btle.targetSpeedKmH)

        let expectedSpindownSeconds = Float(spindown) / 1000
        XCTAssertEqual(expectedSpindownSeconds, btle.targetSpinDownTimeSeconds)

        let response = FECResponse(from: data)
        let expectation = FECResponse.calibrationProgress(temp: temp,
                                                          zeroOffsetStatus: 1,
                                                          spindownStatus: 1,
                                                          speedCondition: speedCondition,
                                                          tempCondition: tempCondition,
                                                          targetSpeed: speed,
                                                          targetSpindown: spindown)
        XCTAssertEqual(expectation, response)
    }

    func testPage16() {
        let btle = BTLETrainerManager()

        let capabilities: FECapabilities = [.distanceTravelled, .virtualSpeed, .hrDataSource]
        let type: EquipmentType = .trainer
        let elapsed: UInt8 = 123
        let distance: UInt8 = 69
        let heartrate: UInt8 = 180
        let speed: UInt16 = 12345

        let expectedSpeed = Float(speed) * 3.6 / 1000

        let data = TestData.page16(capabilities: capabilities, type: type, elapsed: elapsed,
                                   distance: distance, heartrate: heartrate, speed: speed)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Int(type.rawValue), btle.equipmentType)

        XCTAssertEqual(0.25 * Float(elapsed), btle.elapsedTimeSeconds)
        XCTAssertEqual(Int(distance), btle.distanceTraveledMeters)
        XCTAssertEqual(Int(heartrate), btle.heartRateBPM)
        XCTAssertEqual(expectedSpeed, btle.speedKmH)

        let response = FECResponse(from: data)
        let expectation = FECResponse.generalFEData(capabilities: capabilities,
                                                    type: type,
                                                    elapsed: elapsed,
                                                    distance: distance,
                                                    heartrate: heartrate,
                                                    speed: expectedSpeed)
        XCTAssertEqual(expectation, response)
    }

    func testPage17() {
        let btle = BTLETrainerManager()

        let incline: UInt16 = 0x9999
        let resistance: UInt8 = 0x69
        let cycleLength: UInt8 = 23

        let data = TestData.page17(cycleLength: cycleLength, incline: incline, resistanceLevel: resistance)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Float(incline) * 0.01, btle.inclinePercent)
        XCTAssertEqual(Float(cycleLength) * 0.01, btle.cycleLengthM, accuracy: 0.01)
        XCTAssertEqual(Float(resistance) / 2, btle.resistanceLevelPercent)

        let inclinePercentage = Float(incline) / 100

        let response = FECResponse(from: data)
        let expectation = FECResponse.generalSettings(cycleLength: cycleLength,
                                                      inclinePercentage: inclinePercentage,
                                                      resistanceLevel: resistance / 2)
        XCTAssertEqual(expectation, response)
    }

    func testPage25() {
        let btle = BTLETrainerManager()

        let updates: UInt8 = 23
        let cadence: UInt8 = 111
        let power: UInt16 = 458
        let instantaneous: UInt16 = 999

        let data = TestData.page25(updates: updates, cadence: cadence, power: power, instantaneous: instantaneous)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Int(updates), btle.updateEventCount)
        XCTAssertEqual(Int(cadence), btle.cadenceRPM)
        XCTAssertEqual(Int(power), btle.accumulatedPowerW)
        XCTAssertEqual(Int(instantaneous), btle.powerW)

        let response = FECResponse(from: data)
        let expectation = FECResponse.trainerSpecific(updates: updates,
                                                      cadence: cadence,
                                                      accumulatedPower: power,
                                                      instantaneousPower: instantaneous)
        XCTAssertEqual(expectation, response)
    }

    // Basic resistance
    func testPage48() {
        let btle = BTLETrainerManager()

        let resistance: UInt8 = 99
        let expectedResistance = Float(resistance) / 2

        let data = TestData.page48(resistance: resistance)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(expectedResistance, btle.totalResistancePercent)

        let response = FECResponse(from: data)
        let expectation = FECResponse.basicResistance(resistance: expectedResistance)

        XCTAssertEqual(expectation, response)
    }

    // Target power
    func testPage49() {
        let btle = BTLETrainerManager()

        let targetPower: UInt16 = 456
        let expectedPower = Float(targetPower) / 4

        let data = TestData.page49(target: targetPower)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(expectedPower, btle.targetPowerW)

        let response = FECResponse(from: data)
        let expectation = FECResponse.targetPower(target: expectedPower)

        XCTAssertEqual(expectation, response)
    }

    // Wind resistance
    func testPage50() {
        let btle = BTLETrainerManager()

        let coefficient: UInt8 = 123
        let windSpeed: UInt8 = 134
        let factor: UInt8 = 99

        let data = TestData.page50(coefficient: coefficient, windSpeed: windSpeed, factor: factor)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Float(coefficient) * 0.01, btle.windResistanceCoefficientKgM)
        XCTAssertEqual(Float(windSpeed) - 127, btle.windSpeedKmH)
        XCTAssertEqual(Float(factor) / 100, btle.draftingFactor)

        let response = FECResponse(from: data)
        let expectation = FECResponse.windResistance(coefficient: coefficient,
                                                     windspeed: windSpeed,
                                                     factor: factor)

        XCTAssertEqual(expectation, response)
    }

    // Track resistance
    func testPage51() {
        let btle = BTLETrainerManager()

        let grade: UInt16 = 0x1234
        let resistance: UInt8 = 77

        let gradePercentage = Float(grade) / 100
        let rrCoefficient = Float(resistance) * 5 * pow(10, -5)

        let data = TestData.page51(grade: grade, resistance: resistance)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(gradePercentage, btle.gradePercent)
        XCTAssertEqual(rrCoefficient, btle.rollingResistanceCoefficient)

        let response = FECResponse(from: data)
        let expectation = FECResponse.trackResistance(coefficient: rrCoefficient, grade: gradePercentage)

        XCTAssertEqual(expectation, response)
    }

    // FE capabilities
    func testPage54() {
        let btle = BTLETrainerManager()

        let max: UInt16 = 12345
        let capabilities: FECapabilities = [.basicResistanceMode, .targetPowerMode, .simulationMode]
        let data = TestData.page54(max: max, capabilities: capabilities)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Int(max), btle.maximumResistanceN)
        XCTAssertTrue(btle.supportedMode.contains("resistance : true"))
        XCTAssertTrue(btle.supportedMode.contains("power : true"))
        XCTAssertTrue(btle.supportedMode.contains("Simulation : true"))

        let response = FECResponse(from: data)
        let expectation = FECResponse.feCapabilities(maxResistance: max, capabilities: capabilities)

        XCTAssertEqual(expectation, response)
    }

    // User configuration
    func testPage55() {
        let weight: UInt16 = 7500
        let wheelDiameter: UInt8 = 222
        let diameterOffset: UInt8 = 13
        let bicycleWeight: UInt16 = 100
        let ratio: UInt8 = 205

        let weightKg = Float(weight) / 100
        let diameterM = Float(wheelDiameter) / 100
        let bikeKg = Float(bicycleWeight) / 20
        let gearRatio = Float(ratio) * 0.03

        let btle = BTLETrainerManager()
        let data = TestData.page55(userWeight: weight, bicycleWeight: bicycleWeight,
                                   diameterOffset: diameterOffset, wheel: wheelDiameter, ratio: ratio)

        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(weightKg, btle.userWeightKg)
        XCTAssertEqual(Int(diameterOffset), btle.bicycleWheelDiameterOffsetMm)

        XCTAssertEqual(bikeKg, btle.bicycleWeightKg)

        XCTAssertEqual(diameterM, btle.bicycleWheelDiameterM)
        XCTAssertEqual(gearRatio, btle.gearRatio)

        let response = FECResponse(from: data)
        let expectation = FECResponse.userConfiguration(userWeightKg: weightKg,
                                                        bicycleWeightKg: bikeKg,
                                                        diameterOffset: diameterOffset,
                                                        wheelDiameterM: diameterM,
                                                        ratio: gearRatio)
        XCTAssertEqual(expectation, response)
    }

    // Command status
    func testPage71() {
        let command: UInt8 = 0x12
        let sequence: UInt8 = 0x34
        let status: UInt8 = 0x56
        let payload: UInt32 = 0x1234abcd

        let btle = BTLETrainerManager()
        let data = TestData.page71(commandId: command, sequence: sequence, status: status, data: payload)
        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Int(command), btle.lastReceivedCommandID)
        XCTAssertEqual(Int(sequence), btle.sequence)
        XCTAssertEqual(Int(status), btle.commandStatus)
        XCTAssertEqual(String(format: "%08x", payload), btle.dataString)

        let response = FECResponse(from: data)
        let expectation = FECResponse.commandStatus(commandId: command,
                                                    sequence: sequence,
                                                    status: status,
                                                    data: payload)
        XCTAssertEqual(expectation, response)
    }

    // Manufacturer's identification
    func testPage80() {
        let hwRevision: UInt8 = 99
        let manufacturerId: UInt16 = 0x9999
        let modelNumber: UInt16 = 0x5a5a
        let btle = BTLETrainerManager()

        let data = TestData.page80(hwId: hwRevision, manufacturer: manufacturerId, model: modelNumber)
        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Int(hwRevision), btle.hwRevision)
        XCTAssertEqual(Int(manufacturerId), btle.manufacturerID)
        XCTAssertEqual(Int(modelNumber), btle.modelNumber)

        let response = FECResponse(from: data)
        let expectation = FECResponse.manufacturersId(hardwareId: hwRevision,
                                                      manufacturer: manufacturerId,
                                                      model: modelNumber)
        XCTAssertEqual(expectation, response)
    }

    // Product information
    func testPage81() {
        let swRevisionMinor: UInt8 = 69
        let swRevisionMajor: UInt8 = 3
        let serialNumber: UInt32 = 0x12ab56ef

        let btle = BTLETrainerManager()
        let data = TestData.page81(major: swRevisionMajor, minor: swRevisionMinor, serial: serialNumber)
        btle.dataReceived(byCharacteristic: CBUUIDs.fecRead, data: data, error: nil)

        XCTAssertEqual(Int(swRevisionMinor), btle.swRevisionSupplemental)
        XCTAssertEqual(Int(swRevisionMajor), btle.swRevisionMain)
        XCTAssertEqual(Int(serialNumber), btle.serialNumber)

        let response = FECResponse(from: data)
        let expectation = FECResponse.productInformation(majorVersion: swRevisionMajor,
                                                         minorVersion: swRevisionMinor,
                                                         serial: serialNumber)
        XCTAssertEqual(expectation, response)
    }
}
