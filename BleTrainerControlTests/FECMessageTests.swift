//
//  FECMessageTests.swift
//  BleTrainerControlTests
//
//  Created by Chris on 22/01/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import XCTest

class FECMessageTests: XCTestCase {

    @objc
    func testCorrectMessageLength() {
        let brMessage = try? FECMessage.basicResistance(value: 50).message()
        XCTAssertEqual(brMessage?.count, 13)
    }

    @objc
    func testCorrectChecksum() {
        let brMessage = try? FECMessage.basicResistance(value: 50).message()
        // Expected checksum
        let expectedChecksum = brMessage?.subdata(in: 0..<12).reduce(0) { (checksum, value) in return checksum ^ value }
        XCTAssertEqual(brMessage?.last, expectedChecksum)

        // Valid checksum
        XCTAssertEqual(brMessage!.last! ^ expectedChecksum!, 0)
    }

    @objc
    func testWindResistanceThrowsOnInvalidCoefficients() {
        do {
            _ = try FECMessage.windResistanceCoefficient(kgMValue: 3, windspeed: 17,
                                                         draftingFactor: 0.2).message().asHex()
            XCTFail("Should have thrown")
        } catch {
            // Pass
        }
    }

    @objc
    func testBasicResistanceProducesCorrectMessage() {
        let resistance: UInt8 = 50
        let brMessage = try? FECMessage.basicResistance(value: Float(resistance)).message()
        // Correct page
        XCTAssertEqual(brMessage?[4], 0x30)
        // Correct value
        XCTAssertEqual(brMessage?[11], 2 * resistance)
    }

    @objc
    func testTargetValueProducesCorrectMessage() {
        let target: UInt16 = 123
        let msg = try? FECMessage.targetPower(value: Float(target)).message()
        // Correct page
        XCTAssertEqual(msg?[4], 0x31)
        // Correct value
        let (msb, lsb) = (4 * target).bytes()
        XCTAssertEqual(msg?[10], lsb)
        XCTAssertEqual(msg?[11], msb)
    }
}
