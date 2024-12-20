//
//  ViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/2.
//

/**
 https://blog.csdn.net/guoyongming925/article/details/139683548
 Publisher，Operator 和 Subscriber 三者组成了从 事件发布，变形，到订阅 的完整链条。在建立起事件流的响应链后，随着事件发生，app 的状态随之演变，这些是响应式编程处理异步程序的 Combine 框架的基础架构。
 
 ————————————————
 Publisher：
 最主要的工作其实有两个：发布新的事件及其数据，以及准备好被Subscriber订阅。
 Output 定义了某个 Publisher 所发布的值的类型，Failure 则定义可能产生的错误的类型。随着时间的推移，事件流也会逐渐向前发展。对应 Output 及 Failure，Publisher 可以发布三种事件：

 类型为 Output 的新值：这代表事件流中出现了新的值。
 类型为 Failure 的错误：这代表事件流中发生了问题，事件流到此终止。
 完成事件：表示事件流中所有的元素都已经发布结束，事件流到此终止。 (completion(.finished))
 ————————————————
 
 
 
 ————————————————
 Operator:
 Operator提供了一些方法，他们接收上有的元素进行操作，然后创建下游发布者或者订阅者。
 使用Operator组装一个Publisher链(可以以订阅者结束)，该Publisher链处理上游Publisher生成的元素。每个Operator创建并配置Publisher或Subscriber的实例，并将其订阅到调用该方法的Publisher上。
 比如：public func throttle<S>(for interval: S.SchedulerTimeType.Stride, scheduler: S, latest: Bool) -> Publishers.Throttle<Self, S> where S : Scheduler
 public func map<T>(_ keyPath: KeyPath<Self.Output, T>) -> Publishers.MapKeyPath<Self, T>
 ⚠️Operator闭包中也可创建新的Publisher（比如根据上游输入值，执行新的网络请求，再将响应结果发出去）
 ————————————————
 ————————————————
 ————————————————
 let cancellable = [1, 2, 3, 4, 5].publisher
     .filter {
         $0 % 2 == 0
     }
     .sink {
         print ("Even number: \($0)")
     }
 // Prints:
 // Even number: 2
 // Even number: 4
 一个数组Publisher发出整数1、2、3、4、5。filter操作符创建了一个Publisher，重新发布偶数值。sink操作符创建Subscriber，该Subscriber打印接收到的每个值。sink创建的Subscriber订阅filter创建的Publisher，filter创建的Publisher订阅了数组Publisher。
 额外补充：似乎Swift中对象实例都可 .publisher，比如
 [1, 2, 3, 4, 5].publisher,   repositoryCountLabel.publisher(for: \.text)
 可参阅 Foundation中常用的Publisher：https://www.jianshu.com/p/9adfe39aa36f
 
 以下这些可以
 Foundation
 URLSession.dataTaskPublisher
 KVO 实例中的 .publisher
 NotificationCenter
 Timer
 Result
 ————————————————
 ————————————————
 
 Subscribers.Sink是一个简单的订阅者，在订阅时请求无限数量的值。
 该方法可以同时提供两个闭包也可以一个，receiveCompletion用来接收 failure 或者 finished 事件，receiveValue 用来接收 output 值。
 ————————————————
 
 
 ————————————————
 Subscriber:
 Subscribers.Assign，和通过 sink 提供闭包，可以执行任意操作不同，assign 接受一个 【class 对象以及对象类型上的某个键路径 (key path)】。每当 output 事件到来时，其中包含的值就将被设置到对应的属性上去。
 public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable
 使用这个方法有些要求，只有那些 class 类型实例中的属性能被绑定才行，在SwiftUI中，我们常用的和View匹配的ViewModel继承了 ObservableObject，而继承 ObservableObject的只能是class类，因此assign方法常用在这里。
  
 Combine 内置了两种订阅者：Assign 和 Sink 。【SwiftUI 中还有一种订阅者：onReceive 】。
 订阅者支持取消订阅，并在发布者发布任何 Completion完成 之前关闭流处理。Assign 和 Sink 均实现了 Cancellable协议。
 当你保留了一个订阅者的引用，你很有可能想要一个其订阅的引用来取消订阅。可以用这个引用的 cancel()方法来取消订阅。【存储订阅者的引用很重要，因为当释放引用时，订阅者会取消自己的订阅】
 
 struct MyView : View {
     @State private var 当前状态值 = "ok"
     var body: some View {
         Text("当前状态: \(当前状态值)")
             .onReceive(我的订阅者) { 接收的值 in
                 self.当前状态值 = 接收的值
             }
     }
 }
 ————————————————
 
 
 
 
 
 ————————————————————————— —————————
 ————————————————————————— —————————
 https://blog.csdn.net/guoyongming925/article/details/139781390
 AnyPublisher:
 使用了eraseToAnyPublisher()方法， 就会将上游传下来的具体类型的Publisher转化成AnyPublisher，该方法下游的Subscriber接收到的就是AnyPublisher了。
 
 1. 需要保护一些私有信息
 AnyPublisher的一个引人注目的用例是保护数据流的私有详细信息。
 2. 简化复杂逻辑
 如果数据流涉及复杂的Publisher链或各种Publisher的组合，那么使用AnyPublisher进行类型擦除可以使代码更干净，更易于维护。
 3. API接口一致性
 调用eraseToAnyPublisher() 可以将不同类型的 Publisher 转换为相同的 AnyPublisher 类型，使得在统一的接口下进行操作更加方便和简洁，尤其是在需要统一处理不同类型数据流时非常有用
 ————————————————————————— —————————
 
 ————————————————————————— —————————
 AnyCancellable:
 AnyCancellable是一个非常重要的类型，用于【持有和管理订阅关系】（注意其本身不是订阅者）。它可以持有任何类型的Cancellable对象，并提供了一种类型擦除的方式来管理订阅关系。
 AnyCancellable是一个class类型，继承了Cancellable协议并实现了cancel方法。【cancel方式是用来取消订阅的】，也就是断开Publisher和Subscriber的联系，【从而不再接受Publisher的任何事件（Publisher也可发出completion(.finished/.failure）来主动结束事件流】。
 AnyCancellable 可以调用 cancel() 方法来取消订阅
 
 Cancellable 是一个非常重要的协议，用于管理和取消订阅。每当我们订阅了一个 Publisher，Combine 会返回一个符合 Cancellable  协议的实例。 我们可以通过这个实例【在适当的时候取消订阅】， 从而【停止数据流的处理，避免资源浪费和内存泄漏】。
 
 ⚠️⚠️⚠️另外特别要强调的是AnyCancellable实例在deinit时（即销毁时/ = nil）时自动调用cancel()。
 
 store(in:)方法接受一个AnyCancellable类型的集合（比如cancellable），而这个集合就是用来存储订阅的 （有多个Publisher的时候，定义很多个AnyCancellable实例对象不再适合，可改用store(in:)），如果取消订阅的话，调用cancellable.removeAll()方法
 总之【 AnyCancellable是一种管理订阅状态的工具】，能根据开发者需要在某个时段切断(cancel) Publisher和 Subscriber的联系。
 */

import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet weak var selectButton: UIButton!
    var isSelected: Bool = false
    var cancelablePipeline: AnyCancellable? = nil
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        /**
         Foundation、UIKit 和 AppKit 类的大量属性都符合 KVO 的要求。我们可以使用 KVO 来观察它们的变化。
         */
        let testLabel = UILabel()
        let kvoCancellable = testLabel.publisher(for: \.text)
            .sink { value in
                print("")
            }
    }

    @IBAction func selectAction(_ sender: Any) {
        isSelected = !isSelected
        print("isSelected \(isSelected)")
        cancelablePipeline = Just(isSelected)
            .receive(on: RunLoop.main)
            .assign(to: \.isSelected, on: selectButton)
    }
    
    @IBAction func requestNetworkAction(_ sender: Any) {
        POSManager.obj.dataTaskPublisher3()
    }
    
    @IBAction func futureAction(_ sender: Any) {
        POSManager.obj.futurePublisher()
    }
    
    @IBAction func doubtTestAction(_ sender: Any) {
        let theVC = DoubtTestViewController.loadStoryboardVC(sbName: "DoubtTest")
        self.navigationController?.pushViewController(theVC, animated: true)
    }
    
    //MARK: - 网络受限时从备用 URL 请求数据
    @IBAction func tryCatchTryMapAction(_ sender: Any) {
        let regularURL = URL(string: "https://heckj.github.io/swiftui-notes/index_zh-CN.html#patterns-constrained-network")!
        let lowDataURL = URL(string: "https://postman-echo.com/time/valid?timestamp=2016-10-10")!
        cancelablePipeline = POSManager.obj.adaptiveLoaderFunc(regularURL: regularURL, lowDataURL: lowDataURL)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print(".sink() finished")
                case .failure(let failure):
                    print(".sink() response failed, ", failure)
                }
            }, receiveValue: { someValue in
                print(".sink response: ", someValue)
            })
        
        /**
         先设置低数据模式再测试请求：
         设置 -- 蜂窝网络 -- 蜂窝数据选项 -- 数据模式 -- 低数据模式
         
         ⚠️⚠️⚠️ 注意两种情况下的response，非低数据模式返回的是整个网页数据 swiftui-notes/index_zh-CN
         低数据模式打印结果：
         will requet low data url （）
         .sink response:  19 bytes
         .sink() finished
         
         非低数据模式打印结果：
         .sink response:  752616 bytes
         .sink() finished
         
         打印的警告：
         Task <C2FDA56C-4500-4EBB-87CC-C41C9E7692AD>.<3> finished with error [-1009] Error Domain=NSURLErrorDomain Code=-1009 "The Internet connection appears to be offline." UserInfo={NSErrorFailingURLStringKey=https://heckj.github.io/swiftui-notes/index_zh-CN.html#patterns-constrained-network, _kCFStreamErrorDomainKey=1, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <C2FDA56C-4500-4EBB-87CC-C41C9E7692AD>.<3>, NSURLErrorNetworkUnavailableReasonKey=2, _NSURLErrorRelatedURLSessionTaskErrorKey=(
             "LocalDataTask <C2FDA56C-4500-4EBB-87CC-C41C9E7692AD>.<3>"
         ), NSLocalizedDescription=The Internet connection appears to be offline., NSErrorFailingURLKey=https://heckj.github.io/swiftui-notes/index_zh-CN.html#patterns-constrained-network, NSUnderlyingError=0x301fb8660 {Error Domain=kCFErrorDomainCFNetwork Code=-1009 "(null)" UserInfo={NSURLErrorNetworkUnavailableReasonKey=2, _kCFStreamErrorDomainKey=1, _kCFStreamErrorCodeKey=50, _NSURLErrorNWResolutionReportKey=Resolved 0 endpoints in 1ms using unknown from cache, _NSURLErrorNWPathKey=unsatisfied (Constrained path prohibited), interface: pdp_ip0[lte], ipv4, ipv6, dns, expensive, constrained, uses cell}}, _kCFStreamErrorCodeKey=50}
         */
    }
}

