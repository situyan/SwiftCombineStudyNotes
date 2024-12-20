//
//  SubscribeOnReceiveOn.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/10.
//

import UIKit
import Combine

class SubscribeOnReceiveOn: NSObject {
    var cancellable: Set<AnyCancellable> = []
    
    func test1_default() {
        print("---------------------------")
        /**
         "receive: is main thread, true"
         Map1: is main thread, true
         Sink1: is main thread, true
         */
        Publishers.MyPublisher()
            .map { _ in
                print("Map1: is main thread, \(Thread.isMainThread)")
            }
            .sink { _ in
                print("Sink1: is main thread, \(Thread.isMainThread)")
            }
            .store(in: &cancellable)
    }
    
    func test2_subscribeon() {
        print("---------------------------")
        /**
         "receive: is main thread, false"
         Map2: is main thread, false
         Sink2: is main thread, false
         */
        Publishers.MyPublisher()
            .map { _ in
                print("Map2: is main thread, \(Thread.isMainThread)")
            }
            .subscribe(on: DispatchQueue.global())
            .sink { _ in
                print("Sink2: is main thread, \(Thread.isMainThread)")
            }
            .store(in: &cancellable)
    }
    
    func test3_receiveon() {
        print("---------------------------")
        /**
         "receive: is main thread, false"
         Map3: is main thread, false
         Sink3: is main thread, true
         */
        Publishers.MyPublisher()
            .map { _ in
                print("Map3: is main thread, \(Thread.isMainThread)")
            }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("Sink3: is main thread, \(Thread.isMainThread)")
            }
            .store(in: &cancellable)
    }
}

extension Publishers {
    struct MyPublisher: Publisher {
        typealias Output = Int
        typealias Failure = Never
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Int == S.Input {
            debugPrint("receive: is main thread, \(Thread.isMainThread)")
            subscriber.receive(subscription: Subscriptions.empty)
            _ = subscriber.receive(12345)
        }
    }
}
