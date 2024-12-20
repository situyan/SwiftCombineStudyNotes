//
//  CustomPublisherSubscriber.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/11.
//

/**
 ⚠️⚠️⚠️在实际开发过程中，不建议我们自己去实现Publisher，Subscriber和Subscription，因为一个逻辑错误可能会破坏发布者和订阅者之间的所有连接，这可能会导致意想不到的结果。
 本文件的内容作为理解Combine发布--订阅流程的参考，也很重要！！！
 
 上游流程的理解：
 https://blog.csdn.net/guoyongming925/article/details/139939864
 http://chenru.cn/16561664137193.html
 https://www.cnblogs.com/jerrywossion/p/18168777（看这个先看上面两个链接内容， 然后再看这个）

 如果不好理解看看这个：Apple 官方异步编程框架Swift Combine 简介
 publisher中的 receive()方法可理解为 发布者收到订阅者或其消息，
 subscriber中的receive()方法可理解为 订阅者收到发布者或其消息
 如果不理解，再看“疑问和待处理”中的第5点
 
 因为Subscription是起了一个桥梁的作用，属于幕后，所以下面的第5，6步骤从语义上来说相当于Publisher通过receive(_:) 方法或receive(completion:) 方法向Subscriber 发送数据或者结束信息。实际上Subscription 替Publisher 做了向下游发送数据的事情。
 当然也可根据实际情况由Publisher自己处理
 当一个 Subscriber 订阅到一个 Publisher 上时，会接收到一个新生成的由协议 Subscription 表示的类型对象（func receive(subscription: any Subscription) {}），Subscriber 通过该对象来向 Publisher 请求值，而 Publisher 也只有在接收到 Subscriber 的显式请求时才会分发值。
 
 以下或可作为参考：
 订阅者Subscriber：接收发布者发送的值、错误和完成信息，并进行相应的处理。
 订阅者用两种相关类型进行描述：Input 和 Failure 。订阅者发起数据请求，并控制接收到的数据量。在 Combine 中，他可以看作是“行为的驱动者”，没有了订阅者，其他的组成部分将闲置。
 
 请求驱动：
 请求驱动(Request Driven)：基于请求和响应的设计思想，消费者向生产者请求某个事务的变化，当变化时生产者给消费者对应的响应。
 事件驱动(Event Driven)：基于事件通知的设计思想。 在事务发生变化时，生产者将通知提交给事件管道进行分发，而不关心谁去消费事件。 消费者需要到事件管道中订阅关心的通知。
 */

import Combine

/**
 Subscription是一个协议，实现该协议的对象负责将订阅者链接到发布者。只要它在内存中，订阅者就会继续接收值。
 订阅消息(Subsciption):描述如何控制发布者到订阅者的数据流动，用于表达发布者和订阅者之间的连接。
 
 该协议中规定了要实现request方法，因为继承了Cancellable，所以还需要实现一个cancel方法。
 同Subscriber一样，自定义的Subscription需要使用class定义，而非struct，否则会报错，另外创建的Subscription实例对象需要在内存中保持，否则订阅就失效了
 */
// 自定义Subscription
class CustomSubscription<S: Subscriber>: Subscription where S.Input == Int, S.Failure == Never {
    // 持有传入进来的Subscriber对象。
    private var subscriber: S
    private var counter = 0
    private var isCompleted = false
    
    /**
     初始化的时候将Subscriber对象传入进来，并持有，待后续发送数据使用。
     在Publisher协议的receive<S>(subscriber: S)方法中初始化 Subscription
     */
    init(subscriber: S) {
        self.subscriber = subscriber
    }
    
    /**4，5，6
     在Subscription的request方法中，知道了Subscriber的请求次数，经过相关的逻辑处理后，在此方法中给Subscriber发送数据。
     通过Subscriber的receive(_:)方法向Subscriber发送数据。
     通过Subscriber的receive(completion:)方法向Subscriber发送结束或者失败信息。
     
     该方法传入请求数据的次数，并给Subscriber发送数据。
     */
    /// Tells a publisher that it may send more values to the subscriber.
    func request(_ demand: Subscribers.Demand) {
        debugPrint("CustomSubscription request")
        guard !isCompleted else { return }
        
        for _ in 0..<(demand.max ?? 0) {
            _ = subscriber.receive(counter) // 给Subscriber发送数据
            counter += 1
        }
        
        if counter >= 5 {
            subscriber.receive(completion: .finished) // 通知Subscriber结束。
            isCompleted = true
        }
    }
    
    // 该方法中执行一些取消订阅的操作。(因为继承了Cancellable，所以还需要实现一个cancel方法。)
    func cancel() {
        isCompleted = true
    }
}

// 自定义Publisher
class CustomPublisher: Publisher {
    // 确定输出类型，需要和Subscriber的输入类型一致。
    typealias Output = Int
    // 确定失败类型，需要和Subscriber的失败类型一致，永远不会失败就定义为Never。
    typealias Failure = Never
    
    /**2 在第一步调用subscribe(_:)  方法后 即触发Publisher内部调用receive(subscriber:)  方法，在该方法中创建一个连接Publisher和Subscriber的Subscription对象， 然后调用Subscriber的receive(subscription:)方法，将Subscription对象传给Subscriber
        
     接收subscriber对象的方法。方法传入Subscriber实例对象，开始建立联系。 方法内创建Subscription对象，然后调用Subscriber的receive(subscription:)方法，将Subscription对象传给Subscriber。
     
     实现这个方法，将它调用 `subscribe(_:)` 方法传入的订阅者附加到发布者上
     接收subscriber对象的方法。方法传入Subscriber实例对象，开始建立联系。
     方法内创建Subscription对象，然后调用Subscriber的receive(subscription:)方法，将Subscription对象传给Subscriber。
     */
    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Int == S.Input {
        // 创建Subscription对象
        let subscription = CustomSubscription(subscriber: subscriber)
        debugPrint("CustomPublisher subscriber.receive")
        // 将Subscription对象传给Subscriber
        subscriber.receive(subscription: subscription)
    }
}
//extension Publisher {
//    /// 将订阅者附加到发布者上，供外部调用，不直接使用 `receive(_:)` 方法
//    public func subscribe<S>(_ subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
//}

/**
 自定义Subscriber
 协议中有两个类型，三个方法。自定义的Subscriber需要使用class定义，而非struct，否则会报错，另外struct是值类型，Subscription没有持有最初的那个Subscriber对象。
 */
class CustomSubscriber: Subscriber {
    // 确定输入类型，需要和Publisher的输出类型一致。
    typealias Input = Int
    // 确定失败类型，需要和Publisher的失败类型一致，永远不会失败就定义为Never。
    typealias Failure = Never
    
    /**3 在Subscriber的receive(subscription:) 方法中，使用传进来的subscription 对象调用request方法，并设置Subscriber的请求次数。
     接收subscription对象的方法。方法内subscription对象调用request方法，设置请求次数。
     
     告诉订阅者，它在发布者上被成功订阅，可以请求值了
     订阅消息(Subsciption):描述如何控制发布者到订阅者的数据流动，用于表达发布者和订阅者之间的连接。
     */
    func receive(subscription: any Subscription) {
        debugPrint("CustomSubscriber subscription.request")
        subscription.request(.max(5))
    }
    
    /**5
     接收Publisher发送数据的方法。该方法返回`Subscribers.Demand`，(建议不看：用于在request方法中计算请求次数。)
     
     告诉订阅者，发布者产生值了
     */
    func receive(_ input: Int) -> Subscribers.Demand {
        debugPrint("New value \(input)")
        // 这里表示收到订阅的值后，是否还有请求更多值
        // 如果receive(subscription)中设置的是.ulimit，此处只能是.none，不可更改
        return .none // 不请求更多数据
    }
    
    /**6
     接收Publisher发送结束的方法，或者正常结束，或者失败。
     
     告诉订阅者，发布者已经终止产生值了，不管是正常情况还是由于错误情况
     */
    func receive(completion: Subscribers.Completion<Never>) {
        debugPrint("Completion: \(completion)")
    }
}

class CustomCombineObject: ObservableObject {
    var subscription: AnyCancellable?
    
    func testMethod1() {
        // 创建自定义的Publisher
        let publisher = CustomPublisher()
        // 创建自定义的Subscriber
        let subscriber = CustomSubscriber()
        
        debugPrint("Begin subscribe")
        
        /**1 由Publisher调用subscribe(_:) 方法开启链接申请，同时参数传入Subscriber实例对象。
         申请订阅。 由Publisher对象调用subscribe方法，传入Subscriber对象开始。
         Subscriber is attached to Publisher
         */
        publisher.subscribe(subscriber)
        
        /**
         打印结果：
         "Begin subscribe"
         "CustomPublisher subscriber.receive"
         "CustomSubscriber subscription.request"
         "CustomSubscription request"
         New value 0
         New value 1
         New value 2
         New value 3
         New value 4
         Completion: finished
         */
    }
    
    func testMethod2() {
        // 创建自定义的Publisher
        let publisher = CustomPublisher()
        // 系统定义的Subscriber sink
        // 通过sink方法申请订阅，并将创建的subscription持有，否则订阅失败， sink方法返回的是AnyCancellable，这里做了类型抹除。
        subscription = publisher
            .sink { completion in
                print("sink completion: \(completion)")
            } receiveValue: { value in
                print("sink new value \(value)")
            }
        
        /**
         实际打印结果（可能哪里用错了，或者博客里的打印不对）：
         "CustomPublisher subscriber.receive"
         "CustomSubscription request"
         
         博客打印结果（sink请求的是无限次数数据 .unlimited，不同于自定义的Subscriber .max(5)：
         "CustomPublisher subscriber.receive"
         "CustomSubscription request"
         sink new value 0
         sink new value 1
         sink new value 2
         sink new value 3
         sink new value 4
         sink new value 5
         sink new value 6
         sink new value 7
         sink new value 8
         sink new value 9
         sink completion: finished
         */
    }
}
