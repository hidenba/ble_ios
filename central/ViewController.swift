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
    var outputCharacteristic: CBCharacteristic!
    @IBOutlet weak var readButton: UIButton!
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var valueLabel: UILabel!
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
      self.scanButton.enabled = false
      self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }


    @IBAction func readAlc(sender: AnyObject) {
        self.readButton.enabled = false
        
        NSTimer.scheduledTimerWithTimeInterval(7.0, target: self, selector: #selector(ViewController.enableButton), userInfo: nil, repeats: false)
        
        var value: CUnsignedChar!
        let data: NSData = NSData(bytes: &value, length: 1)
        self.peripheral.writeValue(data, forCharacteristic: self.outputCharacteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func enableButton() {
        self.readButton.enabled = true
        self.peripheral.readValueForCharacteristic(self.outputCharacteristic)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        NSLog("BLEデバイス \(peripheral)")
        
        if peripheral.name == "GENUINO 101-CCEE" {
          self.peripheral = peripheral
          self.centralManager.connectPeripheral(self.peripheral, options: nil)
        }

        
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
                NSLog("サービス: \(service)")
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        let characteristics: NSArray = service.characteristics!
        
        NSLog("\(characteristics.count) 個のキャラクラリスティックを発見")
        
        for obj in characteristics {
            if let characteristic = obj as? CBCharacteristic {
                
                if characteristic.UUID.isEqual(CBUUID(string: "29B10001-E8F2-537E-4F6C-D104768A1214")) {
                    self.outputCharacteristic = characteristic
                    NSLog("対象のキャラクラリスティックを発見")
                    
                    self.valueLabel.hidden = false
                    self.readButton.hidden = false
                    self.scanButton.enabled = true
                    self.scanButton.hidden = true
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        NSLog("読み出し成功 service UUID: \(characteristic.service.UUID), characteristic UUID: \(characteristic.UUID), value: \(characteristic.value)")
        
        var out: NSInteger = 0
        characteristic.value!.getBytes(&out, length: sizeof(NSInteger))

        self.valueLabel.text = "\(out)"
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://alcendpoint.herokuapp.com/sensors")!)
        request.HTTPMethod = "POST"
        let postString = "sensor[client_id]=101-CCEE&sensor[value]=\(out)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {                                                          // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("responseString = \(responseString)")
        }
        task.resume()
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            NSLog("状態更新失敗 \(error)")
        } else {
            NSLog("状態更新成功 \(characteristic.isNotifying)")
        }
    }
}

