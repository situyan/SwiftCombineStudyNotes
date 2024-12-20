//
//  SUViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/10.
//

import UIKit
import SwiftUI

enum SUViewControllerType: Int {
    case CombineLatestAndZip = 1
    case PassthroughCurrentValue = 2
    case DebounceThrottle = 3
    case DataTaskPublisher = 4
    case CommonOperator = 5
    case CommonPublisher = 6
}

class SUViewController: UIViewController {
    var type: SUViewControllerType = .CombineLatestAndZip

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var swiftUIVC: UIViewController? = nil
        switch type {
        case .CombineLatestAndZip:
            swiftUIVC = UIHostingController(rootView: CombineLatestAndZipView())
        case .PassthroughCurrentValue:
            swiftUIVC = UIHostingController(rootView: PassthroughAndCurrentValueView())
        case .DebounceThrottle:
            swiftUIVC = UIHostingController(rootView: DebounceThrottleView())
        case .DataTaskPublisher:
            swiftUIVC = UIHostingController(rootView: URLSessionView())
        case .CommonOperator:
            swiftUIVC = UIHostingController(rootView: CommonOperatorsView())
        case .CommonPublisher:
            swiftUIVC = UIHostingController(rootView: CommonPublisherView())
        }
        
        guard let theVC = swiftUIVC else { return; }
        theVC.view.frame = self.view.bounds
        self.addChild(theVC)
        self.view.addSubview(theVC.view)
        // 通知系统层级变化
        theVC.didMove(toParent: self)
    }
}
