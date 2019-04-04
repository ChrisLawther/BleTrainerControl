//: Playground - noun: a place where people can play

import Foundation

enum FECRequest {

    case calibrationRequest(value: CalibrationRequest)

    case basicResistance(value: Float)
    case targetPower(value: Float)
    case windResistanceCoefficient(kgMValue: Float, windspeed: Float, draftingFactor: Float)
    case trackResistance(grade: Float, coefficient: Float)
    case request(page: Int)

    func message() throws -> Data {
        return try messageBody().checksummed()
    }

    private func messageBody() throws -> Data {
        switch self {
        case .basicResistance(let value):
            return try basicResistanceData(for: value)
        case .targetPower(let power):
            return try targetPowerData(for: power)
        case .windResistanceCoefficient(let kgMValue, let windspeed, let draftingFactor):
            return try windResistanceCoefficientData(kgmValue: kgMValue,
                                                     windspeed: windspeed, draftingFactor: draftingFactor)
        case .trackResistance(let grade, let coefficient):
            return try trackResistanceData(for: grade, coefficient: coefficient)
        case .calibrationRequest(let value):
            return try calibrationRequest(for: value)
        case .request(let page):
            return try requestData(for: page)
        }
    }

    private func basicResistanceData(for resistance: Float) throws -> Data {
        let range: ClosedRange<Float> = 0...100

        guard range.contains(resistance) else {
            throw FECError.outOfRange(range, resistance)
        }

        let page: UInt8 = 48
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, UInt8(2 * resistance)])
    }

    private func targetPowerData(for power: Float) throws -> Data {
        let range: ClosedRange<Float> = 0...10000
        guard range.contains(power) else {
            throw FECError.outOfRange(range, power)
        }

        let page: UInt8 = 49
        let targetPower: UInt16 = UInt16(power * 4)
        let (powerMsb, powerLsb) = targetPower.bytes()
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, 0xff, powerLsb, powerMsb])
    }

    private func windResistanceCoefficientData(
        kgmValue: Float,
        windspeed: Float,
        draftingFactor: Float
    ) throws -> Data {
        let kgmRange: ClosedRange<Float> = 0...1.86 // Was 2.5
        guard kgmRange.contains(kgmValue) else {
            throw FECError.outOfRange(kgmRange, kgmValue)
        }
        let draftingRange: ClosedRange<Float> = 0...1
        guard draftingRange.contains(draftingFactor) else {
            throw FECError.outOfRange(draftingRange, draftingFactor)
        }

        // Q. Reject illegal windspeed, or just clamp it?
        let windspeed = max(min(windspeed, 127), -127)
        let coefficient = UInt8(kgmValue / 0.01)
        let speed = UInt8(windspeed + 127)
        let factor = UInt8(draftingFactor / 0.01)
        let page: UInt8 = 50
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, coefficient, speed, factor])
    }

    private func trackResistanceData(for grade: Float, coefficient: Float) throws -> Data {
        let gradeRange: ClosedRange<Float> = -200...200
        guard gradeRange.contains(grade) else {
            throw FECError.outOfRange(gradeRange, grade)
        }
        let coefficientRange: ClosedRange<Float> = 0...0.0127 // was 0.0033
        guard coefficientRange.contains(coefficient) else {
            throw FECError.outOfRange(coefficientRange, coefficient)
        }

        // TODO: Confirm valid range of gradient (200?)
        // TODO: Confirm valid range of coefficient (0 .. 0.0033?)
        let gradeValue = UInt16((grade + 200) / 0.01)        // TODO: Confirm this!!!!
        let rrCoeff = UInt8(coefficient / (5 * pow(10, -5)))  // TODO: Confirm this!!!!
        let (gradeMsb, gradeLsb) = gradeValue.bytes()
        let page: UInt8 = 51
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, gradeLsb, gradeMsb, rrCoeff])
    }

    // 7.4.1 Calibration request (p.40)
    private func calibrationRequest(for calibration: CalibrationRequest) throws -> Data {
        let page: UInt8 = 1
        return Data([0xa4, 0x09, 0x4f, 0x05,
                     page, calibration.rawValue, 0x00, 0xff,
                     0xff, 0xff, 0xff, 0xff])
    }

    private func requestData(for page: Int) throws -> Data {
        let pageRange = 0...50
        guard pageRange.contains(page) else {
            throw FECError.outOfIntegerRange(pageRange, page)
        }

        let fePage: UInt8 = 70
        return Data([0xa4, 0x09, 0x4f, 0x05, fePage, 0xff, 0xff, 0xff, 0xff, 0x80, UInt8(page), 0x01])
    }
}

extension Data {
    func asHex() -> String {
        return self.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
