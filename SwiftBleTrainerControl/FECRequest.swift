//: Playground - noun: a place where people can play

import Foundation

private extension UInt16 {
    /// Convert a grade % (-200...200) into it's UInt16 representation
    var grade: Double {
        return Double(self) * 0.01 - 200
    }
}

private extension Double {
    /// Convert the transmitted form of grade into a floating point value (-200...200)
    var gradeValue: UInt16 {
        return UInt16(100 * (self + 200))
    }
}

enum FECRequest {

    case calibrationRequest(value: CalibrationRequest)

    case basicResistance(value: Double)
    case targetPower(value: Double)
    case windResistanceCoefficient(kgMValue: Double, windspeed: Double, draftingFactor: Double)
    case trackResistance(grade: Double, coefficient: Double)
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

    private func basicResistanceData(for resistance: Double) throws -> Data {
        let range: ClosedRange<Double> = 0...100

        guard range.contains(resistance) else {
            throw FECError.outOfRange("resistance", range, resistance)
        }

        let page: UInt8 = 48
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, UInt8(2 * resistance)])
    }

    private func targetPowerData(for power: Double) throws -> Data {
        let range: ClosedRange<Double> = 0...10000
        guard range.contains(power) else {
            throw FECError.outOfRange("power", range, power)
        }

        let page: UInt8 = 49
        let targetPower: UInt16 = UInt16(power * 4)
        let (powerMsb, powerLsb) = targetPower.bytes()
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, 0xff, powerLsb, powerMsb])
    }

    private func windResistanceCoefficientData(
        kgmValue: Double,
        windspeed: Double,
        draftingFactor: Double
    ) throws -> Data {
        let kgmRange: ClosedRange<Double> = 0...1.86 // Was 2.5
        guard kgmRange.contains(kgmValue) else {
            throw FECError.outOfRange("kgm", kgmRange, kgmValue)
        }

        let draftingRange: ClosedRange<Double> = 0...1
        guard draftingRange.contains(draftingFactor) else {
            throw FECError.outOfRange("draftingFactor", draftingRange, draftingFactor)
        }

        let windspeedRange: ClosedRange<Double> = -200...200
        guard windspeedRange.contains(windspeed) else {
            throw FECError.outOfRange("windspeed", windspeedRange, windspeed)
        }
        let coefficient = UInt8(kgmValue / 0.01)
        let speed = UInt8(windspeed + 127)
        let factor = UInt8(draftingFactor / 0.01)
        let page: UInt8 = 50
        return Data([0xa4, 0x09, 0x4f, 0x05, page, 0xff, 0xff, 0xff, 0xff, coefficient, speed, factor])
    }

    private func trackResistanceData(for grade: Double, coefficient: Double) throws -> Data {
        let gradeRange: ClosedRange<Double> = -200...200
        guard gradeRange.contains(grade) else {
            throw FECError.outOfRange("grade", gradeRange, grade)
        }
        let coefficientRange: ClosedRange<Double> = 0...0.0127
        guard coefficientRange.contains(coefficient) else {
            throw FECError.outOfRange("coefficient", coefficientRange, coefficient)
        }

        let rrCoeff = UInt8(coefficient / (5 * pow(10, -5)))  // TODO: Confirm this!!!!
        let (gradeMsb, gradeLsb) = grade.gradeValue.bytes()
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
            throw FECError.outOfIntegerRange("page", pageRange, page)
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
