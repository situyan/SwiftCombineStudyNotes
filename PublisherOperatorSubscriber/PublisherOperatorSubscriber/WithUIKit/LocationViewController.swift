//
//  LocationViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/6.
//

import UIKit
import Combine
import CoreLocation

class LocationViewController: UIViewController {
    var headingSubscriber: AnyCancellable?
    let proxy = LocationHeadingProxy()
    let headingBgQueue: DispatchQueue = .init(label: "com.xxxcombine.bgqueue")
    var cancellable: Set<AnyCancellable> = []
    
    @IBOutlet var permissionButton: UIButton!
    @IBOutlet var activateTrackingSwitch: UISwitch!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var locationPermissionLabel: UILabel!
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updatePermissionStatus()
        
        // let corelocationsub = proxy.publisher.print().receive(on:)
        proxy.publisher
            .print("heading subscriber")
            .receive(on: RunLoop.main)
            .sink { completion in
                print("completion: \(completion)")
            } receiveValue: { [weak self] someValue in
                self?.headingLabel.text = String(describing: someValue.trueHeading)
            }
            .store(in: &cancellable)
//        headingSubscriber = corelocationsub
    }
    
    deinit {
        print("销毁 Location ViewController")
    }
    
    func updatePermissionStatus() {
        let x = CLLocationManager.authorizationStatus()
        switch x {
        case .notDetermined:
            locationPermissionLabel.text = "notDetermined"
        case .restricted:
            locationPermissionLabel.text = "restricted"
        case .denied:
            locationPermissionLabel.text = "denied"
        case .authorizedAlways:
            locationPermissionLabel.text = "authorizedAlways"
        case .authorizedWhenInUse:
            locationPermissionLabel.text = "authorizedWhenInUse"
        case .authorized:
            locationPermissionLabel.text = "authorized"
        @unknown default:
            locationPermissionLabel.text = "unknown"
        }
    }
    
    //MARK: - 请求定位权限
    @IBAction func requestPermission(_ sender: UIButton) {
        print("requesting corelocation permission")
        
        Future<Int, Never> { [weak self] promis in
            self?.proxy.mgr.requestWhenInUseAuthorization()
            return promis(.success(1))
        }
        .delay(for: 2.0, scheduler: headingBgQueue)
        .receive(on: RunLoop.main)
        .sink(receiveValue: { [weak self] _ in
            print("updating corelocation permission label")
            self?.updatePermissionStatus()
        })
        .store(in: &cancellable)
    }
    
    //MARK: 开始/停止定位
    @IBAction func trackingToggled(_ sender: UISwitch) {
        switch sender.isOn {
        case true:
            proxy.enable()
            print("Enabling heading tracking")
        case false:
            proxy.disable()
            print("Disabling heading tracking")
        }
    }
}
