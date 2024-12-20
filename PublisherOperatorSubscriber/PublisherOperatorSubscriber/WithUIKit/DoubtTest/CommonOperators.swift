//
//  CommonOperators.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/12.
//  带有⚠️标记的要重点留意

import Foundation
import Combine

/**
 Combine中对 Publisher的值进行操作的方法称为 Operator（操作符）。 Combine中的 Operator通常会生成一个 Publisher，该 Publisher处理传入事件，对其进行转换，然后将更改后的事件发送给 Subscriber。
 */
class CommonOperators: ObservableObject {
    private var cancellable: Set<AnyCancellable> = []
    
    deinit {
        print("销毁 CommonOperators -- cancellable")
        cancellable.removeAll()
    }
    
    // 测试管道中如果有nil，会不会传递到订阅者，还是被过滤了
    func mapFunc() {
        let intArray = [1,2,3,4,5,nil,7,8,9]
        _ = intArray.publisher
            .map({ String(describing: $0) })
            .sink(receiveValue: { value in
                print("Map Received value \(value)")
            })
        /**
         打印结果：nil 会被发送出去，传递给订阅者
         Map Received value Optional(1)
         Map Received value Optional(2)
         Map Received value Optional(3)
         Map Received value Optional(4)
         Map Received value Optional(5)
         Map Received value nil
         Map Received value Optional(7)
         Map Received value Optional(8)
         Map Received value Optional(9)
         */
    }
    
    /**
     包括map在内的几个操作符都有一个对应的try操作符，该操作符将接受可能引发错误的闭包。 如果有错误抛出，它将发送错误完成事件
     */
    func tryMapFunc() {
        let testA = Character(Unicode.Scalar(65) ?? "\0").description.localizedLowercase
        print("测试Unicode转字符 \(testA)")
        
        let publisher = PassthroughSubject<String, Never>()
        publisher
            .tryMap { value in
                try JSONSerialization.jsonObject(with: value.data(using: .utf8)!, options: .allowFragments)
            }
            .sink(receiveCompletion: { print("tryMap sink \($0)")},
                  receiveValue: { print("tryMap sink received: \($0)") })
            .store(in: &cancellable)
        
        publisher.send(#"{"name": "DK"}"#)
        publisher.send("not a JSON")
        
        /**
         测试Unicode转字符 a
         tryMap sink received: {
             name = DK;
         }
         tryMap sink failure(Error Domain=NSCocoaErrorDomain Code=3840 "Something looked like a 'null' but wasn't around line 1, column 0." UserInfo={NSDebugDescription=Something looked like a 'null' but wasn't around line 1, column 0., NSJSONSerializationErrorIndex=0})
         */
    }
    
    /**
     filter 操作符主要用于过滤数据
     如下面的数据中，将大于5的数输出
     */
    func filterFunc() {
        let intArray = [1,2,3,4,5,6,7,8,9]
        _ = intArray.publisher
            .filter({ $0 > 5 })
            .sink(receiveValue: { value in
                print("filter value is \(value)")
            })
        
        /**
         打印结果：
         filter value is 6
         filter value is 7
         filter value is 8
         filter value is 9
         */
    }
    
    /**
     tryFilter 过滤在 抛出错误的闭包中 求值的元素
     如果【闭包抛出错误，则publisher将【因该错误而失败终止】】
     */
    func tryFilterFunc() {
        struct ZeroError: Error {}
        
        let intArray = [1,2,3,4,5,6,0,8,9]
        _ = intArray.publisher
            .tryFilter({ value in
                if value == 0 {
                    throw ZeroError()
                } else {
                    return value > 5
                }
            })
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("tryFilter Received completion \(completion)")
                case .failure(let failure):
                    print(("tryFilter Received fail error ", failure))
                }
            }, receiveValue: { value in
                print("tryFilter Received value \(value)")
            })
        
        /**
         打印结果：
         tryFilter Received value 6
         ("tryFilter Received fail error ", PublisherOperatorSubscriber.CommonOperators.(unknown context at $1018e2dc4).(unknown context at $1018e2dd0).ZeroError())
         */
    }
    
    /**
     compactMap 与Swift标准库中的compactMap(_:)类似。
     该操作符移除Publisher流中的nil元素，并将非nil元素重新发布给下游订阅者
     */
    func compactMapFunc() {
        /**
         数组：
         let strings = ["1", "2", "3", "abc", "5"]
         let numbers = strings.compactMap { Int($0) }
         print(numbers)
         // 输出: [1, 2, 3, 5]
         */
        // 字典
        let numbers = (0...5)
        let romanNumeralDict: [Int: String] = [1: "one", 2: "two", 3: "three", 5: "five"]
        
        _ = numbers.publisher
            .compactMap({ romanNumeralDict[$0] })
            .sink(receiveValue: { value in
                print("compactMap Received value \(value)")
            })
        // 当通过key为4的值的时候为nil了，所以这里将nil去除了。
        
        /**
         打印结果：
         compactMap Received value one
         compactMap Received value two
         compactMap Received value three
         compactMap Received value five
         */
        
        let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher
        strings
            .compactMap({ Float($0) })
            .sink(receiveValue: { print("\($0)") })
            .store(in: &cancellable)
        /**
         打印结果：
         1.24
         3.0
         45.0
         0.23
         */
    }
    
    /**
     tryCompactMap(_: )相比compactMap(_:)除了都能去除nil外，前者还能在闭包内抛出错误。
     如果闭包抛出错误，则Publisher流将因该错误而失败终止。
     */
    func tryCompactMapFunc() {
        struct ParseError: Error {}
        func romanNumeral(from: Int) throws -> String? {
            let romanNumeralDict: [Int: String] = [1: "one", 2: "two", 3: "three", 4: "Four", 5: "five"]
            guard from != 0 else { throw ParseError() }
            return romanNumeralDict[from]
        }
        
        let numbers = [6,5,4,3,2,1,0]
        _ = numbers.publisher
            .tryCompactMap({ try romanNumeral(from: $0) })
            .sink(receiveCompletion: { completion in
                print("tryCompactMap Received completion \(completion)")
            }, receiveValue: { value in
                print("tryCompactMap Received value \(value)")
            })
        /**
         打印结果：
         tryCompactMap Received value five
         tryCompactMap Received value Four
         tryCompactMap Received value three
         tryCompactMap Received value two
         tryCompactMap Received value one
         tryCompactMap Received completion failure(PublisherOperatorSubscriber.CommonOperators.(unknown context at $1018e2df8).(unknown context at $1018e2e04).ParseError())
         */
    }
    
    /**
     数组高阶函数 flatMap 说明：
     对集合中的每个元素进行转换，并返回一个新的包含转换结果的扁平化集合，扁平化集合的意思是如果数组有嵌套，它会把嵌套的数组元素拿出来统一合并成一个单一的集合。
     
     Combine的 flatMap 说明：
     public func flatMap<P>(maxPublishers: Subscribers.Demand = .unlimited, _ transform: @escaping (Self.Output) -> P) -> Publishers.FlatMap<P, Self> where P : Publisher, P.Failure == Never
     核心：flatMap输出的是发布者而非数值，flatMap输出的发布者的Failure是 Never 而非 Error，这些都是在闭包中完成的
     
     flatMap 是 Combine 框架中的一个操作符，它用于将上游发送的值转换为新的发送者， 然后将这些发送者的值拼接起来作为下游的输出。 【flatMap 的工作方式类似于 map，但它要求转换后的发送者必须是 "flat" 的，也就是说它们不能发出错误】。【如果转换后的发送者发出错误，flatMap 会将这个错误传递给订阅的接收者。】
     */
    func flatMapFunc() {
        let arrays = [[1, 2, 3], [4, 5], [6, 7, 8, 9]]
        // Binary operator '*' cannot be applied to operands of type '[Int]' and 'Int'
        // let numbers = arrays.flatMap({ $0 * 10 })
        // No exact matches in call to instance method 'flatMap', flatMap需要返回Publisher
        // let numbers = arrays.publisher.flatMap({ $0 })
        // 这只是数组的高阶方法
        // let numbers = arrays.flatMap({ $0 })
        // print("flatMap value \(numbers)")
        arrays.publisher.flatMap({ Just($0) })
            .sink { value in
                print("flatMap sink receive \(value)")
            }
            .store(in: &cancellable)
        
        // 以下是一个简单的例子，演示如何使用 flatMap 来将一个发送字符串的发送者转换为一个发送整数的发送者
        let strings = ["1", "2", "3"]
        let publisher = PassthroughSubject<String, Never>()
        
        let flatMappedPublisher = publisher.flatMap { string -> Just<Int> in
            // 将字符串转换为可以发送一个整数的发送者
            return Just(Int(string) ?? 0)
        }
        
        flatMappedPublisher
            .sink { value in
                print(value)
            }
            .store(in: &cancellable)
        
        strings.forEach { item in
            publisher.send(item)
        }
    }
    
    /**
     flatmap作用是在publisher内部仍然包含publisher时可以将事件扁平化，具体查看以下代码
     
     在一开始我们使用chat.sink { print($0.message.value)} 订阅事输出只有三句话，这是因为我们只对 chat 进行了订阅。当具体的Chatter的message变化时，我们并不能订阅到事件。那我想订阅全部的谈话事件怎么办呢？flatMap正是为此而生的，当我们改成flatmap的订阅后可以输出所有publisher的事件，包括publisher的值内部的publisher发出的事件。
     */
    func flatMapFunc2() {
        // 1 定义三个人用于聊天
        let xm = Chatter(name: "小明", message: "小明：鄙人王小明！")
        let lw = Chatter(name: "老王", message: "老王：我是隔壁老王！")
        let ydy = Chatter(name: "于大爷", message: "于大爷：烫头去")
        
        // 2 创建聊天，并设置初始值
        let chat = CurrentValueSubject<Chatter, Never>(xm)
        
        // 第一种
//        chat
//            .sink { value in
//                print("CurrentValue sink receive \(value.message)")
//            }
//            .store(in: &cancellable)
        
        // 第二种
        chat
            .flatMap(maxPublishers: .max(2)) { model in
                return model.message
            }
            .sink { value in
                print("flatMap sink receive \(value)")
            }
            .store(in: &cancellable)
        
        xm.message.value = "小明：马冬梅在家吗？"
        chat.value = lw
        lw.message.value = "老王：什么冬梅？"
        xm.message.value = "小明：马冬梅啊！"
        lw.message.value = "老王：马东什么？"
        chat.value = ydy
        ydy.message.value = "于大爷：吃地道卤煮"
        /**
         第一种打印结果：
         CurrentValue sink receive 小明：鄙人王小明！
         CurrentValue sink receive 老王：我是隔壁老王！
         CurrentValue sink receive 烫头去
         */
        
        /**
         第二种打印结果：
         flatMap sink receive 小明：鄙人王小明！
         flatMap sink receive 小明：马冬梅在家吗？
         flatMap sink receive 老王：我是隔壁老王！
         flatMap sink receive 老王：什么冬梅？
         flatMap sink receive 小明：马冬梅啊！
         flatMap sink receive 老王：马东什么？
         /*--.max(2)改为 .max(3) 或者 .unlimited，才有以下打印--*/
         flatMap sink receive 于大爷：烫头去
         flatMap sink receive 于大爷：吃地道卤煮
         
         map操作会缓存publisher，为了防止我们缓存太多的publisher我们可以在flatmap时指定缓存的publisher个数(maxPublishers: .max(2))
         */
    }
    
    /**
     flatMap 操作符会转换上游发布者发送的所有的元素，然后【返回一个新的或者已有的发布者。】
     flatMap 会将所有返回的发布者的输出合并到一个输出流中（有点像数组的高阶函数 flatMap，但还是不一样的）。我们可以通过 flatMap 操作符的 maxPublishers 参数【指定返回的发布者的最大数量】。
     flatMap 常在错误处理中用于返回备用发布者和默认值
     */
    func flatMapFunc3() {
        guard let data1 = #"{"id": 1}"#.data(using: .utf8),
            let data2 = #"{"i": 2}"#.data(using: .utf8),
            let data3 = #"{"id": 3}"#.data(using: .utf8) else {
                print("flatMapFunc3 字符串转Data失败")
                return
        }
        
        [data1, data2, data3].publisher
        //第一种
            .flatMap { data -> AnyPublisher<FlatMapTestModel?, Never> in
                return Just(data)
                    // ⚠️⚠️⚠️ 注意不能是FlatMapTestModel.self，因为新的发布者的值是可选的
                    // .decode(type: FlatMapTestModel.self, decoder: JSONDecoder())
                    .decode(type: FlatMapTestModel?.self, decoder: JSONDecoder())
                    .catch({ _ in
                        // 解析失败时，返回默认值 nil
                        return Just(nil)
                    })
                    .eraseToAnyPublisher()
            }
        // 第二种
//            .setFailureType(to: Error.self)
//            .flatMap({ data -> AnyPublisher<FlatMapTestModel?, Error> in
//                return Just(data)
//                    // ⚠️⚠️⚠️ 注意不能是FlatMapTestModel.self，因为新的发布者的值是可选的
//                    //.decode(type: FlatMapTestModel.self, decoder: JSONDecoder())
//                    .decode(type: FlatMapTestModel?.self, decoder: JSONDecoder())
//                    .eraseToAnyPublisher()
//            })
            .sink { completion in
                print("flatMapFunc3 sink completion ", completion)
            } receiveValue: { value in
                print("flatMapFunc3 sink receive ", value)
            }
            .store(in: &cancellable)

        /**
         第一种打印结果（Catch捕获管道中错误，并替换为默认值）：
         flatMapFunc3 sink receive  Optional(PublisherOperatorSubscriber.FlatMapTestModel(id: 1))
         flatMapFunc3 sink receive  nil
         flatMapFunc3 sink receive  Optional(PublisherOperatorSubscriber.FlatMapTestModel(id: 3))
         flatMapFunc3 sink completion  finished
         */
        
        /**
         第二种打印结果（未使用Catch捕获管道中错误）：
         flatMapFunc3 sink receive  Optional(PublisherOperatorSubscriber.FlatMapTestModel(id: 1))
         flatMapFunc3 sink completion  failure(Swift.DecodingError.keyNotFound(CodingKeys(stringValue: "id", intValue: nil), Swift.DecodingError.Context(codingPath: [], debugDescription: "No value associated with key CodingKeys(stringValue: \"id\", intValue: nil) (\"id\").", underlyingError: nil)))
         
         最终，下游订阅者因为上游发生了错误而终止了订阅，下游便无法收到
         flatMapFunc3 sink receive  Optional(PublisherOperatorSubscriber.FlatMapTestModel(id: 3))
         */
    }
    
    /**
     flatMap 处理错误，防止管道数据流终止
     */
    func flatMapCatchFunc() {
        let requestDataPublisher = Just(URL(string: "https://www.baidu.com/xxx"))
            .flatMap { url in
                let response = Future<String, Error> { promise in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        let success = Bool.random()
                        if success {
                            promise(.success("请求成功，返回的数据..."))
                        } else {
                            promise(.failure(NSError(domain: "请求失败，网络错误", code: -1, userInfo: nil)))
                        }
                    }
                }
                
                return response
                        .catch { _ in
                            return Just("请求失败，网络错误")
                        }
            }
            .eraseToAnyPublisher()
        
        requestDataPublisher
            .sink { completion in
                switch completion {
                case .finished:
                    print("flatMap Catch sink finished, \(completion)")
                case .failure(let error):
                    print("flatMap Catch sink erorr, ", error)
                }
            } receiveValue: { value in
                print("flatMap Catch sink value \(value)")
            }
            .store(in: &cancellable)
    }
    
    /**
     removeDuplicates 可以去除重复数据（过滤掉连续的重复值）
     注意removeDuplicates操作符不会将Publisher作为一个集合去排重，而是随着时间根据上下接收到的数据排重，如果相同的数据不挨着，那么不会认为是重复的。【只有相邻的挨着的数据有重复才会去重】
     */
    func removeDuplicatesFunc() {
        let intArray = [1,1,3,5,5,6,7,8,9,1,5]
        _ = intArray.publisher
            .removeDuplicates()
            .sink(receiveValue: { value in
                print("removeDuplicates Received value \(value)")
            })
        /**
         打印结果：
         removeDuplicates Received value 1
         removeDuplicates Received value 3
         removeDuplicates Received value 5
         removeDuplicates Received value 6
         removeDuplicates Received value 7
         removeDuplicates Received value 8
         removeDuplicates Received value 9
         removeDuplicates Received value 1
         removeDuplicates Received value 5
         */
    }
    
    /**
     first(where:)操作符和filter操作符很相似，filter是找出所有满足条件的数据，而first(where:)操作符是找出第一个满足条件的数据。
     last(where:)和first(where:)操作符正好相反， last(where:)操作符查找符合条件的最后一个数据。
     
     ⚠️注意：
     first(where:) 找到序列中的第一个满足条件的值然后发出，并且发送完成事件，取消上游的 publishers 继续向其发送值的动作；
     last(where:) 必须等待所有值发出，才能知道是否找到匹配的值。 因此，上游必须是一个已经完成的publisher；
     first() 发出原始序列中的第一个值，然后发出完成事件；
     last() ，与 first 相反，发出原始序列中的最后一个值，然后发出完成事件。 要求序列是已完成的序列否则会等待原始序列的完成事件。
     ⚠️⚠️⚠️ last需要等待发布者的完成事件，否则会一直等待，建议注意或少用
     */
    func firstLastWhere() {
        let intArray = [1,5,3,7,2,6,4,8,9]
        _ = intArray.publisher
            .print("first(where:)")
            //.first()
            .first(where: { $0 > 5 })
            .sink(receiveCompletion: { completion in
                print("firstwhere completion")
            }, receiveValue: { value in
                print("firstwhere Received value \(value)")
            })
        _ = intArray.publisher
            .print("last(where:)")
            //.last()
            .last(where: { $0 < 6 })
            .sink(receiveCompletion: { completion in
                print("lastwhere completion")
            }, receiveValue: { value in
                print("lastwhere Received value \(value)")
            })
        /**
         打印结果：
         first(where:): receive subscription: ([1, 5, 3, 7, 2, 6, 4, 8, 9])
         first(where:): request unlimited
         first(where:): receive value: (1)
         first(where:): receive value: (5)
         first(where:): receive value: (3)
         first(where:): receive value: (7)
         first(where:): receive cancel
         firstwhere Received value 7
         firstwhere completion
         
         last(where:): receive subscription: ([1, 5, 3, 7, 2, 6, 4, 8, 9])
         last(where:): request unlimited
         last(where:): receive value: (1)
         last(where:): receive value: (5)
         last(where:): receive value: (3)
         last(where:): receive value: (7)
         last(where:): receive value: (2)
         last(where:): receive value: (6)
         last(where:): receive value: (4)
         last(where:): receive value: (8)
         last(where:): receive value: (9)
         last(where:): receive finished
         lastwhere Received value 4
         lastwhere completion
         */
    }
    
    /**
     merge 操作符可以将多个 Publisher 合并成一个，并按照它们产生事件的顺序将这些事件发送给下游。
     ⚠️注意：不同于 combineLatest 和  zip ，merge 合并后的数据不是元组！（看下面的打印结果）
     相当于多条道路的车辆汇流到主道（主道同一时间只能通行一辆车）
     combineLatest 和 zip 看CombineLatestAndZipVC
     */
    func mergeFunc() {
        let publisher1 = PassthroughSubject<Int, Never>()
        let publisher2 = PassthroughSubject<Int, Never>()
        
        publisher1
            .merge(with: publisher2)
            .sink { value in
                print("merge Received value \(value)")
            }
            .store(in: &cancellable)
        
        publisher1.send(1)
        publisher2.send(2)
        publisher1.send(3)
        publisher2.send(4)
        
        /**
         打印结果：
         merge Received value 1
         merge Received value 2
         merge Received value 3
         merge Received value 4
         */
    }
    
    /**
     setFailureType 操作符可以【将当前序列的失败类型设置为指定的类型】，主要用于适配具有不同失败类型的发布者。
     发布者的类型是 Publisher<Output, Failure>，其中Failure可以是 Error 或者 Never
     */
    func setFailureTypeFunc() {
        let publisher = PassthroughSubject<Int, Error>()
        
        Just(2)
            .setFailureType(to: Error.self)
            .merge(with: publisher)
            .sink { completion in
                print("setFailureType sink completion ", completion)
            } receiveValue: { value in
                print("setFailureType sink receive \(value)")
            }
            .store(in: &cancellable)
        
        publisher.send(1)
        
        /**
         打印结果:
         setFailureType sink receive 2
         setFailureType sink receive 1
         
         如果注释 .setFailureType(to: Error.self) 这一行代码，编译器就会给出错误：
         Instance method 'merge(with:)' requires the types 'Never' and 'any Error' be equivalent
         因为，Just(2) 的失败类型是 Never，而 PassthroughSubject<Int, Error>() 的失败类型是 Error。
         通过调用 setFailureType 操作符，可以将 Just(2) 的失败类型设置为 Error（<Int, Never>  --->  <Int, Error>）。
         */
    }
    
    /**
     switchToLatest：
     1、其输入为publihser，输出为具体的值，这就说明它会等待publisher的输出，不管publisher是即时的(Just(1)) 还是异步的(URLSession.shared.dataTaskPublisher(for: url))
     2、只保留最后的publisher，之前的publisher会自动取消。（补充：因为它会等待publisher的输出，那么在等待时间内
     没有新的 publisher 进来，之前的 publisher 就不会被取消，而是可能执行完成；等待时间由 publisher 决定，自动取消由新的 publisher 进入时机决定）
     switchToLatest的核心思想是保留最后一个publisher，在实际开发中，特别适合用于过滤搜索框的多余的网络请求。
     https://zhuanlan.zhihu.com/p/345054834
     */
    func switchToLatest1Func() {
        let subject = PassthroughSubject<Int, Never>()
        
        subject
            .setFailureType(to: URLError.self)
            .map { index -> URLSession.DataTaskPublisher in
                let url = URL(string: "https://example.org/get?index=\(index)")!
                return URLSession.shared.dataTaskPublisher(for: url)
            }
            .switchToLatest()
            .sink { completion in
                print("switchToLatest sink completion, ", completion)
            } receiveValue: { (data, response) in
                guard let url = response.url else {
                    print("Bad Response")
                    return
                }
                print("switchToLatest sink receive \(url)")
            }
            .store(in: &cancellable)

        for index in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(index / 10)) {
                subject.send(index)
            }
        }
        
        /**
         打印结果：
         switchToLatest sink receive https://example.org/get?index=5
         
         上边的例子中，我们使用PassthroughSubject来发送数据，接下来通过map把1～5转换成网络请求，由于网络请求是有一定延时的，所以只输出了最后发送的数据，因为前边的请求都被取消了，上边的情况正好验证了switchToLatest的含义。
         */
    }
    
    func switchToLatest2Func() {
        let subject = PassthroughSubject<Int, Never>()
        
        subject
            .setFailureType(to: URLError.self)
            .map { index -> Just<Int> in
                return Just(index)
            }
            .switchToLatest()
            .sink { completion in
                print("switchToLatest sink completion, ", completion)
            } receiveValue: { value in
                print("switchToLatest sink receive \(value)")
            }
            .store(in: &cancellable)

        for index in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(index / 10)) {
                subject.send(index)
            }
        }
        
        /**
         打印结果：
         switchToLatest sink receive 1
         switchToLatest sink receive 2
         switchToLatest sink receive 3
         switchToLatest sink receive 4
         switchToLatest sink receive 5
         
         因为Just(xxx) 并不需要等待，所以即发即收
         */
    }
    
    func switchToLatest3Func() {
        let subjects = PassthroughSubject<PassthroughSubject<String, Never>, Never>()
        subjects
            .switchToLatest()
            .sink(receiveValue: { print($0) })
            .store(in: &cancellable)
        
        let stringSubject1 = PassthroughSubject<String, Never>()
        subjects.send(stringSubject1)
        stringSubject1.send("A")
        
        let stringSubject2 = PassthroughSubject<String, Never>()
        subjects.send(stringSubject2) // 发布者切换为 stringSubject2
        
        // 收不到原因：发布者从subject1 切换到 subject2，subject1没有订阅者了
        stringSubject1.send("B") // 下游不会收到
        stringSubject1.send("C") // 下游不会收到
        stringSubject2.send("D")
        stringSubject2.send("E")
        stringSubject2.send(completion: .finished)
        
        /**
         打印结果：
         A
         D
         E
         */
        // 类似的例子还有这个：https://www.jianshu.com/p/4058823d1bba
    }
    
    func switchToLatest4Func() {
        let subject = PassthroughSubject<String, Error>()
        subject.map { value in
            // 发起网络请求，或者其他可能失败的任务
            return Future<Int, Error> { promise in
                if let intValue = Int(value) {
                    // 根据传入的值延迟执行
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(intValue)) {
                        promise(.success(intValue))
                    }
                } else {
                    // 失败立即返回结果
                    promise(.failure(NSError(domain: "not Integer", code: -1)))
                }
            }
            // 提供默认值，转换成<Int, Never>，防止下游的订阅因为失败而被终止
            .replaceError(with: 0)
            .eraseToAnyPublisher()
        }
        .switchToLatest()
        .sink { completion in
            print("switchToLatest4 sink completion, ", completion)
        } receiveValue: { value in
            print("switchToLatest4 sink receive \(value)")
        }
        .store(in: &cancellable)
        
        subject.send("3") // 下游不会收到 3
        subject.send("")  // 立即失败，下游会收到0，之前的 3 会被丢弃
        subject.send("1") // 延时 1 秒后，下游收到 1
        
        /**
         打印结果：
         switchToLatest4 sink receive 0
         switchToLatest4 sink receive 1
         
         注意，在发送了 "" 之后，之前发送的 "3" 依然会触发 Future 中的操作，但是这个 Future 里的 promise(.success(intValue)) 中传入的 3，下游不会收到。因为管道的发布者已经切换到Future<1>
         */
    }
    
    /**
     print 操作符主要用于打印所有发布的事件，您可以选择为输出的内容添加前缀。
     */
    func printFunc() {
        [1, 2, 3].publisher
            .print("print ") // 添加前缀
            .sink(receiveValue: { _ in })
            .store(in: &cancellable)
        
        /**
         打印结果：
         print : receive subscription: ([1, 2, 3])
         print : request unlimited
         print : receive value: (1)
         print : receive value: (2)
         print : receive value: (3)
         print : receive finished
         */
    }
    
    /**
     https://www.cnblogs.com/ficow/p/13788610.html
     breakpoint 操作符可以发送调试信号来让调试器暂停进程的运行，只要在给定的闭包中返回 true 即可。
     通过使用 breakpoint 操作符，我们可以很容易地在订阅操作、输出、完成发生时启用断点。
     如果这时候想直接在代码上打断点，我们就要重写 sink 部分的代码，而且无法轻易地为订阅操作启用断点
     */
    func breakpoint() {
        [1, 2, 3].publisher
            .breakpoint { subscription in
                return false // 返回 true 以抛出 SIGTRAP 中断信号，调试器会被调起
            } receiveOutput: { value in
                return false // 返回 true 以抛出 SIGTRAP 中断信号，调试器会被调起
            } receiveCompletion: { completion in
                return false // 返回 true 以抛出 SIGTRAP 中断信号，调试器会被调起
            }
            .sink(receiveValue: { _ in })
            .store(in: &cancellable)
    }
    
    /**
     handleEvents 操作符可以在 发布事件 发生时执行指定的闭包。
     handleEvents 接受的闭包都是可选类型的，所以我们可以只需要对感兴趣的事件进行处理即可，不必为所有参数传入一个闭包。
     可以在这些闭包里面控制 loading显示与隐藏
     */
    func handleEvents() {
        [1, 2, 3].publisher
            .handleEvents { subscription in
                print("订阅事件")
            } receiveOutput: { value in
                print("值事件 value \(value)")
            } receiveCompletion: { completion in
                print("完成事件")
            } receiveCancel: {
                print("取消事件")
            } receiveRequest: { demand in
                print("请求事件 \(demand)")
            }
            .sink(receiveValue: { _ in })
            .store(in: &cancellable)
        
        /**
         打印结果：
         订阅事件
         请求事件 unlimited
         值事件 value 1
         值事件 value 2
         值事件 value 3
         完成事件
         */
    }
    
    /**
     【Future 是一个类！】，而不是一个结构。创建后，它立即调用闭包开始计算结果。
     它存储 Promise 的结果并将其交付给当前和未来的 Subscriber。
     
     在实践中，这意味着 Future 是一种便捷的方式，可以立即开始执行某些工作，同时【只执行一次工作并将结果交付给任意数量的 Subscriber】。但它执行工作并【返回单个结果，而不是结果流】，因此使用场景比成熟的 Subscriber 要更少。当我们需要共享网络请求产生的单个结果时，它是一个很好的选择！
     */
    func futureFunc() {
        /**
         测试Future立即执行闭包任务，结束后如果没有被订阅，会不会保留结果数据
         测试结果：立即执行的结果会被保留，且可以被多次订阅
         */
        func performSomeWork() throws -> Int {
            print("performing some work and returning a result")
            return 5
        }
        
        let future = Future<Int, Error> { promise in
            do {
                let result = try performSomeWork()
                promise(.success(result))
            } catch {
                promise(.failure(error))
            }
        }
        
        print("subscribing to future...")
        future
            .sink { completion in
                print("subscription1 completed")
            } receiveValue: { value in
                print("subscription1 received \(value)")
            }
            .store(in: &cancellable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            future
                .sink { completion in
                    print("subscription2 completed")
                } receiveValue: { value in
                    print("subscription2 received \(value)")
                }
                .store(in: &self.cancellable)
        }
        
        /**
         打印结果：
         performing some work and returning a result
         subscribing to future...
         subscription1 received 5
         subscription1 completed
         subscription2 received 5
         subscription2 completed
         */
    }
    
    /**
     Deferred延迟执行，可让Future在创建后不会立即执行，而是等待被订阅时才开始执行
     */
    func deferredFunc() {
        let delayPublisher = Deferred {
            Future<String, Error> { promise in
                print("开始请求数据...")
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                    let isb = Bool.random() // 随机布尔
                    if isb {
                        promise(.success("请求成功：返回的数据"))
                    } else {
                        promise(.failure(NSError(domain: "请求失败：网络错误", code: -1, userInfo: nil)))
                    }
                }
            }
        }
        
        delayPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Deferred sink completion")
                case .failure(let error):
                    print("Deferred sink fail, ", error)
                }
            } receiveValue: { value in
                print("Deferred sink value \(value)")
            }
            .store(in: &cancellable)
    }
    
    /**
     本操作符将单个元素缓存到集合中(可以指定缓存个数，满足个数或者收到完成事件后)，然后发送集合
     使用.collect 和其他没有指定个数或缓存大小的操作符时， 注意他们将使用没有内存大小限制的缓存区存储收到的元素。【注意内存溢出】
     ⚠️高级用法：collect(.byTime(DispatchQueue.main,.seconds(collectTimeStride)) - 每隔一段事件收集数据,变成数组发送
     
     将原始序列中的元素组成集合发出，可以接受的参数有集合个数、时间、个数或时间。
     【参数是时间和个数都设置时满足任一就会发出】看collectFunc()中的定时器示例
     */
    func collectFunc() {
        ["a", "b", "c", "d", "e"].publisher
            .collect(5)
            .print("collect")
            .sink(receiveCompletion: { print("sink \($0)") },
                  receiveValue: { print("sink \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果（.collect(5)）：
         collect: receive subscription: (CollectByCount)
         collect: request unlimited
         collect: receive value: (["a", "b", "c", "d", "e"])
         sink ["a", "b", "c", "d", "e"]
         collect: receive finished
         sink finished
         
         打印结果（.collect(2)）：
         collect: receive subscription: (CollectByCount)
         collect: request unlimited
         collect: receive value: (["a", "b"])
         sink ["a", "b"]
         collect: receive value: (["c", "d"])
         sink ["c", "d"]
         collect: receive value: (["e"])
         sink ["e"]
         collect: receive finished
         sink finished
         */
        
        let publisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        publisher
            .sink { [weak self] date in
                print("origin:\t\(self?.deltaTime ?? "")\t\(date.description)")
            }
            .store(in: &cancellable)
        /// 收集数据（5s 或者 3个），满足其一发出
        publisher
            .collect(.byTimeOrCount(DispatchQueue.main, .seconds(5), 3), options: .none)
            .sink { [weak self] date in
                print("collect:\t\(self?.deltaTime ?? "")\t\(date.description)")
            }
            .store(in: &cancellable)
        
        /**
         打印结果：
         origin:    7.7    2024-12-20 01:57:52 +0000
         origin:    8.7    2024-12-20 01:57:53 +0000
         origin:    9.7    2024-12-20 01:57:54 +0000
         collect:    9.7    [2024-12-20 01:57:52 +0000, 2024-12-20 01:57:53 +0000, 2024-12-20 01:57:54 +0000]
         origin:    10.7    2024-12-20 01:57:55 +0000
         origin:    11.7    2024-12-20 01:57:56 +0000
         collect:    11.7    [2024-12-20 01:57:55 +0000, 2024-12-20 01:57:56 +0000]
         origin:    12.7    2024-12-20 01:57:57 +0000
         origin:    13.7    2024-12-20 01:57:58 +0000
         */
    }
    
    /**
     它的作用和方法名一样直白，就是在遇到可选值为空时用默认值替换空值, 原始的序列也变成一个非空序列
     */
    func replaceNilFunc() {
        ["A", nil, "C"].publisher
            //.replaceNil(with: "-")
            .map({ $0 })
            .print("replaceNil")
            .sink(receiveValue: { print($0) })
            .store(in: &cancellable)
        
        /**
         打印结果：
         replaceNil: receive subscription: (["A", "-", "C"])
         replaceNil: request unlimited
         replaceNil: receive value: (A)
         A
         replaceNil: receive value: (-)
         -
         replaceNil: receive value: (C)
         C
         replaceNil: receive finished
         
         --------注释 .replaceNil(with: "-")----------
         replaceNil: receive subscription: ([Optional("A"), nil, Optional("C")])
         replaceNil: request unlimited
         replaceNil: receive value: (Optional("A"))
         Optional("A")
         replaceNil: receive value: (nil)
         nil
         replaceNil: receive value: (Optional("C"))
         Optional("C")
         replaceNil: receive finished
         */
    }
    
    /**
     replaceEmpty(with: )
     Replaces an empty stream with the provided element. （即替换空序列）
     空序列是指没有发出任何数据的发布者，下面示例Empty<>仅仅只是用空发布者举例
     
     Empty：A publisher that never publishes any values, and optionally finishes immediately.
     一个不发任何值，只发出完成事件的发布者
     */
    func replaceEmptyFunc() {
        let empty = Empty<Int, Never>()
        empty
            //.replaceEmpty(with: 1)
            .print("replaceEmpty")
            .sink(receiveCompletion: { print($0) },
                  receiveValue: { print($0) })
            .store(in: &cancellable)
        
        /**
         打印结果：
         replaceEmpty: receive subscription: (ReplaceEmpty)
         replaceEmpty: request unlimited
         replaceEmpty: receive value: (1)
         1
         replaceEmpty: receive finished
         finished
         
         --------注释 .replaceEmpty(with: 1)----------
         replaceEmpty: receive subscription: (Empty)
         replaceEmpty: request unlimited
         replaceEmpty: receive finished
         finished
         */
    }
    
    func replaceErrorFunc() {
        let future = Future<Int, Error>{ promise in
            promise(.failure(NSError(domain: "unknown error", code: -1)))
        }
        
        future
            //.replaceError(with: 0)
            .print("replaceError")
            .sink(receiveCompletion: { print("completion \($0)") },
                  receiveValue: { print($0) })
            .store(in: &cancellable)
        
        /**
         打印结果：
         replaceError: receive subscription: (ReplaceError)
         replaceError: request unlimited
         replaceError: receive value: (0)
         0
         replaceError: receive finished
         finished
         
         --------注释 .replaceError(with: 0)----------
         replaceError: receive subscription: (Future)
         replaceError: request unlimited
         replaceError: receive error: (Error Domain=unknown error Code=-1 "(null)")
         completion failure(Error Domain=unknown error Code=-1 "(null)")
         */
    }
    
    /// 扫描之前的序列中所有元素，运用函数计算新值，接收一个初始值和每次接受到新元素的函数
    func scanFunc() {
        // 1 一共进了10个球 每个球进球得分随机1~3分，每次进球后打印当前总分
        let score = (1..<10).compactMap { value in
            return (1...3).randomElement()
        }
        
        /**
         scan<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Self.Output) -> T) -> Publishers.Scan<Self, T>
         */
        score.publisher
            .print("scan")
            .scan(0) { sum, item in
                print("sum \(sum), item \(item)")
                return sum + item
            }
            // 简化
            //.scan(0, +)
            .sink(receiveValue: { print("all score \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         scan: receive subscription: ([3, 1, 1, 2, 3, 2, 2, 3, 2])
         scan: request unlimited
         scan: receive value: (3)
         sum 0, item 3
         all score 3
         scan: receive value: (1)
         sum 3, item 1
         all score 4
         scan: receive value: (1)
         sum 4, item 1
         all score 5
         scan: receive value: (2)
         sum 5, item 2
         all score 7
         scan: receive value: (3)
         sum 7, item 3
         all score 10
         scan: receive value: (2)
         sum 10, item 2
         all score 12
         scan: receive value: (2)
         sum 12, item 2
         all score 14
         scan: receive value: (3)
         sum 14, item 3
         all score 17
         scan: receive value: (2)
         sum 17, item 2
         all score 19
         scan: receive finished
         */
    }
    
    func tryScanFunc() {
        let message = """
         类似于 map, tryMap
         上面方法 scanFunc中，.scan(0, block) 闭包中代码如果可能出错，需要执行 try xxx，抛出异常，
         则使用 tryScan
        """
        print(message)
    }
    
    /**
     忽略发送的值，如果有的时候你只在乎publisher有没有完成发送，而不关心他具体发送了那些值，可以使用 ignoreOutput，使用后将只会订阅到完成事件（错误完成或者正常结束）
     ⚠️注意：尽管忽略发布者发送的具体值，只关心完成事件，但仍需等待发布者发布完所有数据之后才发送完成事件
     */
    func ignoreOutputFunc() {
//        let publisher = (1...10_000).publisher
        let publisher = Deferred {
            return Future<Int, Error>{ promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    promise(.failure(NSError(domain: "unknown error", code: -1)))
                }
            }
        }
        publisher
            .ignoreOutput()
            .print("ignoreOutput")
            .sink(receiveCompletion: { print("completion \($0)") },
                  receiveValue: { print($0) })
            .store(in: &cancellable)
        
        /**
         打印结果（let publisher = (1...10_000).publisher）：
         ignoreOutput: receive subscription: (Empty)
         ignoreOutput: request unlimited
         ignoreOutput: receive finished
         completion finished
         
         ----------------
         打印结果（let publisher = Future<Int, Error>{ promise in }）
         ignoreOutput: receive subscription: (Future)
         ignoreOutput: request unlimited
         ignoreOutput: receive error: (Error Domain=unknown error Code=-1 "(null)")
         completion failure(Error Domain=unknown error Code=-1 "(null)")
         上面 receive error 是 5s 后打印的
         */
    }
    
    /// 忽略指定个数的值
    func dropFirst() {
        (1...7).publisher
            .dropFirst(4)
            .print("dropFirst")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         dropFirst: receive subscription: (Sequence)
         dropFirst: request unlimited
         dropFirst: receive value: (5)
         sink receive 5
         dropFirst: receive value: (6)
         sink receive 6
         dropFirst: receive value: (7)
         sink receive 7
         dropFirst: receive finished
         */
    }
    
    /**
     忽略序列中的值直到满足条件时。
     ⚠️注意：只要前面的值触发满足条件即可，后续的值即使不满足条件，也不会被过滤掉
     */
    func dropWhileFunc() {
        var numbers = (1...7).map({ $0 })
        numbers.append(contentsOf: [1,2,3])
        numbers.publisher
            .drop(while: { $0 % 5 != 0 })
            .print("drop(while:)")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        // 看看后面的 1 ~ 3 会不会打印，实测会打印
        
        /**
         打印结果：
         drop(while:): receive subscription: (Sequence)
         drop(while:): request unlimited
         drop(while:): receive value: (5)
         sink receive 5
         drop(while:): receive value: (6)
         sink receive 6
         drop(while:): receive value: (7)
         sink receive 7
         drop(while:): receive value: (1)
         sink receive 1
         drop(while:): receive value: (2)
         sink receive 2
         drop(while:): receive value: (3)
         sink receive 3
         drop(while:): receive finished
         */
    }
    
    /// 忽略序列中对的值，直到另一个序列开始发送值
    func dropUntilOutputFromFunc() {
        let isReady = PassthroughSubject<Void, Never>()
        let taps = PassthroughSubject<Int, Never>()
        
        taps
            .drop(untilOutputFrom: isReady)
            .print("drop(untilOutputFrom:)")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        (1...5).forEach { n in
            taps.send(n)
            if n == 3 {
                // 3 不会被打印，因为 taps.send(3) 之后才触发 isReady.send()
                isReady.send()
            }
        }
        
        /**
         打印结果：
         drop(untilOutputFrom:): receive subscription: (DropUntilOutput)
         drop(untilOutputFrom:): request unlimited
         drop(untilOutputFrom:): receive value: (4)
         sink receive 4
         drop(untilOutputFrom:): receive value: (5)
         sink receive 5
         */
    }
    
    /// 获取序列中指定个数的值，然后发出完成事件
    func prefixFunc() {
        let numbers = (1...5).publisher
        numbers
            .prefix(2)
            .print("prefix")
            .sink(receiveCompletion: { print("sink completion \($0)") },
                  receiveValue: { print("sink received \($0)")})
            .store(in: &cancellable)
        
        // 注意测试 前面2个值发送完成之后，是否立马发送 completion，实测立即发送 finished
        /**
         打印结果：
         prefix: receive subscription: (Sequence)
         prefix: request unlimited
         prefix: receive value: (1)
         sink received 1
         prefix: receive value: (2)
         sink received 2
         prefix: receive finished
         sink completion finished
         */
    }
    
    /// 获取序列中的值直到满足给定的条件，然后发出完成事件，与 drop(while:)相反
    func prefixWhileFunc() {
        (1...5).publisher
            .prefix(while: { $0 < 3})
            .print("prefix(while:)")
            .sink(receiveCompletion: { print("sink completion \($0)") },
                  receiveValue: { print("sink received \($0)")})
            .store(in: &cancellable)
        
        /**
         打印结果：
         prefix(while:): receive subscription: ([1, 2])
         prefix(while:): request unlimited
         prefix(while:): receive value: (1)
         sink received 1
         prefix(while:): receive value: (2)
         sink received 2
         prefix(while:): receive finished
         sink completion finished
         */
    }
    
    /// 获取序列中的值直到给定的序列发出值，然后发出完成事件，与 drop(untilOutputFrom:)相反
    func prefixUntilOutputFromFunc() {
        let isReady = PassthroughSubject<Void, Never>()
        let taps = PassthroughSubject<Int, Never>()
        
        taps
            .prefix(untilOutputFrom: isReady)
            .print("prefix(untilOutputFrom:)")
            .sink(receiveCompletion: { print("sink completion \($0)") },
                  receiveValue: { print("sink received \($0)")})
            .store(in: &cancellable)
        
        (1...5).forEach { n in
            taps.send(n)
            if n == 3 {
                // 3 会被打印，因为 taps.send(3) 之后才触发 isReady.send()
                isReady.send()
            }
        }
        
        /**
         打印结果：
         prefix(untilOutputFrom:): receive subscription: (Combine.Publishers.PrefixUntilOutput<Combine.PassthroughSubject<Swift.Int, Swift.Never>, Combine.PassthroughSubject<(), Swift.Never>>.Inner<Combine.Publishers.Print<Combine.Publishers.PrefixUntilOutput<Combine.PassthroughSubject<Swift.Int, Swift.Never>, Combine.PassthroughSubject<(), Swift.Never>>>.(unknown context at $1a9943820).Inner<Combine.Subscribers.Sink<Swift.Int, Swift.Never>>, Combine.PassthroughSubject<(), Swift.Never>>)
         prefix(untilOutputFrom:): request unlimited
         prefix(untilOutputFrom:): receive value: (1)
         sink received 1
         prefix(untilOutputFrom:): receive value: (2)
         sink received 2
         prefix(untilOutputFrom:): receive value: (3)
         sink received 3
         prefix(untilOutputFrom:): receive finished
         sink completion finished
         */
    }
    
    /// 在原始的publisher序列前面追加给定的值，值的类型必须与原始序列类型一致
    func prependFunc() {
        let publisher = [3, 4].publisher
        publisher
            .prepend(1, 2)
            .sink(receiveValue: { print("prepend receive \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         prepend receive 1
         prepend receive 2
         prepend receive 3
         prepend receive 4
         */
    }
    
    func prependSequenceFunc() {
        let publisher = [3, 4].publisher
        publisher
            .prepend([1, 2])
            .sink(receiveValue: { print("prepend receive \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         prepend receive 1
         prepend receive 2
         prepend receive 3
         prepend receive 4
         */
    }
    
    /**
     在原始的publisher序列前面追加给定publisher 序列中的所有值，值的类型必须与原始序列类型一致，
     ⚠️注意：如果追加的publisher是一个未完成的序列，会等新追加序列发送完成事件再发送原始序列中的值，
     ⚠️必须等待追加的publisher发送completion之后，原始的publisher序列才会发送数据
     */
    func prependPublisherFunc() {
        let publisher1 = [3, 4].publisher
        let publisher2 = PassthroughSubject<Int, Never>()
        
        publisher1
            .prepend(publisher2)
            .print("prepend")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        publisher2.send(1)
        publisher2.send(2)
//        publisher2.send(completion: .finished)
        
        /**
         打印结果：
         prepend: receive subscription: (Concatenate)
         prepend: request unlimited
         prepend: receive value: (1)
         sink receive 1
         prepend: receive value: (2)
         sink receive 2
         prepend: receive value: (3)
         sink receive 3
         prepend: receive value: (4)
         sink receive 4
         prepend: receive finished
         
         --------注释：publisher2.send(completion: .finished)--------
         prepend: receive subscription: (Concatenate)
         prepend: request unlimited
         prepend: receive value: (1)
         sink receive 1
         prepend: receive value: (2)
         sink receive 2
         */
    }
    
    func appendFunc() {
        let message = "与prepend() 类似，只是位置改为在原始序列末尾追加"
        print(message)
    }
    
    func appendSequenceFunc() {
        let message = "与prepend(Sequence) 类似，只是位置改为在原始序列末尾追加"
        print(message)
        let publisher = [1].publisher
        publisher
            .append([2, 3])
            .append(4, 5)
            .sink(receiveValue: { print("append sink \($0)") })
            .store(in: &cancellable)
        /**
         打印结果：
         append sink 1
         append sink 2
         append sink 3
         append sink 4
         append sink 5
         */
    }
    
    func appendPublisherFunc() {
        let publisher1 = [3, 4].publisher
        let publisher2 = PassthroughSubject<Int, Never>()
        
        publisher1
            .append(publisher2)
            .print("append")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        publisher2.send(1)
        publisher2.send(2)
        publisher2.send(completion: .finished)
        
        /**
         打印结果：
         append: receive subscription: (Concatenate)
         append: request unlimited
         append: receive value: (3)
         sink receive 3
         append: receive value: (4)
         sink receive 4
         append: receive value: (1)
         sink receive 1
         append: receive value: (2)
         sink receive 2
         append: receive finished
         
         -----注释：publisher2.send(completion: .finished)------
         与上面打印结果的区别是，少了append: receive finished
         ......
         sink receive 1
         append: receive value: (2)
         sink receive 2
         */
    }
    
    let start = Date()
    let deltaFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.negativePrefix = ""
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()
    var deltaTime: String {
        return deltaFormatter.string(for: Date().timeIntervalSince(start))!
    }
    /// 延迟发出元素，接受一个延迟时间参数,以及要运行的线程
    func delayForFunc() {
        let publisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
        publisher.sink { [weak self] date in
            print("origin:\t \(self?.deltaTime ?? "")\t\(date.description)")
        }
        .store(in: &cancellable)
        
        publisher.delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] date in
                print("delay:\t \(self?.deltaTime ?? "") \t\(date.description)")
            }
            .store(in: &cancellable)
        /* autoconnect() 在第一次订阅时立即连接。*/
        
        /**
         ⚠️⚠️⚠️注意：在Timer.publisher闭包中引用类实例变量， 需要引入[weak self] 防止循环引用导致定时器无法正常销毁
         打印结果（delay在2s后才打印）：
         origin:     7.4    2024-12-20 01:30:44 +0000
         origin:     8.4    2024-12-20 01:30:45 +0000
         origin:     9.4    2024-12-20 01:30:46 +0000
         delay:     9.4     2024-12-20 01:30:44 +0000
         origin:     10.4    2024-12-20 01:30:47 +0000
         delay:     10.5     2024-12-20 01:30:45 +0000
         origin:     11.4    2024-12-20 01:30:48 +0000
         delay:     11.5     2024-12-20 01:30:46 +0000
         */
    }
    
    /**
     用于调试的操作符，计算两次值发出的时间间隔，单位是纳秒(1s = 1e+9 ns)
     测量间隔
     */
    func measureIntervalFunc() {
        let publisher = PassthroughSubject<Double, Never>()
        publisher
            .measureInterval(using: DispatchQueue.main)
            .print("measureInterval")
            .sink { stride in
                //stride.magnitude -- The value of this time interval in nanoseconds.
                let time = Double(stride.magnitude) / 1000000000.0
                print("sink receive \(time)")
            }
            .store(in: &cancellable)
        
        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        publisher.send(completion: .finished)
        
        /**
         打印结果：
         measureInterval: receive subscription: (MeasureInterval)
         measureInterval: request unlimited
         measureInterval: receive value: (Stride(_nanoseconds: 2386167))
         sink receive 0.002386167
         measureInterval: receive value: (Stride(_nanoseconds: 6359291))
         sink receive 0.006359291
         measureInterval: receive value: (Stride(_nanoseconds: 29709))
         sink receive 2.9709e-05
         measureInterval: receive finished
         */
    }
    
    /**
     超出给定的时间后发出结束事件，你可以给出自定义错误类型，这样在超时后会发出错误完成事件
     常见场景
     网络请求超时处理：设置网络请求的超时时间，确保及时处理请求的超时情况。
     用户操作限时处理：在某些情况下，限定用户在一定时间内完成某个操作，超时则取消操作。
     定时任务：对于定时任务，可以使用timeout确保任务在规定时间内完成。
     */
    func timeoutFunc() {
        // 定时器作为发布者在这里无效，timeout没有作用
//        let publisher = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
        let publisher = Just("Test").delay(for: .seconds(5), scheduler: DispatchQueue.main)
        publisher.timeout(.seconds(3), scheduler: DispatchQueue.main)
            .print("timeout")
            .sink(receiveCompletion: { print("sink completion \($0)") },
                  receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         timeout: receive subscription: (Timeout)
         timeout: request unlimited
         timeout: receive finished
         sink completion finished
         
         --------如果发布者改为 Timer.Publisher----------
         timeout: receive subscription: (Timeout)
         timeout: request unlimited
         timeout: receive value: (2024-12-20 05:44:53 +0000)
         sink receive 2024-12-20 05:44:53 +0000
         timeout: receive value: (2024-12-20 05:44:54 +0000)
         sink receive 2024-12-20 05:44:54 +0000
         ..........................................................................
         ......一直打印时间，并不会在3s后终止............
         ..........................................................................
         */
    }
    
    /// 发出原始序列中的最小值，然后发出完成事件。 要求序列是已完成的序列否则会等待原始序列的完成事件。
    func minFunc() {
        let publisher = PassthroughSubject<Int, Never>()
        publisher
            .min()
            //.min(by: <#T##(Int, Int) -> Bool#>)
            //.min(by: <#T##(Publishers.Sequence<[Int], Never>.Output, Publishers.Sequence<[Int], Never>.Output) -> Bool#>)
            .print("min")
            .sink { value in
                print("sink receive \(value)")
            }
            .store(in: &cancellable)
    
        publisher.send(4)
        publisher.send(5)
        publisher.send(1)
        publisher.send(3)
        publisher.send(2)
        //需要序列发送完成，才会触发 min 或者 max
        //publisher.send(completion: .finished)
        
        /**
         打印结果：
         min: receive subscription: (Comparison)
         min: request unlimited
         min: receive value: (1)
         sink receive 1
         min: receive finished
         
         -------没有publisher.send(completion: .finished)--------
         min: receive subscription: (Comparison)
         min: request unlimited
         */
    }
    
    /// 与min相反，发出原始序列中的最大值，然后发出完成事件。 要求序列是已完成的序列否则会等待原始序列的完成事件。
    func maxFunc() {
        let publisher = [4,5,1,3,2].publisher
//        let publisher = PassthroughSubject<Int, Never>()
        publisher
            .max()
            .print("max")
            .sink { value in
                print("sink receive \(value)")
            }
            .store(in: &cancellable)
        
//        publisher.send(4)
//        publisher.send(5)
//        publisher.send(1)
        //需要序列发送完成，才会触发 min 或者 max
//        //publisher.send(completion: .finished)
        
        /**
         打印结果：
         max: receive subscription: (Optional)
         max: request unlimited
         max: receive value: (5)
         sink receive 5
         max: receive finished
         */
    }
    
    /// 发出原始序列中的第一个值，然后发出完成事件
    func firstFunc() {
        // 看前面的方法 firstLastWhere()，功能类似，一个带条件，一个不带
    }
    
    /// 与first相反，发出原始序列中的最后一个值，然后发出完成事件。 要求序列是已完成的序列否则会等待原始序列的完成事件。
    func lastFunc() {
        // 看前面的方法 firstLastWhere()，功能类似，一个带条件，一个不带
    }
    
    /**
     output（at:）发出指定位置的值，output（in:）发出指定范围内的值。
     接收指定位置或指定范围内值之后，取消并结束管道
     注意不管是位置还是范围，下标都是从 0 开始！
     */
    func outputInAtFunc() {                                                              let publisher = ["A", "B", "C", "D", "E"].publisher
        publisher
            .print("output")
            //.output(at: 2)
            .output(in: 1...3)
            .sink(receiveCompletion: { print("sink completion \($0)") },
                  receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        // .print("output") 换位置看看打印结果
        /**
         打印结果:
         output: receive subscription: (["A", "B", "C", "D", "E"])
         output: request unlimited
         output: receive value: (A)
         output: request max: (1) (synchronous)
         output: receive value: (B)
         sink receive B
         output: receive value: (C)
         sink receive C
         output: receive value: (D)
         sink receive D
         output: receive cancel
         sink completion finished
         
         ------.output(at: 2)------
         output: receive subscription: (["A", "B", "C", "D", "E"])
         output: request unlimited
         output: receive value: (A)
         output: request max: (1) (synchronous)
         output: receive value: (B)
         output: request max: (1) (synchronous)
         output: receive value: (C)
         sink receive C
         output: receive cancel
         sink completion finished
         */
    }
    
    /**
     记录原始序列发出值的个数，并发出结果，和min,max一样，要求原始序列是已完成的序列
     不然系统不确定序列是否结束，可能还有数据再发送，导致无法统计
     count(): A publisher that consumes all elements [until the upstream publisher finishes], then emits a single value with the total number of elements received.
     */
    func countFunc() {
        (1...10).publisher
            .count()
            .print("count")
            .sink(receiveCompletion: { print("sink completion \($0)") },
                  receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         count: receive subscription: (Just)
         count: request unlimited
         count: receive value: (10)
         sink receive 10
         count: receive finished
         sink completion finished
         */
    }
  
    /**
     原始publisher发出指定值，则contains运算符将发出true并取消订阅； 如果原始publisher已完成且发出的值均不等于指定值，则发出false
     ⚠️⚠️⚠️注意看下面的两种不同发布者及打印结果示例
     */
    func containsFunc() {
        let publisher = [1,2,3,4,5].publisher
//        let publisher = PassthroughSubject<Int, Never>()
        publisher
            //.contains(3)
            .contains(where: { $0 == 5 })
            .print("contains")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
//        publisher.send(1)
//        publisher.send(2)
//        publisher.send(3)
//        publisher.send(4)
//        publisher.send(5)
//        //publisher.send(completion: .finished)
        
        /**
         打印结果：
         contains: receive subscription: (Once)
         contains: request unlimited
         contains: receive value: (true)
         sink receive true
         contains: receive finished
         
         -----------.contains(where: { $0 == 7 })-----------
         // ⚠️⚠️⚠️let publisher = PassthroughSubject<Int, Never>()，没有返回false，也没有【完成事件】
         contains: receive subscription: (ContainsWhere)
         contains: request unlimited
         // 如果条件改为 .contains(where: { $0 == 5 })，则和下面的打印结果一样
         
         // 更换成 [1,2,3,4,5].publisher，无包含返回false，并【结束事件】
         contains: receive subscription: (Once)
         contains: request unlimited
         contains: receive value: (false)
         sink receive false
         contains: receive finished
         
         结论：发布者的事件完整，才会有完成事件，如果不完整，contains会等待事件完整后才会开始判断；
         如果contains判断刚好在发布者发出的事件范围内，即使不完整，仍有完成事件
         */
    }
    
    /// 与标准库函数类似，在原始publisher完成时发出累计计算到的值
    func reduceFunc() {
        let publisher = [1,2,3,4,5].publisher
        publisher
            .reduce(0, +)
            .reduce(0) { sum, item in
                return sum + item
            }
            .print("reduce")
            .sink(receiveValue: { print("sink receive \($0)") })
            .store(in: &cancellable)
        
        /**
         打印结果：
         reduce: receive subscription: (Once)
         reduce: request unlimited
         reduce: receive value: (15)
         sink receive 15
         reduce: receive finished
         */
    }
}

struct Chatter {
    var name: String
    var message = CurrentValueSubject<String, Never>("")
    
    init(name: String, message: String) {
        self.name = name
        self.message.value = message
    }
}

struct FlatMapTestModel: Decodable {
    let id: Int
}
