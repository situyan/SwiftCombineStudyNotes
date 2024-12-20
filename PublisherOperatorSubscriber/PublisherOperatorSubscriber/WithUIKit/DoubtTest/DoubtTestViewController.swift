//
//  DoubtTestViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/9.
//  疑问解释与测试

import UIKit

class DoubtTestViewController: UIViewController {
    let subscribeReceiveOn = SubscribeOnReceiveOn()
    var customCombine = CustomCombineObject()
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    @IBAction func subscribeOnReceiveOnAction(_ sender: UIButton) {
        subscribeReceiveOn.test1_default()
        subscribeReceiveOn.test2_subscribeon()
        subscribeReceiveOn.test3_receiveon()
    }
    
    @IBAction func justPublisherAction(_ sender: UIButton) {
        JustPublisherObject.sendMessage()
    }
    
    @IBAction func passthroughAndCurrentValue(_ sender: UIButton) {
        let theVC = SUViewController()
        theVC.type = .PassthroughCurrentValue
        self.navigationController?.pushViewController(theVC, animated: true)
    }
    
    @IBAction func debounceThrottle(_ sender: UIButton) {
        let theVC = SUViewController()
        theVC.type = .DebounceThrottle
        self.navigationController?.pushViewController(theVC, animated: true)
    }
    
    @IBAction func dataTaskPublisher(_ sender: UIButton) {
        let theVC = SUViewController()
        theVC.type = .DataTaskPublisher
        self.navigationController?.pushViewController(theVC, animated: true)
    }
    
    @IBAction func commonPublisher(_ sender: UIButton) {
        let theVC = SUViewController()
        theVC.type = .CommonPublisher
        self.navigationController?.pushViewController(theVC, animated: true)
    }
    
    @IBAction func commonOperator(_ sender: UIButton) {
        let theVC = SUViewController()
        theVC.type = .CommonOperator
        self.navigationController?.pushViewController(theVC, animated: true)
    }
    
    @IBAction func publisherSubscriber(_ sender: UIButton) {
        customCombine = CustomCombineObject()
        
//        customCombine.testMethod1()
        customCombine.testMethod2()
    }
}
