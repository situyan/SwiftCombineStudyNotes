//
//  GithubViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/4.
//

/**
 【主体功能和思路】：
 功能：输入框输入用户名称，查询出用户信息，在根据用户信息显示器仓库数和头像
 思路：
 虽然我们可以在更新 UI 元素时简单地将管道连接到它们，但这使得和实际的 UI 元素本身耦合更紧密。 虽然简单而直接，但创建明确的状态，以及分别对用户行为和数据做出更新是一个好的建议，这更利于调试和理解。 在上面的示例中，我们使用两个 @Published 属性来保存与当前视图关联的状态。 其中一个由 IBAction 更新（username），第二个使用 Combine 发布者管道以声明的方式更新（githubUserData）。 所有其他的 UI 元素都依赖这些属性的发布者更新时 进行更新。
 */

import UIKit
import Combine

class GithubAvatarImageViewC {
    var image = UIImage()
}

class GithubViewController: UIViewController {
    @IBOutlet weak var github_id_entry: UITextField!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var repositoryCountLabel: UILabel!
    @IBOutlet var githubAvatarImageView: UIImageView!
    var githubAvatarImageViewC = GithubAvatarImageViewC()
    
    var repositoryCountSubscriber: AnyCancellable?
    var avatarViewSubscriber: AnyCancellable?
    var usernameSubscriber: AnyCancellable?
    var apiNetworkActivitySubscriber: AnyCancellable?
    
    // @Published 属性，既能保存数据，又能响应更新。 因为它是一个 @Published 属性，它提供了一个发布者，我们可以使用 Combine 的管道更新界面的其他变量或元素。
    @Published var username: String = ""
    @Published private var githubUserData: [GithubAPIUser] = []
    
    var myBackgroundQueue: DispatchQueue = .init(label: "myBackgroundQueue")
    // let coreLocationProxy = LocationHeadingProxy()
        
    //MARK: - 输入GitHubId
    // 我们从 IBAction 内部设置变量 username，如果发布者 $username 有任何订阅者，它反过来就会触发数据流更新。
    @IBAction func githubIdChanged(_ sender: UITextField) {
        username = sender.text ?? ""
        print("Set username to ", username)
    }
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // KVO publisher of UIKit interface element
        let _ = repositoryCountLabel.publisher(for: \.text)
            .sink { someValue in
                print("repositoryCountLabel update to \(String(describing: someValue))")
            }
        
        // https://heckj.github.io/swiftui-notes/index_zh-CN.html#patterns-merging-streams-interface
        /**
         UITextField 是从用户交互推动更新的界面元素。
         我们定义了一个 @Published 属性，既能保存数据，又能响应更新。 因为它是一个 @Published 属性，它提供了一个发布者，我们可以使用 Combine 的管道更新界面的其他变量或元素。
         我们从 IBAction 内部设置变量 username，如果发布者 $username 有任何订阅者，它反过来就会触发数据流更新。
         我们又在发布者 $username 上设置了一个订阅者，以触发进一步的行为。 在这个例子中，它使用更新过的 username 的值从 Github 的 REST API 取回一个 GithubAPIUser 实例。 每次更新用户名值时，它都会发起新的 HTTP 请求。
         throttle 在这里是防止每编辑一次 UITextField 都触发一个网络请求。 throttle 操作符保证了每半秒最多可发出 1 个请求。
         removeDuplicates 移除重复的更改用户名事件，以便不会连续两次对相同的值发起 API 请求。 如果用户结束编辑时返回的是之前的值，removeDuplicates 可防止发起冗余请求。
         map 在此处和 flatMap 处理错误类似，返回一个发布者的实例。 在 map 被调用时，API 对象返回一个发布者。 它不会返回请求的值，而是返回发布者本身。
         -----switchToLatest 核心思想是保留最后一个publisher，特别适合用于过滤搜索框的多余的网络请求（比如此处的
         通过输入名称搜索个人信息，新输入产生的新搜索请求才会被保留）----
         switchToLatest 操作符接收发布者实例并解析其中的数据。 switchToLatest 将发布者解析为值，并将该值传递到管道中，在这个例子中，是一个 [GithubAPIUser] 的实例。
         在管道末尾的 assign 是订阅者，它将值分配到另一个变量：githubUserData。
         */
        usernameSubscriber = $username
            .throttle(for: 0.5, scheduler: myBackgroundQueue, latest: true)
            .removeDuplicates()
            .print("username pipeline: ")
            .map({ username in
                return GithubAPI.retrieveGithubUser(username: username)
            })
            .switchToLatest()
            .receive(on: RunLoop.main)
            .assign(to: \.githubUserData, on: self)
                
        /**
         -------------------------------
         assign订阅者要求管道中返回的失败类型是<Never>，sink不需要但接收到Error时，会给管道发生终止信号，
         从而导致管道的后续处理都被停止（实际测试）
         为了让 UI 在 @Published 属性发送的更改事件中不断更新，我们希望确保任何配置的管道都具有 <Never> 的失败类型。 这是 assign 操作符所必需的。 当使用 sink 操作符时，它也是一个潜在的 bug 来源。 如果来自 @Published 变量的管道以一个接受 Error 失败类型的 sink 结束，如果发生错误，sink 将给管道发送终止信号。 这将停止管道的任何进一步处理，即使有变量仍然被更新。
         -------------------------------
         
         -------------------------------
         subscribe, receive 操作符将管道中操作分配到不同线程中，以实现其他线程上订阅，主线程上接收，既不影响数据处理也不影响UI响应：
         管道使用 subscribe 操作符明确配置在后台队列中工作。 如果没有该额外的配置，管道将被在主线程调用并执行，因为它们是从 UI 线程上调用的，这可能会导致用户界面响应速度明显减慢。
         同样，当管道的结果分配给或更新 UI 元素时，receive 操作符用于将该工作转移回主线程。
         -------------------------------
         */
        
        /**
         这几处的订阅依赖：username 发布者及 其请求的结果 GitHubUserData 发布者，handleEvents
         订阅收到数据后，更新UI（检查发布者发出的数据是否在主线程上，如果不是回到主线程 receive）
         */
        apiNetworkActivitySubscriber = GithubAPI.networkActivityPublisher
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("network request end")
                self.activityIndicator.stopAnimating()
            }, receiveValue: { requesting in
                if requesting {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
            })
        
        /**
         第一个订阅者连接在发布者 $githubUserData 上。 此管道提取用户仓库的个数并更新到 UILabel 实例上。 当列表为空时，管道中间有一些逻辑来返回字符串 “unknown”。
         */
        repositoryCountSubscriber = $githubUserData
            .print("github user data: ")
            .map({ userDatas in
                if let user = userDatas.first {
                    return "\(user.public_repos)"
                }
                return "unknown"
            })
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: repositoryCountLabel)
        
        /**
         第二个订阅者也连接到发布者 $githubUserData。 这会触发网络请求以获取 github 头像的图像数据。 这是一个更复杂的管道，从 githubUser 中提取数据，组装一个 URL，然后请求它。 我们也使用 handleEvents 操作符来触发对我们视图中的 activityIndi​​cator 的更新。 【我们使用 subscribe 在后台队列上发出请求，然后将结果传递回主线程以更新 UI 元素】。 catch 和失败处理在失败时返回一个空的 UIImage 实例。
         */
        avatarViewSubscriber = $githubUserData
            .print("github user data: ")
            .map({ userDatas -> AnyPublisher<UIImage, Never> in
                guard let avatar = userDatas.first?.avatar_url,
                      let url = URL(string: avatar) else {
                    return Just(UIImage()).eraseToAnyPublisher()
                }
                
                let avatarPublisher = URLSession.shared.dataTaskPublisher(for: url)
                    .handleEvents { Subscription in
                        DispatchQueue.main.async {
                            self.activityIndicator.startAnimating()
                        }
                    } receiveCompletion: { completion in
                        DispatchQueue.main.async {
                            self.activityIndicator.startAnimating()
                        }
                    } receiveCancel: {
                        DispatchQueue.main.async {
                            self.activityIndicator.startAnimating()
                        }
                    }
                    .map { data, response in
                        return UIImage(data: data) ?? UIImage()
                    }
                    .subscribe(on: self.myBackgroundQueue)
                    // githubUserData 的生成是在主线程中，所以此处需要在后台线程请求处理数据
                    .catch { error in
                        return Just(UIImage())
                    }
                    .eraseToAnyPublisher()
                // ^^ match the return type here to the return type defined
                // in the .map() wrapping this because otherwise the return
                // type would be terribly complex nested set of generics.
                
                // 没有返回，会导致后面的类型都不对
                return avatarPublisher
            })
        //这里放入sink({})，闭包内部打印是 main thread
            .switchToLatest()
            .subscribe(on: myBackgroundQueue)
        //这里放入sink({})，闭包内部打印是 not main thread
            .receive(on: RunLoop.main)
            // 这里就可以直接使用，不需要转换 image 未可选类型
//            .assign(to: \.image, on: githubAvatarImageViewC)
            // 将 UIImage转换成 Optional<UIImage>，因为 UIImageView的 .image 是可选类型，所以需要转换
            .map({ image -> UIImage? in
                return image
            })
            .assign(to: \.image, on: githubAvatarImageView)
        
//            .sink(receiveValue: { someValue in
        // 看看数据流向的每个阶段都在什么线程中，看看image是否是可选类型
//                print("排查问题，看是什么状态 \(someValue)")
//            })
//            .map({ image in
//                return image
//            })
//            .switchToLatest()
//            .receive(on: RunLoop.main)
//            .assign(to: \.image, on: githubAvatarImageView)
        
        
        
        /**
         Set username to  heckj
         username pipeline: : receive value: (heckj)
         Set username to  heckj
         Can't find or decode reasons
         Failed to get or decode unavailable reasons
         github user data: : receive value: ([PublisherOperatorSubscriber.GithubAPIUser(login: "heckj", id: 43388, avatar_url: "https://avatars.githubusercontent.com/u/43388?v=4", name: "Joseph Heck", location: "Seattle, WA", public_repos: 180)])
         github user data: : receive value: ([PublisherOperatorSubscriber.GithubAPIUser(login: "heckj", id: 43388, avatar_url: "https://avatars.githubusercontent.com/u/43388?v=4", name: "Joseph Heck", location: "Seattle, WA", public_repos: 180)])
         */
    }
}
