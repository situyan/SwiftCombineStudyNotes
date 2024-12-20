//
//  AsyncCoordinatorVC.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/3.
//

/**
 有序的异步操作
 
 任何需要按特定顺序执行的异步（或同步）任务组都可以使用 Combine 管道进行协调管理。 通过使用 Future 操作符，可以捕获 完成异步请求的行为，序列操作符提供了这种协调功能的结构。
 
 通过将任何异步 API 请求与 Future 发布者进行封装，然后将其与 flatMap 操作符链接在一起，你可以以特定顺序调用被封装的异步 API 请求。 通过使用 Future 或其他发布者创建多个管道，使用 zip 操作符将它们合并之后等待管道完成，通过这种方法可以创建多个并行的异步请求。(step2_1,2,3）

 如果你想【强制一个 Future 发布者直到另一个发布者完成之后才被调用】，你可以把 future 发布者创建在 flatMap 的闭包中，这样它就会等待 有值被传入 flatMap 操作符之后 才会被创建。（step3, step4）

 通过组合这些技术，可以创建任何并行或串行任务的结构。

 如果后面的任务需要较早任务的数据，这种协调异步请求的技术会特别有效。 在这些情况下，所需的数据结果可以直接通过管道传输。
 */

import UIKit
import Combine

class AsyncCoordinatorVC: UIViewController {
    @IBOutlet var startButton: UIButton!

    @IBOutlet var step1_button: UIButton!
    @IBOutlet var step2_1_button: UIButton!
    @IBOutlet var step2_2_button: UIButton!
    @IBOutlet var step2_3_button: UIButton!
    @IBOutlet var step3_button: UIButton!
    @IBOutlet var step4_button: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var cancellable: AnyCancellable? = nil
    var coordinatedPipeline: AnyPublisher<Bool, Error>? = nil
    
    //MARK: - 开始
    @IBAction func startAction(_ sender: UIButton) {
        if let cancellable = cancellable {
            print("Cancelling existing run")
            cancellable.cancel()
            activityIndicator.stopAnimating()
        }
        
        print("resetting all the steps")
        self.resetAllSteps()
        self.activityIndicator.startAnimating()
        print("attaching a new sink to start things going")
        /**
         管道中的 print 操作符用于调试，在触发管道时在控制台显示输出。
         使用 sink 创建订阅者并存储对工作流的引用。 被订阅的发布者 coordinatedPipeline 是在该函数外创建的，允许被多次复用。
         */
        self.cancellable = coordinatedPipeline?
            .print()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion: ", String(describing: completion))
                self.activityIndicator.stopAnimating()
            }, receiveValue: { value in
                print(".sink() received value: ", value)
            })
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if let cancellable = cancellable {
            print("------------\nCancelling existing run")
            cancellable.cancel()
            activityIndicator.stopAnimating()
        }
        resetAllSteps()
    }
    
    func resetAllSteps() {
        let buttons: [UIButton] = [step1_button, step2_1_button, step2_2_button, step2_3_button, step3_button, step4_button]
        for button in buttons {
            button.backgroundColor = .lightGray
            button.isHighlighted = false
        }
        activityIndicator.stopAnimating()
    }
    
    func markStepDone(button: UIButton) {
        button.backgroundColor = .systemGreen
        button.isHighlighted = true
    }
    
    func createFuturePublisher(button: UIButton) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.randomAsyncAPI { result, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(result))
                }
            }
        }
        .receive(on: RunLoop.main)
        .map { value in
            self.markStepDone(button: button)
            return true
        }
        .eraseToAnyPublisher()
    }
    
    func randomAsyncAPI(completion completionBlock: @escaping ((Bool, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            sleep(UInt32.random(in: 1...4))
            completionBlock(true, nil)
        }
    }
    
    //MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.activityIndicator.stopAnimating()
        
        /**
         此排序的示例如下。 在此示例中，按钮在完成时会高亮显示，按钮的排列顺序是特意用来显示操作顺序的。 整个序列由单独的按钮操作触发，该操作还会重置所有按钮的状态，如果序列中有尚未完成的任务，则都将被取消。 在此示例中，异步 API 请求会在随机的时间之后完成，作为例子来展示时序的工作原理。
         
         创建的工作流分步表示如下：

         步骤 1 先运行。
         步骤 2 有三个并行的任务，在步骤 1 完成之后运行。
         步骤 3 等步骤 2 的三个任务全部完成之后，再开始执行。
         步骤 4 在步骤 3 完成之后开始执行。
         
         此外，还有一个 activity indicator 被触发，以便在序列开始时开始动画，在第 4 步完成时停止。
         */
        // 创建整个管道及其串行和并行任务结构，是结合了对 createFuturePublisher 的调用以及对 flatMap 和 zip 操作符的使用共同完成的。
        // 先创建一个执行step1 的发布者Future
        coordinatedPipeline = createFuturePublisher(button: self.step1_button)
            .flatMap({ _ -> AnyPublisher<Bool, Error> in
                // _ 表示step1的结果（可在当前使用）， 在管道中用flatMap操作符执行并发操作（step2_1,2,3），并通过zip收集三个任务的结果
                let step2_1 = self.createFuturePublisher(button: self.step2_1_button)
                let step2_2 = self.createFuturePublisher(button: self.step2_2_button)
                let step2_3 = self.createFuturePublisher(button: self.step2_3_button)
                return Publishers.Zip3(step2_1, step2_2, step2_3)
                    .map({ bool1, bool2, bool3 in
                        return (bool1 && bool2 && bool3)
                    })
                    .eraseToAnyPublisher()
            })
            .flatMap { _ in
                // _ 表示（step2_1,2,3）的结果（可在当前使用），继续在管道中用flatMap操作符执行step3
                self.createFuturePublisher(button: self.step3_button)
            }
            .flatMap { _ in
                // _ 表示step3的结果（可在当前使用），继续在管道中用flatMap操作符执行step3
                self.createFuturePublisher(button: self.step4_button)
            }
            .eraseToAnyPublisher()
    }
}
