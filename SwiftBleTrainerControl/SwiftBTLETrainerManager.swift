//
//  SwiftBTLETrainerManager.swift
//  BleTrainerControl
//
//  Created by Chris on 01/04/2019.
//  Copyright © 2019 Kinomap. All rights reserved.
//

import Foundation
import CoreBluetooth

class SwiftBTLETrainerManager: NSObject {
    private static let FECRead = CBUUID(string: "6E40FEC2-B5A3-F393-E0A9-E50E24DCCA9E")
}

extension SwiftBTLETrainerManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

    }
}

extension SwiftBTLETrainerManager: CBPeripheralDelegate {

    // swiftlint:disable:next cyclomatic_complexity
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard error == nil else {
            fatalError("\(error!.localizedDescription)")
        }

        let uuid = characteristic.uuid

        guard let data = characteristic.value else {
            print("Read, but no data 😕")
            return
        }

        guard uuid == SwiftBTLETrainerManager.FECRead else {
            return  // Not the data we are looking for
        }

        let sync = data[0]

        guard sync == 0xa4 else {
            return  // Not the packet format we were expecting
        }

        let length = data[1]

        guard data.count == 2 + length else {
            return // Not the quantity we were expecting
        }

        let pageNumber = data[3]

        switch pageNumber {
        case 1: calibrationRequestAndResponse(data)
        case 2: calibrationInProgress(data)
        case 16: generalFEDataPage(data)
        case 17: generalSettings(data)
        case 25: trainerDataPage(data)
        case 48: basicResistance(data)
        case 49: targetPower(data)
        case 50: windResistance(data)
        case 51: trackResistance(data)
        case 54: feCapabilities(data)
        case 55: userConfiguration(data)
        case 70: requestData(data)
        case 71: commandStatus(data)
        case 80: manufacturersIdentification(data)
        case 81: productInformation(data)
        default:
            fatalError("Unexpected page # (\(pageNumber))")
        }
    }

    private func calibrationRequestAndResponse(_ data: Data) {

    }

    private func calibrationInProgress(_ data: Data) {

    }

    private func generalFEDataPage(_ data: Data) {

    }

    private func generalSettings(_ data: Data) {

    }

    private func trainerDataPage(_ data: Data) {

    }

    private func basicResistance(_ data: Data) {

    }

    private func targetPower(_ data: Data) {

    }

    private func windResistance(_ data: Data) {

    }

    private func trackResistance(_ data: Data) {

    }

    private func feCapabilities(_ data: Data) {

    }

    private func userConfiguration(_ data: Data) {

    }

    private func requestData(_ data: Data) {

    }

    private func commandStatus(_ data: Data) {

    }
    private func manufacturersIdentification(_ data: Data) {

    }

    private func productInformation(_ data: Data) {

    }
}
