//
//  BleTrainerControlTests.swift
//  BleTrainerControlTests
//
//  Created by Chris on 22/01/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import XCTest

extension NSData {

    /// Return hexadecimal string representation of NSData bytes
    @objc(kdj_hexadecimalString)
    public var hexadecimalString: String {
        var bytes = [UInt8](repeating: 0, count: length)
        getBytes(&bytes, length: length)

        return bytes.map{ String(format: "%02x", $0) }.joined()
    }
}

class BTLETrainerManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBasicResistanceMatches() {
        let btle = BTLETrainerManager()

        let values: [Float] = [0, 1, 50, 69, 99, 100]
        for resistance in values {
            let expected = btle.generateBasicResistance(resistance)
            let actual = try! FECMessage.basicResistance(value: resistance).message()

            XCTAssertEqual(expected, actual, "Mismatched results for resistance value \(resistance)")
        }
    }

    func testBasicResistanceRejectsOutOfRange() {
        XCTAssertThrowsError(try FECMessage.basicResistance(value: -1).message())
        XCTAssertThrowsError(try FECMessage.basicResistance(value: 101).message())
    }

    func testTargetPowerMatches() {
        let btle = BTLETrainerManager()

        let values: [Float] = [0, 1, 50, 69, 99, 123, 450, 999]
        for target in values {
            let expected = btle.generateTargetPower(target)
            let actual = try! FECMessage.targetPower(value: target).message()

            XCTAssertEqual(expected, actual, "Mismatched results for target power value \(target)")
        }
    }

    func testWindResistanceCoefficientMatches() {
        let btle = BTLETrainerManager()

        let resistances: [Float] = [0, 0.1, 1, 2, 2.5]
        let speeds: [Float] = [-50, -1, 0, 1, 50, 120]
        let factors: [Float] = [0, 0.1, 0.5, 0.99, 1]

        for resistance in resistances {
            for speed in speeds {
                for factor in factors {
                    let expected = btle.generateWindResistanceCoefficient(resistance, windSpeed: speed, draftingFactor: factor)
                    let actual = try! FECMessage.windResistanceCoefficient(kgMValue: resistance, windspeed: speed, draftingFactor: factor).message()

                    XCTAssertEqual(expected, actual, "Mismatched results for resistance \(resistance), speed \(speed) and factor \(factor)")
                }
            }
        }

        btle.sendWindResistanceCoefficient(0.5, windSpeed: 17, draftingFactor: 0.2)
    }

    func testTrackResistanceMatches() {
        let btle = BTLETrainerManager()
        let grades: [Float] = [-200, -33, -2, 0, 7, 13, 69]
        let coefficients: [Float] = [0, 0.001, 0.003]

        for grade in grades {
            for coefficient in coefficients {
                let expected = btle.generateTrackResistance(withGrade: grade, rollingResistanceCoefficient: coefficient)
                let actual = try! FECMessage.trackResistance(grade: grade, coefficient: coefficient).message()

                XCTAssertEqual(expected, actual, "Mismatched results for grade \(grade) and coefficient \(coefficient)")
            }
        }
    }

    func testCalibrationRequestForSpindownMatches() {
        let btle = BTLETrainerManager()

        for spindown in [true, false] {
            for zeroOffset in [true, false] {
                let expected = btle.generateCalibrationRequest(forSpinDown: spindown, forZeroOffset: zeroOffset)
                let actual = try! FECMessage.calibrationRequestForSpindown(spindown: spindown, zeroOffset: zeroOffset).message()

                XCTAssertEqual(expected, actual, "Mismatched results for spindown \(spindown) and zeroOffset \(zeroOffset)")
            }
        }

    }

    func testPageRequestMatches() {
        let btle = BTLETrainerManager()
        for page in 0...50 {
            let expected = btle.generateRequestPage(page)
            let actual = try! FECMessage.request(page: page).message()

            XCTAssertEqual(expected, actual, "Mismatched results for page \(page)")
        }
    }

}


/*
 -(void)sendBasicResistance:(float)totalResistancePercentValue;
 -(NSData *)generateBasicResistance:(float)totalResistancePercentValue;

 -(void)sendTargetPower:(float)targetPowerWValue;
 -(NSData *)generateTargetPower:(float)targetPowerWValue;

 -(void)sendWindResistanceCoefficient:(float)windResistanceCoefficientKgMValue windSpeed:(float)windSpeedKmHValue draftingFactor:(float)draftingFactorValue;
 -(NSData *)generateWindResistanceCoefficient:(float)windResistanceCoefficientKgMValue windSpeed:(float)windSpeedKmHValue draftingFactor:(float)draftingFactorValue;

 -(void)sendTrackResistanceWithGrade:(float)gradePercentValue rollingResistanceCoefficient:(float)rollingResistanceCoefficienValuet;
 -(NSData *)generateTrackResistanceWithGrade:(float)gradePercentValue rollingResistanceCoefficient:(float)rollingResistanceCoefficienValuet;

 //Request page
 -(void)sendRequestPage:(NSInteger)page;
 -(NSData *)generateRequestPage:(NSInteger)page;

 //Calibration
 -(void)sendCalibrationRequestForSpinDown:(BOOL)forSpinDown forZeroOffset:(BOOL)forZeroOffset;
 -(NSData *)generateCalibrationRequestForSpinDown:(BOOL)forSpinDown forZeroOffset:(BOOL)forZeroOffset;
 */
