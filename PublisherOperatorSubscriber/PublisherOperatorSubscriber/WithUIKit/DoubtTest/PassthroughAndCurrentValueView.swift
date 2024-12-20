//
//  PassthroughAndCurrentValueView.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/10.
//

import SwiftUI

struct PassthroughAndCurrentValueView: View {
    @ObservedObject var model = PasstthroughAndCurrentValueSubject()
    
    var body: some View {
        HStack {
            VStack(spacing: 10) {
                Text("PassthroughSubject")
                Button("Send Message") {
                    model.sendMessage1()
                }
                Button("Send Error") {
                    model.sendError1()
                }
                Button("Send Completion") {
                    model.sendCompletion1()
                }
            }
            .padding()
            
            VStack(spacing: 10) {
                Text("CurrentValueSubject")
                Button("Send Message") {
                    model.sendMessage2()
                }
                Button("Send Error") {
                    model.sendError2()
                }
                Button("Send Completion") {
                    model.sendCompletion2()
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            model.passthroughSubjectFunc()
            model.currentValueSubjectFunc()
        }
    }
}

#Preview {
    PassthroughAndCurrentValueView()
}
