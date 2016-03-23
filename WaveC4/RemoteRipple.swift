//
//  RemoteRipple.swift
//  WaveC4
//
//  Created by Takahiko Inayama on 3/21/16.
//  Copyright © 2016 TETRA2000. All rights reserved.
//

import Foundation
import CoreBluetooth

class RemoteRipple: NSObject, CBPeripheralManagerDelegate {
    static var sharedInstance = RemoteRipple()

    private var peripheralManager : CBPeripheralManager?

    // FIXME:
    private var hasRippleStarted = false
    
    private var onRippleCharacteristic : CBMutableCharacteristic?
    
    func startAdvertise() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func updateRippleState(hasRippleStarted : Bool) {
        print("updateRippleState \(boolToData(hasRippleStarted))")
        
        self.hasRippleStarted = hasRippleStarted
        
        onRippleCharacteristic?.value = boolToData(hasRippleStarted)
        
        peripheralManager?.updateValue(boolToData(hasRippleStarted), forCharacteristic: onRippleCharacteristic!, onSubscribedCentrals: nil)
    }
    
    private func boolToData(value : Bool) -> NSData {
        var intVal : NSInteger = value ? 1 : 0
        return NSData(bytes: &intVal, length: sizeof(NSInteger))
    }
    
    //MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState state:\(peripheral.state.rawValue)")
        switch peripheral.state {
        case CBPeripheralManagerState.PoweredOn:
            let service = CBMutableService(type: CBUUID(string: RIPPLE_SERVICE_UUID), primary: true)
            
            onRippleCharacteristic = CBMutableCharacteristic(
                type: CBUUID(string: ON_RIPPLE_CHARACTERISTIC_UUID),
                properties: CBCharacteristicProperties.Read,
                value: nil,
                permissions: CBAttributePermissions.Readable
            )
            service.characteristics = [onRippleCharacteristic!]
            peripheral.addService(service)
            
            break
        default:
            print("failed to start advertise")
            break
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        print("didAddService")
        
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.UUID]])
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        print("peripheralManagerDidStartAdvertising")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        print("didReceiveReadRequest")
        
        if let uuid = self.onRippleCharacteristic?.UUID where uuid.isEqual(request.characteristic.UUID){
            request.value = boolToData(hasRippleStarted)
            
            //FIXME:
            self.hasRippleStarted = false
            
            peripheralManager?.respondToRequest(request, withResult: CBATTError.Success)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        print("didSubscribeToCharacteristic")
    }
    
}