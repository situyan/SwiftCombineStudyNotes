//
//  JustPublisherObject.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/10.
//
/**
 Publisher都是可以连续发送数据的，Subscriber也可以一直接收数据，除非收到了finished或者error而结束。
 而JUST Publisher则不同，它只向每个订阅者发送一次输出，然后结束。
 
 Just Publisher给任何一个Subscriber发送数据都只发送一次，然后就调用Completion。
 */

import UIKit
import Combine

class JustPublisherObject: NSObject {
    static func sendMessage() {
        let justPublisher = Just("This is a Just publisher")
        
        /**
         打印结果：
         --- Received value: This is a Just publisher
         --- Received completion: finished
         --- 2 Received value: This is a Just publisher
         --- 2 Received completion: finished
         
         这里有一个误区，以为 --- 2 不会打印（Just 发送数据只发送一次，发送完就会结束数据流）
         但实际打印了，因为整个管道虽然只有一个publisher，但却有两个subscriber，所以publisher发送的数据，subscriber都会收到。
         两次订阅的sink方法的回调都被调用了，而且每个Subscriber都只接收到一次数据，然后就调用Completion闭包了。
         */
        _ = justPublisher
            .sink(receiveCompletion: { completion in
                print("--- Received completion: \(completion)")
            }, receiveValue: { value in
                print("--- Received value: \(value)")
            })
        
        _ = justPublisher
            .sink(receiveCompletion: { completion in
                print("--- 2 Received completion: \(completion)")
            }, receiveValue: { value in
                print("--- 2 Received value: \(value)")
            })
    }
}
