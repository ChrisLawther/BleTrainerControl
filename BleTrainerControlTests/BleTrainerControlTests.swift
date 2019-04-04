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

        return bytes.map { String(format: "%02x", $0) }.joined()
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
            guard let actual = try? FECRequest.basicResistance(value: resistance).message() else {
                return XCTFail("Should not have thrown")
            }

            XCTAssertEqual(expected, actual, "Mismatched results for resistance value \(resistance)")
        }
    }

    func testBasicResistanceRejectsOutOfRange() {
        XCTAssertThrowsError(try FECRequest.basicResistance(value: -1).message())
        XCTAssertThrowsError(try FECRequest.basicResistance(value: 101).message())
    }

    func testTargetPowerMatches() {
        let btle = BTLETrainerManager()

        let values: [Float] = [0, 1, 50, 69, 99, 123, 450, 999]
        for target in values {
            let expected = btle.generateTargetPower(target)
            guard let actual = try? FECRequest.targetPower(value: target).message() else {
                return XCTFail("Should NOT have thrown")
            }

            XCTAssertEqual(expected, actual, "Mismatched results for target power value \(target)")
        }
    }

    func testWindResistanceCoefficientMatches() {
        let btle = BTLETrainerManager()

        let resistances: [Float] = [0, 0.1, 1, 1.23, 1.86]
        let speeds: [Float] = [-50, -1, 0, 1, 50, 120]
        let factors: [Float] = [0, 0.1, 0.5, 0.99, 1]

        for resistance in resistances {
            for speed in speeds {
                for factor in factors {
                    let expected = btle.generateWindResistanceCoefficient(resistance, windSpeed: speed,
                                                                          draftingFactor: factor)
                    guard let actual = try? FECRequest.windResistanceCoefficient(
                        kgMValue: resistance,
                        windspeed: speed,
                        draftingFactor: factor).message() else {
                            return XCTFail("Should NOT have thrown")
                    }

                    XCTAssertEqual(expected, actual,
                        "Mismatched results for resistance \(resistance), speed \(speed) and factor \(factor)")
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
                guard let actual = try? FECRequest.trackResistance(
                    grade: grade, coefficient: coefficient).message() else {
                        return XCTFail("Should NOT have thrown")
                }

                XCTAssertEqual(expected, actual, "Mismatched results for grade \(grade) and coefficient \(coefficient)")
            }
        }
    }

    func testPageRequestMatches() {
        let btle = BTLETrainerManager()
        for page in 0...50 {
            let expected = btle.generateRequestPage(page)
            guard let actual = try? FECRequest.request(page: page).message() else {
                return XCTFail("Should NOT have thrown")
            }

            XCTAssertEqual(expected, actual, "Mismatched results for page \(page)")
        }
    }

}
