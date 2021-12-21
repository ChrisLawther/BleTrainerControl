//
//  FECMessages.swift
//  BleTrainerControl
//
//  Created by Chris on 04/04/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import Foundation

enum FECMessages {
    case basicResistanceRequest(resistance: Double)
    case basicResistanceResponse(resistance: Double)
}

extension FECMessages {

    /// Attempt to parse a received message into one of the supported types
    ///
    /// - Parameter data: the received data
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
        case 48: self = FECMessages.basicResistance(payload)
        default: return nil
        }
    }
}

extension FECMessages {
    func message() throws -> Data {
        switch self {

        case .basicResistanceRequest(let value),
            .basicResistanceResponse(let value):
            return try basicResistance(value)
        }
    }

    func basicResistance(_ resistance: Double) throws -> Data {
        let range: ClosedRange<Double> = 0...100

        guard range.contains(resistance) else {
            throw FECError.outOfRange("resistance", range, resistance)
        }

        let page: UInt8 = 48
        return Data([0xa4, 0x09, 0x4f, 0x05,
                     page, 0xff, 0xff, 0xff,
                     0xff, 0xff, 0xff, UInt8(2 * resistance)])
    }

    // 7.8.1 Data Page 48 (0x30) – Basic Resistance (p.68)
    private static func basicResistance(_ payload: [UInt8]) -> FECMessages {
        let resistance = Double(payload[7]) / 2

        return .basicResistanceResponse(resistance: resistance)
    }
}
