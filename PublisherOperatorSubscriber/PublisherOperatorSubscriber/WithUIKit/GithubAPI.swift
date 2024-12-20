//
//  GithubAPI.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/4.
//

import Combine
import Foundation

enum APIFailureCondition: Error, LocalizedError {
    case InvalidServerResponse
    
    var errorDescription: String? {
        switch self {
        case .InvalidServerResponse:
            return "invalid server response"
//        default:
//            return "unknown error"
//            break;
        }
    }
}

/**
  此处创建的 decodable 结构体是从 GitHub API 返回的数据的一部分。 在由 decode 操作符处理时，任何未在结构体中定义的字段都将被简单地忽略。
 */
struct GithubAPIUser: Decodable {
    //  a github API user 部分属性
    // https://api.github.com/users/heckj 看最底部的返回JSON
    
    let login: String
    let id: Int
    let avatar_url: String
    let name: String
    let location: String
    let public_repos: Int
}

enum GithubAPI {
    // 使用 passthroughSubject 暴露了一个发布者，使用布尔值以在发送网络请求时反映其状态。
    static let networkActivityPublisher = PassthroughSubject<Bool, Never>()
    
    /**
     与 GitHub API 交互的代码被放在一个独立的结构体中，我习惯于将其放在一个单独的文件中。 API 结构体中的函数返回一个发布者，然后与 ViewController 中的其他管道进行混合合并。
     */
    static func retrieveGithubUser(username: String) -> AnyPublisher<[GithubAPIUser], Never> {
        // 这里的逻辑只是为了防止无关的网络请求，如果请求的用户名少于 3 个字符，则返回空结果
        if username.count < 3 {
            return Just([]).eraseToAnyPublisher()
        }
        
        /**
         返回空列表很有用，因为当提供无效的用户名时，我们希望明确地移除以前显示的任何头像。 为此，我们需要管道始终有值可以流动，以便触发进一步的管道和相关的 UI 界面更新。 如果我们使用可选的 String? 而不是 String[] 数组，【可选的字符串不会在值是 nil 时触发某些管道，并且我们始终希望管道返回一个结果值（即使是空值）。】
         
         replaceError(with: [])
         我最开始创建了一个管道以返回一个可选的 GithubAPIUser 实例，但发现没有一种方便的方法来在失败条件下传递 “nil” 或空对象。 然后我修改了代码以返回一个列表，即使只需要一个实例，它却能更方便地表示一个“空”对象。 这对于想要在对 GithubAPIUser 对象不再存在后，在后续管道中做出响应以擦除现有值的情况很重要 —— 这时可以删除 repositoryCount 和用户头像的数据。
         */
        let assembledURL = String("https://api.github.com/users/\(username)")
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
            .handleEvents { receiveSubscription in
                /**
                 handleEvents 操作符是我们触发网络请求发布者更新的方式。 我们定义了在订阅和终结（完成和取消）时触发的闭包，它们会在 passthroughSubject 上调用 send()。 这是我们如何作为单独的发布者提供有关管道操作的元数据的示例。
                 */
                networkActivityPublisher.send(true)
            } receiveCompletion: { _ in
                networkActivityPublisher.send(false)
            } receiveCancel: {
                networkActivityPublisher.send(false)
            }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw APIFailureCondition.InvalidServerResponse
                }
                return data
            }
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
            .map({ return [$0] })
            .replaceError(with: [])
            .eraseToAnyPublisher()
        // replaceError 此管道中的错误条件，返回一个空列表，同时还将失败类型转换为 Never。
        
        return publisher
    }
}

/**
 https://api.github.com/users/heckj
 {
     "login": "heckj",
     "id": 43388,
     "node_id": "MDQ6VXNlcjQzMzg4",
     "avatar_url": "https://avatars.githubusercontent.com/u/43388?v=4",
     "gravatar_id": "",
     "url": "https://api.github.com/users/heckj",
     "html_url": "https://github.com/heckj",
     "followers_url": "https://api.github.com/users/heckj/followers",
     "following_url": "https://api.github.com/users/heckj/following{/other_user}",
     "gists_url": "https://api.github.com/users/heckj/gists{/gist_id}",
     "starred_url": "https://api.github.com/users/heckj/starred{/owner}{/repo}",
     "subscriptions_url": "https://api.github.com/users/heckj/subscriptions",
     "organizations_url": "https://api.github.com/users/heckj/orgs",
     "repos_url": "https://api.github.com/users/heckj/repos",
     "events_url": "https://api.github.com/users/heckj/events{/privacy}",
     "received_events_url": "https://api.github.com/users/heckj/received_events",
     "type": "User",
     "user_view_type": "public",
     "site_admin": false,
     "name": "Joseph Heck",
     "company": null,
     "blog": "https://rhonabwy.com/",
     "location": "Seattle, WA",
     "email": null,
     "hireable": null,
     "bio": null,
     "twitter_username": null,
     "public_repos": 180,
     "public_gists": 58,
     "followers": 574,
     "following": 227,
     "created_at": "2008-12-30T20:39:41Z",
     "updated_at": "2024-11-22T20:34:42Z"
 }
 */
