//
//  ViewController.swift
//  central
//
//  Created by HidekuniKajita on 2016/07/12.
//  Copyright © 2016年 HidekuniKajita. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var settingCharacteristic: CBCharacteristic!
    var outputCharacteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        NSLog("state: \(central.state)")
    }

    @IBAction func scan(sender: AnyObject) {
        NSLog("SCAN Start")
      self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    @IBAction func led(sender: AnyObject) {
        NSLog("LED ON")
        
        var value: CUnsignedChar = 0x01 << 1
        let data: NSData = NSData(bytes: &value, length: 1)
        
        self.peripheral.writeValue(data, forCharacteristic: self.settingCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
        
        self.peripheral.writeValue(data, forCharacteristic: self.outputCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }

    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        if peripheral.name == "konashi2-f025aa" {
          self.peripheral = peripheral
          self.centralManager.connectPeripheral(self.peripheral, options: nil)
        }

        NSLog("BLEデバイス \(peripheral)")
        
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        NSLog("接続成功")
        self.centralManager.stopScan()
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("接続失敗")
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let services: NSArray = peripheral.services!
        NSLog("\(services.count) 個のサービスを発見 \(services)")
        
        for obj in services {
            if let service = obj as? CBService {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        let characteristics: NSArray = service.characteristics!
        
        NSLog("\(characteristics.count) 個のキャラクラリスティックを発見")
        
        for obj in characteristics {
            if let characteristic = obj as? CBCharacteristic {
                if characteristic.UUID.isEqual(CBUUID(string: "229B3000-03FB-40DA-98A7-B0DEF65C2D4B")) {
                    self.settingCharacteristic = characteristic
                } else if characteristic.UUID.isEqual(CBUUID(string: "229B3002-03FB-40DA-98A7-B0DEF65C2D4B")) {
                    self.outputCharacteristic = characteristic
                } else if characteristic.UUID.isEqual(CBUUID(string: "229B3003-03FB-40DA-98A7-B0DEF65C2D4B")) {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
                
                if characteristic.properties == CBCharacteristicProperties.Read {
                    peripheral.readValueForCharacteristic(characteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        NSLog("読み出し成功 service UUID: \(characteristic.service.UUID), characteristic UUID: \(characteristic.UUID), value: \(characteristic.value)")
        
        if characteristic.UUID.isEqual(CBUUID(string: "2A3A")) {
            var byte: CUnsignedChar = 0
            characteristic.value?.getBytes(&byte, length: 1)
            NSLog("Battery LEvel \(byte)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            NSLog("Notify状態更新失敗: \(error)")
        } else {
            NSLog("Notify状態更新成功: \(characteristic.isNotifying)")
        }
    }
    
}

