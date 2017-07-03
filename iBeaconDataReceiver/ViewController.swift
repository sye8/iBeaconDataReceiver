//
//  ViewController.swift
//  iBeaconDataReceiver
//
//  Created by 叶思帆 on 12/06/2017.
//  Copyright © 2017 Sifan Ye. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var detailLabels: [UILabel]!
    @IBOutlet var proximityLabels: [UILabel]!
    @IBOutlet weak var locationLabel: UILabel!
    
    let locManager = CLLocationManager()
    let region = CLBeaconRegion(proximityUUID: UUID(uuidString: "FDA50693-A4E2-4FB1-AFCF-C6EB07647825")!, identifier: "FmxyBeacon") //Here: filter out those that doesn't have major == 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locManager.delegate = self
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedWhenInUse {
            locManager.requestWhenInUseAuthorization()
        }
        locManager.startRangingBeacons(in: region)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in inRegion: CLBeaconRegion) {
        
        //For display
        let endIndex = min(2, beacons.count-1)
        for index in 0...endIndex{
            let beacon = beacons[index]
            if beacon.proximity == CLProximity.unknown{
                detailLabels[index].text = "No Signal"
            }else{
                detailLabels[index].text = "Major: \(beacon.major)\nMinor: \(beacon.minor)\nRSSI: \(beacon.rssi)\nAccuracy:\(beacon.accuracy)\n"
            }
            switch beacon.proximity {
                case CLProximity.far:
                    proximityLabels[index].text = "Far"
                case CLProximity.near:
                    proximityLabels[index].text = "Near"
                case CLProximity.immediate:
                    proximityLabels[index].text = "Immediate"
                case CLProximity.unknown:
                    proximityLabels[index].text = "Unknown"
            }
        }
        if beacons.count == 0{
            self.locationLabel.text = "No Node found, cannot determine location"
        }else{
            //Send JSON
            var retDict: [[String:String]] = []
            for beacon in beacons{
                retDict.append(beaconToDict(beacon: beacon))
            }
            httpPostJSON(beacons: retDict)
        }
    }
    
    func httpPostJSON(beacons: [[String:String]]){
        var request = URLRequest(url: URL(string: "http://10.250.111.185:8080/Trilateration/Lookup")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if JSONSerialization.isValidJSONObject(beacons){
            do{
                let data = try JSONSerialization.data(withJSONObject: beacons, options: JSONSerialization.WritingOptions.prettyPrinted)
                request.httpBody = data
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                    if error != nil{
                        return
                    }
                    if let data = data, let string = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async() {
                            self.locationLabel.text = string
                        }
                    }
                }
                task.resume()
            }catch{
                print("Error")
            }
        }else{
            print("Invalid JSON Object")
        }
        
    }
    
    //For conversion to JSON
    func beaconToDict(beacon: CLBeacon) -> [String: String]{
        var retDict: [String: String] = [:]
        retDict["major"] = "\(beacon.major)"
        retDict["minor"] = "\(beacon.minor)"
        retDict["accuracy"] = "\(beacon.accuracy)"
        return retDict
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

