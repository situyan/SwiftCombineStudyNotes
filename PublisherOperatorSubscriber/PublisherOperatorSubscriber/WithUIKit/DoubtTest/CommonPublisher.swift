//
//  CommonPublisher.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/13.
//

import Foundation
import Combine
import UIKit

class CommonPublisher: ObservableObject {
    private var cancellable: Set<AnyCancellable> = []
    var timerCancellable: AnyCancellable? = nil
    var timer1Cancellable: AnyCancellable? = nil
    private var connection: Cancellable?
    
    @Published var date = Date()
    
    deinit {
        print("销毁 CommonPublisher -- cancellable")
        cancellable.removeAll()
        connection?.cancel()
    }
    
    /**
     在SwiftUI中，可以使用Timer.publish来创建一个Publisher，该Publisher会在指定的时间间隔内发布事件。例如：
     创建了一个每秒发布一次事件的Publisher。通过.autoconnect()方法，确保Publisher在订阅时立即开始发布事件。
     ⚠️⚠️⚠️注意：在Timer.publisher闭包中引用类实例变量， 需要引入[weak self] 防止循环引用导致定时器无法正常销毁
     */
    func timerFunc() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .print("timer publisher")
            .sink { value in
                print("timer sink value \(value)")
            }
        
        /**
         打印结果 + timerStop：
         timer publisher: receive subscription: ((extension in Foundation):__C.NSTimer.TimerPublisher.Inner<Combine.Publishers.Autoconnect<(extension in Foundation):__C.NSTimer.TimerPublisher>.(unknown context at $1a99436a8).Inner<Combine.Publishers.Print<Combine.Publishers.Autoconnect<(extension in Foundation):__C.NSTimer.TimerPublisher>>.(unknown context at $1a9943820).Inner<Combine.Subscribers.Sink<Foundation.Date, Swift.Never>>>>)
         timer publisher: request unlimited
         timer publisher: receive value: (2024-12-13 10:32:52 +0000)
         timer sink value 2024-12-13 10:32:52 +0000
         timer publisher: receive value: (2024-12-13 10:32:53 +0000)
         timer sink value 2024-12-13 10:32:53 +0000
         timer publisher: receive value: (2024-12-13 10:32:54 +0000)
         timer sink value 2024-12-13 10:32:54 +0000
         timer publisher: receive value: (2024-12-13 10:32:55 +0000)
         timer sink value 2024-12-13 10:32:55 +0000
         timer publisher: receive value: (2024-12-13 10:32:56 +0000)
         timer sink value 2024-12-13 10:32:56 +0000
         timer publisher: receive value: (2024-12-13 10:32:57 +0000)
         timer sink value 2024-12-13 10:32:57 +0000
         timer publisher: receive cancel
         */
        
        timer1Cancellable = Timer.publish(every: 1.0, on: .current, in: .common)
            .autoconnect()
            .receive(on: RunLoop.main)
            .assign(to: \.date, on: self)
    }
        
    func timerStop() {
        timerCancellable?.cancel()
        timer1Cancellable?.cancel()
        
        // ⚠️注意：并没有disconnect()方法
//        let timerPublisher = Timer.publish(every: 1.0, on: .current, in: .common)
//        timerPublisher.disconnect()
    }
    
    func notificationFunc() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification, object: nil)
            .sink { value in
                print("Notification sink value \(value)")
            }
            .store(in: &cancellable)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification, object: nil)
            .sink { value in
                print("Notification sink value \(value)")
            }
            .store(in: &cancellable)
        
        /**
         Notification sink value name = UIApplicationDidEnterBackgroundNotification, object = Optional(<UIApplication: 0x1015daa40>), userInfo = nil
         Notification sink value name = UIApplicationWillEnterForegroundNotification, object = Optional(<UIApplication: 0x1015daa40>), userInfo = nil
         */
    }
    
    /**
     将数组或集合等序列转换为发布者，顺序发布每个元素。
     */
    func sequenceFunc() {
        let sequencePublisher = Publishers.Sequence<[Int], Never>(sequence: [1,2,3,4,5])
        sequencePublisher
            .sink { value in
                print("Sequence sink value \(value)")
            }
            .store(in: &cancellable)
    }
    
    func failedFunc() {
        let failPublisher = Fail<String, Error>(error: NSError(domain: "test error", code: -1, userInfo: nil))
        failPublisher
            .sink { completion in
                switch completion {
                case .finished:
                    print("Fail sink completion")
                case .failure(let error):
                    print("Fail sink fail, ", error)
                }
            } receiveValue: { value in
                print("Fail sink value \(value)")
            }
            .store(in: &cancellable)
    }
    
    func emptyFunc() {
        Empty<Any, Error>()
            .print("empty publisher")
            .sink { completion in
                switch completion {
                case .finished:
                    print("Empty sink completion")
                case .failure(let error):
                    print("Empty sink fail, ", error)
                }
            } receiveValue: { value in
                print("Empty sink value \(value)")
            }
            .store(in: &cancellable)
        
        /**
         打印结果：
         empty publisher: receive subscription: (Empty)
         empty publisher: request unlimited
         empty publisher: receive finished
         Empty sink completion
         */
    }
    
    /**
     share()在本示例中的作用：1、只请求一次网络，防止资源浪费
     share operator 目的是让我们通过引用而不是通过值来获取 Publisher。 Publisher 通常是结构体：当我们将 Publisher 传递给函数或将其存储在多个属性中时，Swift 会多次复制它。当我们订阅每个副本时，Publisher 只能做一件事：重复开始其工作并交付值。
     .share() 返回 Publishers.Share 类的实例。通常，Publisher 被实现为结构，但在 share() 的情况下，【 Operator 获取对 Publisher 的引用而不是使用值语义】，这允许它共享底层 Publisher。
     
     特点：如果 Subscriber 在上游Publisher 完成后才去订阅，则该新 Subscriber 只会收到完成事件。 因为subscriber共享同一个Publisher，publisher在第一个subscriber订阅后就会发出值，后续的subscriber再订阅，
     publisher 不会重新/重置/重复流程；
     另一方面，杜绝了publisher的重复工作（比如多次重复的网络请求）。
     至于如何确保多个subscriber都能订阅到完整的值，可通过 makeConnectable(), multicast(subject:) 来控制
     
     适用场景
     ‌‌共享资源‌：当多个订阅者需要访问同一数据源时，使用share()可以避免重复订阅和资源消耗。
     ‌‌性能优化‌：在处理大量订阅者时，使用share()可以减少计算和资源的使用，提高应用性能。
     ‌‌状态管理‌：在状态管理场景中，使用share()可以确保多个视图或组件共享同一状态，避免不必要的状态更新和冲突。
    
     共享网络请求、图像处理和文件解码等资源，而不是进行重复的工作。换句话说，在多个订阅者之间共享单个资源的结果—— Publisher 发出的值，而【不是复制该结果】（重复操作）。
     */
    func shareFunc1() {
        let url = URL(string: "https://www.cnblogs.com/ficow")!
        let shared = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .print("shared")
            .share()
        
        print("subscribing 1")
        shared
            .sink { _ in
                print("subscription1 sink completion")
            } receiveValue: { value in
                print("subscription1 sink received: \(value)")
            }
            .store(in: &cancellable)
        
        print("subscribing 2")
        shared
            .sink { _ in
                print("subscription2 sink completion")
            } receiveValue: { value in
                print("subscription2 sink received: \(value)")
            }
            .store(in: &cancellable)
        
        /**
         两次打印结果的区别：
         不注释.share() publisher只被订阅一次，两个subscriber共享同一个publisher；
         注释.share() publisher被订阅两次，两个subscriber各自连接一个publisher；
         
         打印结果：
         subscribing 1
         shared: receive subscription: (DataTaskPublisher)
         shared: request unlimited
         subscribing 2
         shared: receive value: (71903 bytes)
         subscription1 sink received: 71903 bytes
         subscription2 sink received: 71903 bytes
         shared: receive finished
         subscription1 sink completion
         subscription2 sink completion
         
         第一个 Subscription 触发对 DataTaskPublisher 的订阅。第二个 Subscription 没有任何改变：Publisher 继续运行，没有第二个请求发出。当请求完成时，Publisher 将结果数据发送给两个 Subscriber，然后完成。
         
         
         注释掉 .share()，打印结果：
         subscribing 1
         shared: receive subscription: (DataTaskPublisher)
         shared: request unlimited
         subscribing 2
         shared: receive subscription: (DataTaskPublisher)
         shared: request unlimited
         shared: receive value: (71903 bytes)
         subscription2 sink received: 71903 bytes
         shared: receive finished
         subscription2 sink completion
         shared: receive value: (71903 bytes)
         subscription1 sink received: 71903 bytes
         shared: receive finished
         subscription1 sink completion
         
         当注释掉 share()后， DataTaskPublisher 不共享，它收到了两个 Subscription！ 在这种情况下，请求会运行两次。
         */
    }
    
    func shareFunc2() {
        let url = URL(string: "https://www.cnblogs.com/ficow")!
        let shared = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .print("shared")
            .share()
        
        print("subscribing 1")
        shared
            .sink { _ in
                print("subscription1 sink completion")
            } receiveValue: { value in
                print("subscription1 sink received: \(value)")
            }
            .store(in: &cancellable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("subscribing 2")
            shared
                .sink { _ in
                    print("subscription2 sink completion")
                } receiveValue: { value in
                    print("subscription2 sink received: \(value)")
                }
                .store(in: &self.cancellable)
        }
        
        /**
         打印结果：
         subscribing 1
         shared: receive subscription: (DataTaskPublisher)
         shared: request unlimited
         shared: receive value: (71903 bytes)
         subscription1 sink received: 71903 bytes
         shared: receive finished
         subscription1 sink completion
         subscribing 2
         subscription2 sink completion
         
         在创建 subscription2 时，请求已经完成并且结果数据已经发出，因为两个subscriber共享同一个publisher，所以
         subscriber2订阅时，不会再次请求，管道中还剩余什么数据就接收什么数据
         */
    }
    
    /**
     ConnectablePublisher 是一个协议类型，它可以在你准备好之前阻止发布者发布元素。
     在你显式地调用 connect() 方法之前，一个 ConnectablePublisher 不会发送任何元素。
     makeConnectable()：Creates a connectable wrapper around the publisher.
     makeConnectable()在本示例中的作用：确保多个订阅者能同时收到发布的数据
     
     使用 Connectable Publisher， 你可以决定发布者何时开始发送订阅元素给订阅者。那么，为什么我们需要这么做？

     使用 sink(receiveValue:)  可以立刻开始接收订阅元素， 但是这可能不是你想要的结果。 使用 .share() 多个订阅者订阅了同一个发布者，有可能会出现其中一个订阅者收到订阅内容，而另外一个订阅者收不到的情况。
     比如，当你发起一个网络请求，并为这个请求创建了一个发布者以及连接了这个发布者的订阅者。然后，这个订阅者的订阅操作触发了实际的网络请求。在某个时间点，你将第二个订阅者连接到了这个发布者。如果在连接第二个订阅者之前，网络请求已经完成，那么第二个订阅者将只会收到完成事件，收不到网络请求的响应结果。这时候，这个结果将不是你所期望。（示例shareFunc2()）
     
     解决：在两个订阅者都连接到发布者之后，调用 connect()，然后网络请求才被触发。这样就可以避免竞争(race condition)，保证两个订阅者都收到数据。
     为了在你的 Combine 代码中使用 ConnectablePublisher，你可以【使用 makeConnectable() 操作符将当前的发布者包装到一个 Publishers.MakeConnectable 结构体实例中】。
     比如下面示例中的 connectable： Publishers.MakeConnectable<Publishers.Share<Publishers.Catch<Publishers.Map<URLSession.DataTaskPublisher, Data>, Just<Data>>>>
     
     ConnectablePublisher 提供了 autoconnect() 操作符。当一个订阅者通过 subscribe(_:) 方法连接到发布者时，connect() 方法会被马上调用。
     可参考 Timer.publish(...)     .multicast(subject:)
     */
    func makeConnectable() {
        let url = URL(string: "https://www.cnblogs.com/ficow")!
        let connectable = URLSession.shared.dataTaskPublisher(for: url)
            .map({ return $0.data })
            .print("makeConnectable ")
            .catch({ _ in Just(Data()) })
            .share()
            .makeConnectable() // 阻止发布者发布内容
            
        connectable
            .sink { completion in
                print("connectable received completion 1: \(completion)")
            } receiveValue: { value in
                print("connectable received data 1: \(value.count) bytes")
            }
            .store(in: &cancellable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            connectable
                .sink { completion in
                    print("connectable received completion 2: \(completion)")
                } receiveValue: { value in
                    print("connectable received data 2: \(value.count) bytes")
                }
                .store(in: &self.cancellable)
        }
        
        print("1，2订阅者都已连接发布者")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // 显示地启动发布，此时订阅者才可收到数据
            // 返回值需要被强引用，可用于取消发布（主动调用cancel() 或 返回值被析构/销毁）
            print("connectable connect 1，2同时订阅")
            self.connection = connectable.connect()
        }
        
        /**
         ⚠️⚠️⚠️ 两次打印结果中的 makeConnectable : receive subscription: (DataTaskPublisher) 顺序不同
         因为：Connectable Publisher 可以决定发布者何时开始发送订阅元素给订阅者，
         或者说 Connectable Publisher 控制发布者与订阅者之间的连接
         
         打印结果：
         1，2订阅者都已连接发布者
         connectable connect 1，2同时订阅
         makeConnectable : receive subscription: (DataTaskPublisher)
         makeConnectable : request unlimited
         makeConnectable : receive value: (71903 bytes)
         connectable received data 1: 71903 bytes
         connectable received data 2: 71903 bytes
         makeConnectable : receive finished
         connectable received completion 1: finished
         connectable received completion 2: finished
         
         
         打印结果（注释.makeConnectable() , connectable.connect()）：
         makeConnectable : receive subscription: (DataTaskPublisher)
         makeConnectable : request unlimited
         1，2订阅者都已连接发布者
         makeConnectable : receive value: (71903 bytes)
         connectable received data 1: 71903 bytes
         makeConnectable : receive finished
         connectable received completion 1: finished
         connectable received completion 2: finished
         connectable connect 1，2同时订阅
         */
    }
    
    /**
     .multicast(subject:) 具有share()功能，返回ConnectablePublisher
     我们使用了 multicast(_:)。此 Operator 基于 share() 构建，并使用我们选择的 Subject 将值发布给Subscriber。 multicast(_:) 的独特之处在于它返回的 Publisher 是一个 ConnectablePublisher。这意味着它不会订阅上游 Publisher，直到我们调用它的 connect() 方法。这让你有足够的时间来设置我们需要的所有 Subscriber，然后再让它连接到上游 Publisher 并开始工作。
     */
    func multicastFunc() {
        let subject = PassthroughSubject<Data, URLError>()
        let url = URL(string: "https://www.cnblogs.com/ficow")!
        let multicasted = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .print("multicast")
            .multicast(subject: subject)
        
        print("subscribing 1")
        multicasted
            .sink { completion in
                print("subscription1 sink completion")
            } receiveValue: { value in
                print("subscription1 sink received \(value)")
            }
            .store(in: &cancellable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("subscribing 2")
            multicasted
                .sink { completion in
                    print("subscription2 sink completion")
                } receiveValue: { value in
                    print("subscription2 sink received \(value)")
                }
                .store(in: &self.cancellable)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("connect")
            multicasted
                .connect()
                .store(in: &self.cancellable)
        }
        
        /**
         可对比shareFunc2()的打印结果看
         
         打印结果：
         subscribing 1
         subscribing 2
         connect
         multicast: receive subscription: (DataTaskPublisher)
         multicast: request unlimited
         multicast: receive value: (71903 bytes)
         subscription2 sink received 71903 bytes
         subscription1 sink received 71903 bytes
         multicast: receive finished
         subscription2 sink completion
         subscription1 sink completion
         */
    }
}
