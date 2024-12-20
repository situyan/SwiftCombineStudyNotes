//
//  PassthroughAndCurrentValue.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/10.
//

/**
 https://blog.csdn.net/guoyongming925/article/details/139727027
 
 发布者对象 Subjects：
 Subjects对象是发布者的一种特殊情况（Subject协议 继承了 Publisher协议）。该协议要求实现 send(_:) ，来允许开发者向订阅者发送特定的值。 对象可以通过 send方法 ，来“注入”一个值到数据流中。
 
 Subject： 本身也是一个 Publisher，有两种类型PassthroughSubject，CurrentValueSubject（Combine 内置）
 可以发送三种类型数据：output 值、failure 事件/ finished 事件、subscription。
 public protocol Subject<Output, Failure> : AnyObject, Publisher {
     func send(_ value: Self.Output)
     func send(completion: Subscribers.Completion<Self.Failure>)
     func send(subscription: any Subscription)
 }
 
 Subject可以一直发送数据，如果发送finished, failure/error，Subject生命周期就会结束，只能重新创建再发送数据
 【Subject是有生命周期的，当发送了completion后（不管是finished还是error），Subject都不会再发送任何新值。】
 当使用PassthroughSubject或CurrentValueSubject时，重要的是要考虑生命周期，并在明显没有任何值发送时关闭Subject。
 
 ----------------------------------------
 ----------------------------------------
 ----------------------------------------
 PassthroughSubject与CurrentValueSubject区别：
 首先这两个都是Subject的具体实现，都可以根据需要异步地无限地发出事件。这两个Subject的用法都比较简单，都作为Publisher发布数据，不过却还是有区别的。
 PassthroughSubject没有初始值，也不需要持有最近一次发布的值。
 CurrentValueSubject可以为Publisher提供初始值，并通过更新 value属性自动发出事件（.value = xxx）。

 网上有一个较为恰当的比喻：
 PassthroughSubject就像一个门铃按钮。当有人按门铃时(.send)，只有当你在家时才会通知你(.sink())。
 CurrentValueSubject就像一个电灯开关。当你不在的时候灯是开着的(初始值)，当你回家的时候你仍然会注意到它是开着的。
 */

import UIKit
import Combine

class PasstthroughAndCurrentValueSubject: ObservableObject {
    let publisher1 = PassthroughSubject<Int, Error>()
    let publisher2 = CurrentValueSubject<Int, Error>(1)
    var cancellable: Set<AnyCancellable> = []
    
    //MARK: - PassthroughSubject
    /**
     PassthroughSubject是Combine框架中的一种Subject具体类型，它不持有任何值，将自己接收到的任何值简单的传递给下游的Subscriber。

     当我们要创建一个PassthroughSubject时，需要指定要发送的值的类型，然后使用send方法发送，任何的Subscriber都会收到这个值。因为它本身不持有值，所以如果下游没有Subscriber，那么这个值将废弃了。
     */
    func passthroughSubjectFunc() {
        publisher1.send(1)
        
        /**
         打印结果：
         --- pt value is 2
         --- pt finished
         在添加sink方法之前发送的send("1")没有任何输出，因为发送的时候还没有任何订阅者，发送的值就直接抛弃了。
         */
        publisher1
            .sink { completion in
                switch completion {
                case .finished:
                    print("--- pt finished")
                case .failure(let error):
                    print("--- pt error ", error)
                }
            } receiveValue: { value in
                print("--- pt value is \(value)")
            }
            .store(in: &cancellable)

        publisher1.send(2)
        // publisher1.send(completion: .finished) //先注释，因为放在此处会结束publisher1的生命周期，后面send都会无效
    }
    
    func sendMessage1() {
        publisher1.send(Int.random(in: 3..<100))
    }
    
    func sendError1() {
        publisher1.send(completion: .failure(NSError(domain: "com.xxcombine.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid network"])))
    }
    
    func sendCompletion1() {
        publisher1.send(completion: .finished)
    }
    
    //MARK: - CurrentValueSubject
    /**
     Currentvaluessubject是Combine框架中的一种Subject具体类型。它可以保存单个值（不只初始化，最新值）， 并在设置新值时向任何订阅者发布新值（set赋值/send）。
     Currentvaluessubject在初始化的时候需要设置一个初始值。
     */
    func currentValueSubjectFunc() {
        /**
         打印结果：
         --- cv value is 1
         因为Currentvaluessubject在初始化的时候设置了一个初始值。当有订阅者订阅的时候会立即发送这个值
         completion的finished、failure只会触发其一！！！不会出现先failure再finished的情况
         */
        publisher2
            .sink { completion in
                switch completion {
                case .finished:
                    print("--- cv finished")
                case .failure(let error):
                    print("--- cv error ", error)
                }
            } receiveValue: { value in
                print("--- cv value is \(value)")
            }
            .store(in: &cancellable)
    }
    
    func sendMessage2() {
        // 在发送数据的时候，可以通过send方法，也可以通过直接设置value的方法，效果都是一样的。
        /**
         打印结果
         --- cv value is 4
         --- cv value is 5
         */
        publisher2.send(Int.random(in: 4..<100))
        publisher2.value = Int.random(in: 5..<100)
    }
    
    /**
     发送failure 或 finished之后，Subject的生命周期结束，后面的发送数据不再生效（比如sendMessage2()）
     当使用PassthroughSubject或CurrentValueSubject时，重要的是要考虑生命周期，且在明显没有任何值发送时关闭Subject。
     */
    func sendError2() {
        publisher2.send(completion: .failure(NSError(domain: "com.xxcombine.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid network"])))
    }
    
    func sendCompletion2() {
        publisher2.send(completion: .finished)
    }
}
