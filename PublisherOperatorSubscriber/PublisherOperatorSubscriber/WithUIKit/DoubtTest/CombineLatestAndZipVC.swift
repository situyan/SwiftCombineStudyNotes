//
//  CombineLatestAndZipVC.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/9.
//

import UIKit
import Combine

class CombineLatestAndZipVC: UIViewController {
    @IBOutlet weak var valueATextField: UITextField!
    @IBOutlet weak var valueBTextField: UITextField!
    @IBOutlet weak var combineLatestPipelineLabel: UILabel!
    @IBOutlet weak var zipPipelineLabel: UILabel!
    
    var valueAPublisher = PassthroughSubject<String?, Never>()
    var valueBPublisher = PassthroughSubject<String?, Never>()
    var cancellable: Set<AnyCancellable> = []

    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        compareCombineLatestAndZip()
        
//        // 改进TextField事件监听
//        self.valueATextField.textPublisher()
//            .assign(to: \.text, on: zipPipelineLabel)
//            .store(in: &cancellable)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //MARK: - combineLatest与zip的比较
    /**
     zip：
     需要多个管道都有新值（对称提取），合并发送
     它会把两个 (或多个) Publisher 事件序列中在同一 index 位置上的值进行合并，也就是说，Publisher1 中的第一个事件和 Publisher2 中的第一个事件结对合并，Publisher1 中的第二个事件和 Publisher2 中的第二个事件合并
     zip 操作符会按照 Publisher 发送事件的顺序，将相同位置的事件进行配对，并将这些配对后的事件发送给下游。如果有任意一个 Publisher 发送完成事件，zip 操作符也会发送完成事件。
     管道A    1
     管道B    1
     合并发送 1,1
     管道A    1   2
     管道B    1
     不合并发送，2 被忽略，需等到管道B 有 2，才会合并发送  2，2
     
     zip 在时序语义上更接近于“当…且…”，当 Publisher1 发布值，且 Publisher2 发布值时，将两个值合并，作为新的事件发布出去。在实践中，zip 经常被用在合并多个异步事件的结果，比如同时发出了多个网络请求，希望在它们全部完成的时候把结果合并在一起。
     
     combineLatest：
     只要有一个管道有新值，就提取多个管道的最新值，合并发送
     和 zip 相反，combineLatest的语义接近于“当…或…”，当 Publisher1 发布值，或者 Publisher2 发布值时，将两个值合并，作为新的事件发布出去。
     不论是哪个 Publisher，只要发生了新的事件，combineLatest 就把新发生的事件值和另一个 Publisher 中当前的最新值合并。
     如果有任意一个 Publisher 发送完成事件，combineLatest 操作符也会发送完成事件。
     combineLatest 被用来处理多个可变状态，在其中某一个状态发生变化时，获取这些全部状态的最新值。比如你的 UI 上有多个 TextField，你可能想要在其中某一个值变动时获取到所有 TextField 中的值并对它们进行检查，比如说用户注册界面。
     
     对于 zip 和 combineLatest，它们有一个共同特点，那就是结合后的新 Publisher 所发出的数据是元组类型。对这两种操作，一种常见的模式是将结果的发出多元组数据的 Publisher 沿着响应链继续传递，使用我们之前看到过的各类 Operator 来获取能实际驱动 UI 和 app 状态的 Publisher。
     
     zip 操作符的优点是它可以将多个 Publisher 进行配对，这在需要将多个数据源进行比对或者合并时非常有用。
     combineLatest 操作符的优点是它可以将多个 Publisher 的最新事件进行组合，这在需要实时地将多个数据源进行组合时非常有用。
     https://juejin.cn/post/7220251777685913659
     */
    func compareCombineLatestAndZip() {
        Publishers.CombineLatest(valueAPublisher, valueBPublisher)
            .map({ valueA, valueB in
                print("cbl valueA: \(String(describing: valueA)), valueB: \(String(describing: valueB))")
                return (valueA ?? "") + "__" + (valueB ?? "")
            })
            .assign(to: \.text, on: combineLatestPipelineLabel)
            .store(in: &cancellable)
        
        Publishers.Zip(valueAPublisher, valueBPublisher)
            .map({ valueA, valueB in
                print("zip valueA: \(String(describing: valueA)), valueB: \(String(describing: valueB))")
                return (valueA ?? "") + "__" + (valueB ?? "")
            })
            .assign(to: \.text, on: zipPipelineLabel)
            .store(in: &cancellable)
    }
    
    @IBAction func sendAAction(_ sender: UIButton) {
        valueAPublisher.send(valueATextField.text)
    }
    
    @IBAction func sendBAction(_ sender: UIButton) {
        valueBPublisher.send(valueBTextField.text)
    }
    
    //MARK: 在另外的UI上使用
    @IBAction func otherUIAction(_ sender: Any) {
        let theVC = SUViewController()
        theVC.type = .CombineLatestAndZip
        self.navigationController?.pushViewController(theVC, animated: true)
    }
}

/**
 改进TextField事件监听
 */
extension UITextField {
    func textPublisher() -> AnyPublisher<String?, Never> {
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self)
            .map({ ($0.object as? UITextField)?.text })
            .eraseToAnyPublisher()
        
    }
}
