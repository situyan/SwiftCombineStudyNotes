//
//  DebounceThrottleView.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/11.
//

import SwiftUI

struct DebounceThrottleView: View {
    @StateObject private var model = DebounceThrottleObject()
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 25) {
                Button("Debounce") {
                    model.debounceSendMessage()
                }
                Button("Throttle") {
                    model.throttleSendMessage()
                }
            }
            .padding()
            
            List(model.outputArray, id: \.self) { value in
                Text(value)
                    .font(.title)
                    .frame(alignment: .leading)
            }
            .listStyle(PlainListStyle())
            
            Spacer()
        }
    }
}

#Preview {
    DebounceThrottleView()
}
