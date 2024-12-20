//
//  DebounceThrottleObject.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/11.
//

/**
 Debounce 和 Throttle 是两种常用的操作符，用于控制数据流的频率和处理延迟。但它们的实现方式略有不同。理解这些差异对于在Combine代码中做出正确选择至关重要。
 
 ————————————————
 Debounce 操作符用于限制数据流的频率，【只有在指定的时间间隔内没有新数据到达时】，才会将最后一个数据发送出去
 使用场景
 当你想对用户输入或数据更改做出反应，但不想处理每个中间值时，Debounce特别有用。
 常见的用例包括搜索栏、文本输入字段或自动建议，您希望在开始搜索之前等待用户暂停输入。
 
 Throttle 操作符用于控制数据流的速率，【只有在指定的时间间隔内才会发送数据】，忽略掉间隔内的其他数据。
 使用场景
 当你想要强制一个一致的更新速度，或者当你想要防止超载的下游系统与过多的数据。
 它通常用于滚动事件或处理UI组件中的用户交互等场景（比如防止连续点击Button）
 
 ————————————————
 理解Combine中debounce和throttle的区别对于有效的事件处理和数据流控制至关重要。
 Debounce 操作符用于限制数据流的频率，只有在指定的时间间隔内没有新数据到达时，才会将最后一个数据发送出去。
 Throttle 操作符用于控制数据流的速率，只有在指定的时间间隔内才会发送数据，忽略掉间隔内的其他数据。
 
 ------------Debounce常见使用场景--------------
 搜索框输入：如上例所示，确保在用户停止输入一段时间后再进行搜索，以减少网络请求次数。
 用户输入验证：在用户输入时，例如密码或用户名，使用debounce可以确保在用户停止输入后再执行验证，避免频繁的验证操作。
 UI界面更新：在某些情况下，当界面上的某个状态发生变化时，使用debounce可以避免过于频繁地更新UI，提高性能。
 */

import UIKit
import Combine

class DebounceThrottleObject: ObservableObject {
    let publisher1 = PassthroughSubject<String, Never>()
    let publisher2 = PassthroughSubject<String, Never>()
    private var cancellable: Set<AnyCancellable> = []
    @Published var outputArray: [String] = []
    
    init() {
        publisher1
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                print("Debounce received value: \(value)")
                self?.outputArray.append(value)
            }
            .store(in: &cancellable)
        
        publisher2
            .throttle(for: .seconds(0.5), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] value in
                print("Throttle received value: \(value)")
                self?.outputArray.append(value)
            }
            .store(in: &cancellable)
    }
    
    func clear() {
        outputArray.removeAll()
    }
    
    //MARK: - debounce
    func debounceSendMessage() {
        clear()
        
        /**
         debounce 执行原理：
         当接收到新的值时，debounce启动一个定时器。
         如果在定时器到期前收到其他值，则复位定时器（重新计时，且预发出值替换成该值）。
         在没有新的输入的情况下，计时器完成后才会发出最新的值。
         */
        
        /**
         打印结果：
         错误理解：1, 4, 5, 6
         实际结果：4, 5, 6
         解析在下面，自行理解后再看
         */
        publisher1.send("1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.publisher1.send("2")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.publisher1.send("3")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.publisher1.send("4")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.publisher1.send("5")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.publisher1.send("6")
        }
        
        /**
         下面的发送是指发布者发出数据，但订阅者不一定能收到
         // 发送1，开始计时。
         // 0.25秒后发送2，与上次发送间隔未超过0.5秒，停止上次计时，并且重新开始计时，记录最新值为2.
         // 0.5秒后发送3，与上次发送间隔未超过0.5秒，停止上次计时，并且重新开始计时，记录最新值为3.
         // 0.75秒后发送4，与上次发送间隔未超过0.5秒，停止上次计时，并且重新开始计时，记录最新值为4.
         // 1.3秒后发送5，与上次发送间隔超过0.5秒，所以4已经在1.25秒的时候发出去了，并且订阅者收到。此时发送5并开始计时。
         */
    }
    
    //MARK: throttle
    func throttleSendMessage() {
        clear()
        
        /**
         throttle执行原理:
         当接收到新值时，启动计时器并允许该值通过。
         在计时器持续时间内收到的任何后续值都将被忽略（只预留第一个或最后一个值--取决于latest参数）。
         计时器到期后，发出预留值，并开始一个新的计时器。
         
         打印结果：
         1, 3, 5, 6 (latest: true)
         1, 2, 4, 6 (latest: false)
         
         0～0.5秒内：发送了2和3。最终3通过（如果latest为false，2通过）。
         0.5～1.0秒内：发送了4和5。最终5通过（如果latest为false，4通过）。
         1.0～1.5秒内：发送了6。最终6通过。
         */
        publisher2.send("1")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.publisher2.send("2")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.publisher2.send("3")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.publisher2.send("4")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.publisher2.send("5")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.publisher2.send("6")
        }
    }
}
