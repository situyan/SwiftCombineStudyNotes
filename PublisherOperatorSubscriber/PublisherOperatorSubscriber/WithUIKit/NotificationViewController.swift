//
//  NotificationViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/6.
//

import UIKit
import Combine

extension Notification.Name {
    static let myExampleNotification = Notification.Name("an-example-notification")
}

class NotificationViewController: UIViewController {
    @IBOutlet weak var contentLabel: UILabel!
    
    var notifiSubscriber: AnyCancellable? = nil
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        /**
         ⚠️⚠️⚠️在发布者、操作符及订阅者的闭包中使用自定义变量时，需要 [weak self] 防止相互循环引用！！！
         因为发布者、订阅者被声明为变量被VC持有，闭包中使用自定义变量时，VC/self被发布者、订阅者持有，所以必须要 [weak self]，【实测结果】
         */
        // 创建一个能够订阅和接收通知的Publisher。
        notifiSubscriber = NotificationCenter.default.publisher(for: .myExampleNotification, object: nil)
            // 订阅通知
            .sink(receiveCompletion: { completion in
                print("completion: \(completion)")
            }, receiveValue: { [weak self] notifi in
                // 处理接收到的通知
                let content = "notifi: \(notifi.name),\n\(String(describing: notifi.userInfo))\n\(String(describing: notifi.object))"
                self?.contentLabel.text = content
                print(content)
            })
//            .sink(receiveCompletion: { completion in
//                print("completion: \(completion)")
//            }, receiveValue: { notifi in
//                let content = "notifi: \(notifi.name),\n\(String(describing: notifi.userInfo))\n\(String(describing: notifi.object))"
//                self.contentLabel.text = content
//                print(content)
//            })
    }
    
    deinit {
        print("销毁 Notification ViewController")
        // https://blog.csdn.net/guoyongming925/article/details/139862793
        //⚠️⚠️⚠️另外特别要强调的是AnyCancellable实例在 deinit 时（即销毁时）时自动调用cancel()。
        notifiSubscriber?.cancel()
        notifiSubscriber = nil
    }
    
    @IBAction func sendNotificationAction(_ sender: Any) {
        let dict = ["random": Int.random(in: 1...99)]
        let vc = POSManager() // UIViewController()
        // 发送通知消息
        NotificationCenter.default.post(name: .myExampleNotification, object: vc, userInfo: dict)
    }
}
