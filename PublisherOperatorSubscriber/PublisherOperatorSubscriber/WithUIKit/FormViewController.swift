//
//  FormViewController.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/6.
//

import UIKit
import Combine

class FormViewController: UIViewController {
    @IBOutlet weak var vaule1_input: UITextField!
    @IBOutlet weak var vaule2_input: UITextField!
    @IBOutlet weak var vaule2_repeat_input: UITextField!
    @IBOutlet weak var submission_button: UIButton!
    @IBOutlet weak var value1_message_label: UILabel!
    @IBOutlet weak var value2_message_input: UILabel!

    @Published var value1: String = ""
    @Published var value2: String = ""
    @Published var value2_repeat: String = ""
    
    var validatedValue1: AnyPublisher<String?, Never>? = nil
    var validatedValue2: AnyPublisher<String?, Never>? = nil
    var readyToSubmit: AnyPublisher<Bool, Never>? = nil
    
    var submitSubscriber: AnyCancellable? = nil
    private var cancellableSet: Set<AnyCancellable> = []
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        validatedValue1 = $value1
            .map({ text in
                if text.count < 3 {
                    return "minimum of 3 characters required"
                }
                return nil
            })
            .eraseToAnyPublisher()
        
        validatedValue2 = Publishers.CombineLatest($value2, $value2_repeat)
            .map({ text, repeat_text in
                if text.count < 5 || text != repeat_text {
                    return "values must match and have at least 5 characters"
                }
                return nil
            })
            .eraseToAnyPublisher()
        
        readyToSubmit = Publishers.CombineLatest(validatedValue1!, validatedValue2!)
            .receive(on: RunLoop.main)
            // receive on runloop main 不需要也行，因为管道中数据并未在异步函数中处理过
            .map({ value1, value2 in
                print("value1: \(String(describing: value1)), value2: \(String(describing: value2))")
                if value1 == nil && value2 == nil {
                    self.value1_message_label.text = nil
                    self.value2_message_input.text = nil
                    return true
                }
                self.value1_message_label.text = value1
                self.value2_message_input.text = value2
                return false
            })
            .eraseToAnyPublisher()
        
        /**
         我们可以将分配的管道存储为 AnyCancellable? 引用（将其映射到 viewcontroller 的生命周期），但另一种选择是创建一个变量来收集所有可取消的引用。 这从空集合开始，任何 sink 或 assign 的订阅者都可以被添加到其中，以【持有对它们的引用，以便他们在 viewcontroller 的整个生命周期内运行】。 【【如果你正在创建多个管道，这可能是保持对所有管道的引用的便捷方式】】。
         */
        // 创建的发布者/订阅者需要被持有，或者.store(in:)，如果是临时的，因被释放导致管道中数据无法流动，UI就不会更新
//        let _ = readyToSubmit?
//            .assign(to: \.isEnabled, on: submission_button)
        
        // ViewController持有
//        submitSubscriber = readyToSubmit?
//            .assign(to: \.isEnabled, on: submission_button)
        // cancellableSet集中持有
        readyToSubmit?
            .assign(to: \.isEnabled, on: submission_button)
            .store(in: &cancellableSet)
    }
    
    //MARK: - 输入框事件
    @IBAction func value1_updated(_ sender: UITextField) {
        value1 = sender.text ?? ""
    }

    @IBAction func value2_updated(_ sender: UITextField) {
        value2 = sender.text ?? ""
    }
    
    @IBAction func value2_repeat_updated(_ sender: UITextField) {
        value2_repeat = sender.text ?? ""
    }
    
    @IBAction func submit_TouchUpInside(_ sender: Any) {
        print("提交表单: \(value1), \(value2)")
    }
}
