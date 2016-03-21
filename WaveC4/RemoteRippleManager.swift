//
//  RemoteRippleManager.swift
//  WaveC4
//
//  Created by Takahiko Inayama on 3/21/16.
//  Copyright © 2016 TETRA2000. All rights reserved.
//

import Foundation
import CoreBluetooth

class RemoteRippleManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static var sharedInstance = RemoteRippleManager()
    
    private let serviceUUID = CBUUID(string: RIPPLE_SERVICE_UUID)
    private let onRippleCaracteristicUUID = CBUUID(string: ON_RIPPLE_CHARACTERISTIC_UUID)
    
    private var centralManager : CBCentralManager?
    private var peripherals : [CBPeripheral] = []
    
    var delegate : RemoteRippleManagerDelegate?
    
    func startScan() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func stopScan() {
        //TODO: implement
    }
    
    private func addPheripheral(peripheral : CBPeripheral) {
        if !(peripherals.contains(peripheral) ?? false) {
            peripherals.append(peripheral)
        }
    }
    
    private func removePheripherall(peripheral : CBPeripheral) {
        if peripherals.contains(peripheral) ?? false {
            if let index = peripherals.indexOf(peripheral) {
                peripherals.removeAtIndex(index)
            }
        }
    }
    
    private func dataToBool(data : NSData) -> Bool {
        var intVal : NSInteger = 0
        data.getBytes(&intVal, length: sizeof(NSInteger))
        return intVal == 1
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("centralManagerDidUpdateState state:\(central.state.rawValue)")
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            centralManager?.scanForPeripheralsWithServices([serviceUUID], options: nil)
            break
        default:
            print("failed to start scan")
            break
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("didDiscoverPeripheral UUID:\(peripheral.identifier)")
        
        addPheripheral(peripheral)
        central.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral UUID:\(peripheral.identifier)")
        
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didFailToConnectPeripheral UUID:\(peripheral.identifier)")
        
        removePheripherall(peripheral)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral UUID:\(peripheral.identifier)")
    }
    
    //MARK: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices")
        
        for service in peripheral.services?.filter({(s:CBService) in s.UUID.isEqual(serviceUUID) }) ?? [] {
            peripheral.discoverCharacteristics([onRippleCaracteristicUUID], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("didDiscoverCharacteristicsForService")
        
        let characteristicsFilter = { (characteristic: CBCharacteristic) in
            characteristic.UUID.isEqual(CBUUID(string: ON_RIPPLE_CHARACTERISTIC_UUID))
        }
        
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics?.filter(characteristicsFilter) ?? [] {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateValueForCharacteristic")
        
        print(characteristic.value)
        
        if let value = characteristic.value where dataToBool(value) {
            print("received onRipple")
            self.delegate?.onRipple()
        }
    
        // schedule next notification
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateNotificationStateForCharacteristic")
        
        peripheral.readValueForCharacteristic(characteristic)
    }
    
}

protocol RemoteRippleManagerDelegate {
    func onRipple()
}