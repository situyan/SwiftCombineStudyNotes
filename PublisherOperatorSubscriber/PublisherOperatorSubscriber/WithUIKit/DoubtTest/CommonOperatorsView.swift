//
//  CommonOperatorsView.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/12.
//

import SwiftUI

struct CommonOperatorsView: View {
    @StateObject var model = CommonOperators()
    @StateObject var dtModel = DebounceThrottleObject()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10, content: {
                Text("Operators")
                    .font(.title)
                
                VStack(spacing: 15) {
                    Button("map") {
                        model.mapFunc()
                    }
                    Button("tryMap") {
                        model.tryMapFunc()
                    }
                    Button("filter") {
                        model.filterFunc()
                    }
                    Button("tryFilter") {
                        model.tryFilterFunc()
                    }
                    Button("compactMap") {
                        model.compactMapFunc()
                    }
                    Button("tryCompactMap") {
                        model.tryCompactMapFunc()
                    }
                    VStack {
                        HStack {
                            Button("flatMapFunc") {
                                model.flatMapFunc()
                            }
                            Button("flatMapFunc2") {
                                model.flatMapFunc2()
                            }
                        }
                        HStack {
                            Button("flatMapFunc3") {
                                model.flatMapFunc3()
                            }
                            Button("flatMap catch") {
                                model.flatMapCatchFunc()
                            }
                        }
                    }
                    Button("removeDuplicates") {
                        model.removeDuplicatesFunc()
                    }
                    Button("first/last(where:)") {
                        model.firstLastWhere()
                    }
                    
                    /**
                     merge、zip 和 combineLatest 操作符都是非常有用的操作符，它们可以将多个 Publisher 合并成一个，以便更方便地处理和订阅。
                     merge 操作符可以将多个 Publisher 合并成一个，并按照它们产生事件的顺序【依次】将这些事件发送给下游；
                     zip 操作符可以将多个 Publisher 合并成一个，并将它们产生的事件【配对】发送给下游；
                     combineLatest 操作符可以将多个 Publisher 合并成一个，并将它们产生的最新事件进行【组合】发送给下游。
                     链接：https://juejin.cn/post/7220251777685913659
                     */
                    Button("merge") {
                        model.mergeFunc()
                    }
                    VStack(spacing: 15) {
                        NavigationLink("zip") {
                            CombineLatestAndZipView(isZip: true)
                        }
                        NavigationLink("combineLatest") {
                            CombineLatestAndZipView(isZip: false)
                        }
                    }
                    
                    Button("setFailureType") {
                        model.setFailureTypeFunc()
                    }
                    
                    Button("Future") {
                        model.futureFunc()
                    }
                    
                    Button("Deferred") {
                        model.deferredFunc()
                    }
                    
                    VStack {
                        HStack {
                            Button("switchToLatest1") {
                                model.switchToLatest1Func()
                            }
                            Button("switchToLatest2") {
                                model.switchToLatest2Func()
                            }
                        }
                        HStack {
                            Button("switchToLatest3") {
                                model.switchToLatest3Func()
                            }
                            Button("switchToLatest4") {
                                model.switchToLatest4Func()
                            }
                        }
                    }
                    
                    VStack(spacing: 15) {
                        Text("调试")
                        Button("print") {
                            model.printFunc()
                        }
                        Button("breakpoint") {
                            model.breakpoint()
                        }
                        Button("handleEvents") {
                            model.handleEvents()
                        }
                    }
                    
                    VStack(spacing: 15) {
                        Text("控制时间")
                        Button("Debounce") {
                            dtModel.debounceSendMessage()
                        }
                        Button("Throttle") {
                            dtModel.throttleSendMessage()
                        }
                        Button("delay") {
                            model.delayForFunc()
                        }
                        Button("measureInterval") {
                            model.measureIntervalFunc()
                        }
                        Button("timeout") {
                            model.timeoutFunc()
                        }
                    }
                    
                    Text("额外补充")
                        .foregroundColor(.black)
                        .font(.title3)
                        .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                    
                    Button("collect") {
                        model.collectFunc()
                    }
                    
                    Button("replaceNil") {
                        model.replaceNilFunc()
                    }
                    Button("replaceEmpty") {
                        model.replaceEmptyFunc()
                    }
                    Button("replaceError") {
                        model.replaceErrorFunc()
                    }
                    
                    Button("scan") {
                        model.scanFunc()
                    }
                    Button("tryScan") {
                        model.tryScanFunc()
                    }
                    Button("ignoreOutput") {
                        model.ignoreOutputFunc()
                    }
                    
                    Button("dropFirst") {
                        model.dropFirst()
                    }
                    Button("dropWhile") {
                        model.dropWhileFunc()
                    }
                    Button("dropUntilOutputFrom") {
                        model.dropUntilOutputFromFunc()
                    }
                    Button("prefix") {
                        model.prefixFunc()
                    }
                    Button("prefixWhile") {
                        model.prefixWhileFunc()
                    }
                    Button("prefixUntilOutputFrom") {
                        model.prefixUntilOutputFromFunc()
                    }
                    
                    Button("prepend") {
                        model.prependFunc()
                    }
                    Button("prependSequence") {
                        model.prependSequenceFunc()
                    }
                    Button("prependPublisher") {
                        model.prependPublisherFunc()
                    }
                    
                    Button("append") {
                        model.appendFunc()
                    }
                    Button("appendSequence") {
                        model.appendSequenceFunc()
                    }
                    Button("appendPublisher") {
                        model.appendPublisherFunc()
                    }
                    
                    Button("min") {
                        model.minFunc()
                    }
                    Button("max") {
                        model.maxFunc()
                    }
                    Button("outputIn outputAt") {
                        model.outputInAtFunc()
                    }
                    Button("count") {
                        model.countFunc()
                    }
                    Button("contains") {
                        model.containsFunc()
                    }
                    Button("reduce") {
                        model.reduceFunc()
                    }
                }
                .padding()
            })
        }
    }
}

#Preview {
    CommonOperatorsView()
}
