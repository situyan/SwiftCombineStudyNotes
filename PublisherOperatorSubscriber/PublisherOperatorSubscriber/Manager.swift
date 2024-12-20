//
//  Manager.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/2.
//

/**
 https://heckj.github.io/swiftui-notes/index_zh-CN.html
 https://blog.csdn.net/zgpeace/article/details/136071871?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-1-136071871-blog-136070004.235%5Ev43%5Epc_blog_bottom_relevance_base2&spm=1001.2101.3001.4242.2&utm_relevant_index=4
 https://blog.csdn.net/ZCC361571217/article/details/143609965
 http://chenru.cn/16561664137193.html
 https://www.cnblogs.com/jerrywossion/p/18168777（看这个先看上面两个链接内容， 然后再看这个）
 
 操作符：
 https://zhuanlan.zhihu.com/p/649661331
 https://www.jianshu.com/p/1dc27229a533
 https://blog.csdn.net/guoyongming925/article/details/139843749
 https://juejin.cn/post/7220251777685913659
 https://blog.csdn.net/ZCC361571217/article/details/143609965
 https://www.jb51.net/article/270977.htm
 较全较详细的操作符：
 https://www.cnblogs.com/ficow/p/13788610.html
 https://www.jianshu.com/p/4058823d1bba
 https://www.jianshu.com/p/ead547fbcc0a
 https://www.jianshu.com/p/d6cc55ac967a（还未看-，二，三，四，目前只细看了三）
 Foundation中常用的Publisher：https://www.jianshu.com/p/9adfe39aa36f
 调度程序、线程队列相关（Scheduler Operator）：
 https://www.jb51.net/article/270967.htm
 
 SwiftUI：
 https://blog.csdn.net/guoyongming925/category_10614298_2.html
 https://fatbobman.com/zh/
 List列表组件不流畅问题：https://zhuanlan.zhihu.com/p/196608723
 实战：
 https://zhuanlan.zhihu.com/p/268680841
 UIKit 和 SwiftUI 混编：
 https://blog.csdn.net/qq_39653624/article/details/143710458
 
 好博客：
 https://www.cnblogs.com/ficow
 https://www.zhihu.com/column/c_1264596761944944640
 https://www.jianshu.com/u/4a071a8e3fc3
  
 使用 Swift Package Manager 集成依赖库：
 https://www.cnblogs.com/ficow/p/13722258.html
 
 GItHub个人首页版面排版：
 https://www.cnblogs.com/ficow/p/13716256.html
 
 Kodeco（技术很新的国外学习网站）：
 https://www.kodeco.com/ios/paths/learn
 https://www.kodeco.com/29934862-sharing-core-data-with-cloudkit-in-swiftui/page/2
  ------------------------------------------------
  ------------------------------------------------
  ------------------------------------------------
  ⚠️⚠️⚠️在发布者、操作符及订阅者的闭包中使用自定义变量时，需要 [weak self] 防止相互循环引用！！！
  因为发布者、订阅者也会被设置为变量被VC持有，而自定义变量也被VC持有，且在闭包中使用，所以必须要 [weak self]，【实测结果】
 
 注意一些Publisher如果没有被订阅，那么发出的值不会保留而是直接丢弃
  ------------------------------------------------
  ------------------------------------------------
  ------------------------------------------------
 
 待实测确认（对照所写的方法）：
 使用 flatMap 和 catch 在不取消管道的情况下处理错误
 使用 catch 处理一次性管道中的错误
 assign订阅者要求管道中返回的失败类型是<Never>，sink不需要但接收到Error时，会给管道发生终止信号，
 从而导致管道的后续处理都被停止（实际测试验证时后续还是所有的）
 receive(on:),  subscribe(on:)
 
 管道中如果有 nil，并不会传递到订阅者，而是被过滤了，所以用数组（空元素）（实际测试看看）
 retrieveGithubUser 方法
 
 headingPublisher.send(completion: Subscribers.Completion.failure(error)) 中 Error没有处理
 */

import UIKit
import Combine
import Contacts

fileprivate struct PostmanEchoTimeStampCheckResponse: Decodable, Hashable {
    let valid: Bool
}

class POSManager {
    static let obj = POSManager()
    
    var cancellable: AnyCancellable? = nil
    var dataTaskSink: AnyCancellable? = nil
    var dataTaskPublisher: URLSession.DataTaskPublisher? = nil
    let myURL = URL(string: "https://postman-echo.com/time/valid?timestamp=2016-10-10")!
    
    //MARK: - 订阅者 sink
    func sinkFunc() {
        let _ = Future<Int, Never> { promise in
            promise(.success(0))
        }
        let _ = [1,2,3,4,5].publisher
        
        let publishingSource1 = Just(5)
        let cancellablePipeline1 = publishingSource1.sink { someValue in
            print(".sink() received \(someValue)")
        }
        
        let publishingSource2 = Future<Bool, Error> { promise in
            CNContactStore().requestAccess(for: .contacts) { grantedAccess, error in
                if let err = error {
                    promise(.failure(err))
                }
                return promise(.success(grantedAccess))
            }
        }
        let cancellablePipeline2 = publishingSource2.sink { completion in
            switch completion {
            case .finished:
                print("access result is end")
                break
            case .failure(let err):
                print("access result received the error: \(err)")
                break
            }
        } receiveValue: { someValue in
            print("access status, .sink() received \(someValue)")
        }
        
        cancellablePipeline2.cancel()
    }
    
    //MARK: 订阅者 assign
    func assignFunc() {
        /*
         Assign 要求将失败类型指定为 <Never>，因此，如果你的管道可能失败（例如使用 tryMap 等操作符），则需要在使用 .assign 之前 错误处理。
         */
//        let publishingSource = Future<Bool, Error>{ promise in
//            CNContactStore().requestAccess(for: .contacts) { grantedAccess, error in
//                if let err = error {
//                    promise(.failure(err))
//                    return;
//                }
//                promise(.success(grantedAccess))
//            }
//        }
        
        let publishingSource = Just(false)
        let theButton = UIButton()
        let cancellablePipeline = publishingSource
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: theButton)
    }
    
    //MARK: - 网络请求发布者
    func dataTaskPublisher1() {
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: myURL)
            .map({ $0.data })
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
        
        dataTaskSink = remoteDataPublisher
            .sink { completion in
                switch completion {
                case .finished:
                    // 无网络情况不会走到这里
                    //print(".sink() received the completion", String(describing: completion))
                    break
                case .failure(let error):
                    // 无网络情况会走到这里
                    print(".sink() request received error: ", error)
                }
            } receiveValue: { someValue in
                print(".sink() received \(someValue), \(someValue.valid)")
            }
    }
    
    /**
     要对 URL 响应中被认为是失败的操作进行更多控制，可以对 dataTaskPublisher 的元组响应使用 tryMap 操作符。 由于 dataTaskPublisher 将响应数据和 URLResponse 都返回到了管道中，你可以立即检查响应，并在需要时抛出自己的错误。
     使用 tryMap，这使我们能够根据返回的内容识别并在管道中抛出错误。
     */
    func dataTaskPublisher2() {
        let myURL = URL(string: "https://postman-echo.com/time/valid?timestamp=2016-10-10")!
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: myURL)
            .tryMap({ data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "com.urlsession.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "invalid server response"])
                }
                return data
            })
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
        
        dataTaskSink = remoteDataPublisher
            .sink { completion in
                switch completion {
                case .finished:
                    // 无网络情况不会走到这里
                    //print(".sink() received the completion", String(describing: completion))
                    break
                case .failure(let error):
                    // 无网络情况会走到这里
                    print(".sink() request received error: ", error)
                }
            } receiveValue: { someValue in
                print(".sink() received \(someValue), \(someValue.valid)")
            }
    }
    
    /**
     当在管道上触发错误时，不管错误发生在管道中的什么位置，都会发送 .failure 完成回调，并把错误封装在其中。

     此模式可以扩展来返回一个发布者，该发布者使用此通用模式可接受并处理任意数量的特定错误。 在许多示例中，我们用默认值替换错误条件。 如果我们想要返回一个发布者的函数，该发布者不会根据失败来选择将发生什么，则同样 tryMap 操作符可以与 mapError 一起使用来转换响应对象以及转换 URLError 错误类型。
     
     使用 mapError 将任何其他不可忽视的错误类型转换为通用的错误类型 APIError。
     */
    enum APIError: Error, LocalizedError {
        case unknown, apiError(reason: String), parserError(reason: String), networkError(from: URLError)
        
        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error"
            case .apiError(let reason), .parserError(let reason):
                return reason
            case .networkError(let from):
                return from.localizedDescription
            }
        }
    }
    
    func dataTaskPublisher3() {
        /**
         ⚠️⚠️ URLSession请求在无网络或其他未知情况下，不会返回Data，URLResponse，直接返回Error
         */
//        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "")!)) { <#Data?#>, <#URLResponse?#>, <#(any Error)?#> in
//            <#code#>
//        }
        
        /**
         打印：.sink() request received error:  apiError(reason: "Resource not found")
         正确URL："https://postman-echo.com/time/valid?timestamp=2016-10-10"
         */
        let request = URLRequest(url: URL(string: "https://postman-echo.com/time/valids?timestamp=2016-10-10")!)
        var remoteDataPublisher: AnyPublisher<PostmanEchoTimeStampCheckResponse, APIError>? = nil
        remoteDataPublisher = URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryMap { data, response in
                // 我们将路由到 tryMap 操作符来检查响应，根据服务器响应创建特定的错误。
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                if httpResponse.statusCode == 401 {
                    throw APIError.apiError(reason: "Unauthorized")
                }
                if (httpResponse.statusCode == 403) {
                    throw APIError.apiError(reason: "Resource forbidden")
                }
                if (httpResponse.statusCode == 404) {
                    throw APIError.apiError(reason: "Resource not found")
                }
                if (405..<500 ~= httpResponse.statusCode) {
                    throw APIError.apiError(reason: "client error")
                }
                if 500..<600 ~= httpResponse.statusCode {
                    throw APIError.apiError(reason: "server error")
                }
                return data
            }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .mapError { error in
                // 我们使用 mapError 将任何其他不可忽视的错误类型转换为通用的错误类型 APIError。
                if let error = error as? APIError {
                    return error
                }
                // .networkError 是 APIError 的一个特定情况，当 URLSession.dataTaskPublisher 返回错误时我们将把错误转换为该类型。
                if let urlError = error as? URLError {
                    return APIError.networkError(from: urlError)
                }
                return APIError.unknown
            }
            .eraseToAnyPublisher()
        
        dataTaskSink = remoteDataPublisher?
            .sink { completion in
                switch completion {
                case .finished:
                    // 无网络情况不会走到这里
                    //print(".sink() received the completion", String(describing: completion))
                    break
                case .failure(let error):
                    // 无网络情况会走到这里
                    print(".sink() request received error: ", error)
                }
            } receiveValue: { someValue in
                print(".sink() received \(someValue), \(someValue.valid)")
            }
    }
    
    //MARK: Future发布者
    func futurePublisher() {
        /**
         Future 在创建时【立即发起其中异步 API 的调用】，而不是 当它收到订阅需求时。 这可能不是你想要或需要的行为。 如果你希望在订阅者请求数据时再发起调用，你可能需要用 Deferred 来包装 Future。
         实测：Future创建后，内部代码直接运行，不需要sink订阅，所以用Deferred控制以延迟运行
         Deferred创建延迟发布者（没有可设置延迟参数的地方，可以这样做--下面）
         */
        let deferedFuturePublisher = Deferred {
            let futureAsyncPublisher = Future<Bool, Error> { promise in
                CNContactStore().requestAccess(for: .contacts) { grantedAccess, error in
                    if let error = error {
                        return promise(.failure(error))
                    }
                    return promise(.success(grantedAccess))
                }
            }.eraseToAnyPublisher()
            return futureAsyncPublisher
        }
        
        cancellable = deferedFuturePublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("contacts access end")
                case .failure(let failure):
                    print("contact access failed, ", failure)
                }
            }, receiveValue: { someValue in
                print("contact access result ", someValue)
            })
        
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
        
        let _ = delayPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("sink completion")
                case .failure(let error):
                    print("sink fail, ", error)
                }
            } receiveValue: { value in
                print("sink value \(value)")
            }
    }
    
    //MARK: - 错误处理
    /**
     如果你需要在管道内处理失败，例如在使用 assign 操作符或其他要求失败类型为 <Never> 的操作符之前，你可以使用 catch 来提供适当的逻辑。
     
     catch 处理错误的方式，是将上游发布者替换为另一个发布者，这是你在闭包中用返回值提供的。
     ⚠️⚠️⚠️请注意，这实际上终止了管道（因为发布者被替换了，且非持续性--闭包中提供）。 如果你使用的是一次性发布者（不创建多个事件），那这就没什么。
     
     ⚠️⚠️⚠️此技术的一个可能问题是，如果你希望原始发布者生成多个响应值，但使用 catch 之后原始管道就已结束了。
     如果你正在创建一条对 @Published 属性做出响应的管道，那么在任何失败值激活 catch 操作符之后，管道将不再做出进一步响应
     */
    func catchOnceErrorFunc() {
        struct IPInfo: Codable {
            var ip: String
        }
        let myURL = URL(string: "http://ip.jsontest.com")!
        
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: myURL)
            .map { data, response in
                return data
            }
            .decode(type: IPInfo.self, decoder: JSONDecoder())
            .catch { error in
                /**
                 在 catch操作符闭包中捕获错误，并返回一个一次性的发布者，效果：当请求和解析出错时，提供默认值。
                 通常，catch 操作符将被放置在几个可能失败的操作符之后，以便在之前任何可能的操作失败时提供回退或默认值。
                 Just 发布者经常用于启动另一个一次性管道，或在发生失败时直接提供默认的响应。
                 弊端：使用 catch 之后原始管道就已结束了，
                 原始管道之后的输出数据到不了订阅者（需要实际测试验证--持续性输出+随机错误，看结果值）
                 */
                return Just(IPInfo(ip: "1.1.1.1"))
            }
            .eraseToAnyPublisher()
        
    }
    
    /**
     在发生暂时失败时重试
     
     当 retry 收到 .failure 结束事件时，它重试的方式：【是给它所链接的操作符或发布者重新创建订阅。】
     ⚠️⚠️⚠️ retry验证你请求的 URL 如果反复请求或重试，是否会产生副作用
     */
    func retryOperatorFunc() {
        /**
         当向 dataTaskPublisher 请求数据时，请求可能会失败。 在这种情况下，你将收到一个带有 error 的 .failure 事件。 当失败时，retry 操作符将允许你对相同请求进行一定次数的重试。 当发布者不发送 .failure 事件时，retry 操作符会传递结果值。 retry 仅在发送 .failure 事件时才在 Combine 管道内做出响应。
         
         在下面的示例中，我们将 retry 与 delay 操作符相结合使用。 我们使用延迟操作符在下一个请求之前使其出现少量随机延迟。 这使得重试的尝试行为被分隔开，使重试不会快速连续的发生。
         
         此示例还包括使用 tryMap 操作符以更全面地检查从 dataTaskPublisher 返回的任何 URL 响应。 服务器的任何响应都由 URLSession 封装，并作为有效的响应转发。 URLSession 不将 404 Not Found 的 http 响应视为错误响应，也不将任何 50x 错误代码视作错误。 使用 tryMap，我们可检查已发送的响应代码，并验证它是 200 的成功响应代码。 在此示例中，如果响应代码不是 200 ，则会抛出一个异常 —— 这反过来又会导致 tryMap 操作符传递 .failure 事件，而不是数据。
         此示例将 tryMap 设置在 retry 操作符 之后，以便【仅在网站未响应时重新尝试请求。】，而非code != 200时
         URLSession结果分三种：错误响应，正确响应=200响应 + 非200响应（需要自行处理，可通过tryMap抛出异常）
         
         -------------------------------------
         -------------------------------------
         delay 操作符将流经过管道的结果保持一小段时间，在这个例子中随机选择1至5秒。 通过在管道中添加延迟，即使原始请求成功，重试也始终会发生。 重试被指定为尝试3次。 如果每次尝试都失败，这将导致总共 4 次尝试 - 原始请求和 3 次额外尝试。
         tryMap 被用于检查 dataTaskPublisher 返回的数据，如果服务器的响应数据有效，但不是 200 HTTP 响应码，则返回 .failure 完成事件。
         */
        let myURL = URL(string: "http://ip.jsontest.com")!
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: myURL)
            .delay(for: DispatchQueue.SchedulerTimeType.Stride(integerLiteral: Int.random(in: 1...4)), scheduler: DispatchQueue.global(qos: .background))
            .retry(3)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "com.xxxcombine.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Server Response"])
                }
                return data
            }
            .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
            .subscribe(on: DispatchQueue.global(qos: .background))
            .eraseToAnyPublisher()
    }
    
    /**
     使用 flatMap 和 catch 在不取消管道的情况下处理错误
     
     flatMap 操作符可以与 catch 一起使用，以持续处理新发布的值上的错误。
     flatMap 是用于处理持续事件流中错误的操作符。
     
     你提供一个闭包给 flatMap，该闭包可以获取所传入的值，并创建一个一次性的发布者，完成可能失败的工作。 这方面的一个例子是从网络请求数据，然后将其解码。 你可以引入一个 catch 操作符，以捕获任何错误并提供适当的值。

     当你想要保持对上游发布者的更新时，这是一个完美的机制，因为它创建一次性的发布者或短管道，发送一个单一的值，然后完成每一个传入的值。 所创建的一次性发布者的完成事件在 flatMap 中终止，并且不会传递给下游订阅者。
     */
    func tryMapCatchFunc() {
        /**
         Just 以传入一个 URL 作为示例启动此发布者。
         flatMap 以 URL 作为输入，闭包继续创建一次性发布者管道。
         dataTaskPublisher 使用输入的 url 发出请求。
         输出的结果（一个 (Data, URLResponse) 元组）流入 tryMap 以解析其他错误。
         decode 尝试将返回的数据转换为本地定义的类型。
         如果其中任何一个失败，catch 将把错误转换为一个默认的值。 在这个例子中，是具有预设好 valid = false 属性的对象。
         */
        let remoteDataPublisher = Just(myURL)
            .flatMap { url in
                URLSession.shared.dataTaskPublisher(for: url)
                    .tryMap { data, response in
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            throw NSError(domain: "com.xxxcombine.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "invalid Server Response"])
                        }
                        return data
                    }
                    .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
                    .catch { error in
                        // catch 捕获上面URLSession请求的非响应错误、响应非200错误、data解析错误， 并将错误转换为一个默认值发布者输出
                        return Just(PostmanEchoTimeStampCheckResponse(valid: false))
                    }
            }
            .eraseToAnyPublisher()
    }
    
    /**
     网络受限时从备用 URL 请求数据
     
     在 Apple 的 WWDC 2019 演示 Advances in Networking, Part 1 中，使用 tryCatch 和 tryMap 操作符提供了示例模式，以响应网络受到限制的特殊错误。
     
     在苹果的 WWDC 中的这个例子，提供了一个函数，接受两个 URL 作为参数 —— 一个主要的 URL 和一个备用的URL。 它会返回一个发布者，该发布者将请求数据，并在网络受到限制时向备用 URL 请求数据。
     */
    func adaptiveLoaderFunc(regularURL: URL, lowDataURL: URL) -> AnyPublisher<Data, Error> {
        /**
         测试实例：ViewController -- tryCatchTryMapAction
         request 变量是一个尝试请求数据的 URLRequest。
         设置 request.allowsConstrainedNetworkAccess 将导致 dataTaskPublisher 在网络受限时返回错误。
         调用 dataTaskPublisher 发起请求。
         tryCatch 用于捕获当前的错误状态并检查特定错误（受限的网络）。
         如果它发现错误--受限的网络，它会使用备用 URL 创建一个新的一次性发布者。
         由此产生的发布者仍可能失败，tryMap 可以基于对应到错误条件的 HTTP 响应码来抛出错误，将此映射为失败。
         eraseToAnyPublisher 可在操作符链上进行类型擦除，因此 adaptiveLoader 函数的返回类型为 AnyPublisher<Data, Error>。
         
         在示例中，如果从原始请求返回的错误不是网络受限的问题，则它会将 .failure 结束事件传到管道中。 如果错误是网络受限，则 tryCatch 操作符会创建对备用 URL 的新请求。
         
         ⚠️⚠️⚠️ 如果regular 请求没有非响应错误，不会进入 tryCatch，而是直接进入 tryMap
         */
        var request = URLRequest(url: regularURL)
        request.allowsConstrainedNetworkAccess = false
        return URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryCatch { error in
                guard error.networkUnavailableReason == .constrained else {
                    print("not network unavailable constrained")
                    throw error
                }
                print("will requet low data url")
                return URLSession.shared.dataTaskPublisher(for: lowDataURL)
            }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw NSError(domain: "com.xxxcombine.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Server Response"])
                }
                return data
            }
            .eraseToAnyPublisher()
    }
}
