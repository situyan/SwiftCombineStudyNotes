//
//  CommonPublisherView.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/13.
//

import SwiftUI

struct CommonPublisherView: View {
    @StateObject var model = CommonPublisher()
    
    var body: some View {
        VStack(spacing: 10, content: {
            Text("Publishers")
                .font(.title)
            
            VStack(spacing: 15) {
                Text("一部分在外面，比如：Just，PassthroughSubject，CurrentValueSubject，DataTaskPublishe，sink(receive:)，assign(to:on)等\n------------------------\n------------------------\n------------------------")
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10))
                
                VStack {
                    Text("other Timer: \(model.date)")
                    HStack {
                        Button("Timer Start") {
                            model.timerFunc()
                        }
                        Button("Timer Stop") {
                            model.timerStop()
                        }
                    }
                }
                
                Button("Notification") {
                    model.notificationFunc()
                }
                Button("Sequence") {
                    model.sequenceFunc()
                }
                Button("Fail") {
                    model.failedFunc()
                }
                Button("Empty") {
                    model.emptyFunc()
                }
                
                VStack(spacing: 10) {
                    Text("ConnectablePublisher\n控制何时发布")
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Button("share1") {
                            model.shareFunc1()
                        }
                        Button("share2") {
                            model.shareFunc2()
                        }
                    }
                    Button("makeConnectable") {
                        model.makeConnectable()
                    }
                    Button("multicastFunc") {
                        model.multicastFunc()
                    }
                }
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
            }
        })
        .padding()
        .onDisappear {
            model.timerStop()
        }
    }
}

#Preview {
    CommonPublisherView()
}
