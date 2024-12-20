//
//  LocationHeadingProxy.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/6.
//

import UIKit
import CoreLocation
import Combine

class LocationHeadingProxy: NSObject, CLLocationManagerDelegate {
    let mgr: CLLocationManager
    private let headingPublisher: PassthroughSubject<CLHeading, Error>
    var publisher: AnyPublisher<CLHeading, Error>
    
    override init() {
        mgr = CLLocationManager()
        headingPublisher = PassthroughSubject<CLHeading, Error>()
        publisher = headingPublisher.eraseToAnyPublisher()
        
        super.init()
        mgr.delegate = self
    }
    
    func enable() {
        mgr.startUpdatingHeading()
    }
    
    func disable() {
        mgr.stopUpdatingHeading()
    }
    
    //MARK: - delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingPublisher.send(newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        headingPublisher.send(completion: Subscribers.Completion.failure(error))
    }
}
