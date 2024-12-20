//
//  CombineLatestAndZipView.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/9.
//

import SwiftUI
import Combine

class CombineLatestZipModel: ObservableObject {
    private var cancellable: Set<AnyCancellable> = []
    let numberPublisher = PassthroughSubject<Int, Never>()
    let letterPublisher = PassthroughSubject<String, Never>()
    @Published var receivedValue: [(Int, String)] = []
    
    var submitAllowed: AnyPublisher<Bool, Never>?
    
    func zipFunc() {
        numberPublisher
            .zip(letterPublisher)
            .sink { someValue in
                let (number, letter) = someValue
                print("zip some value: \(someValue)")
                self.receivedValue.append(someValue)
            }
            .store(in: &cancellable)
    }
    
    func combineLatestFunc() {
        numberPublisher
            .combineLatest(letterPublisher)
            .sink { someValue in
                print("combineLatest some value: \(someValue)")
                self.receivedValue.append(someValue)
            }
            .store(in: &cancellable)
    }
    
    func sendNumber(_ number: Int) {
        print("number: \(number)")
        numberPublisher.send(number)
    }
    
    func sendLetter(_ letter: String) {
        print("letter: \(letter)")
        letterPublisher.send(letter)
    }
}

struct CombineLatestAndZipView: View {
    @StateObject var model = CombineLatestZipModel()
    @State var number: String = ""
    @State var letter: String = ""
    @State var isDisabled: Bool = true
    var isZip: Bool = true
    
    var body: some View {
        VStack {
            Text("\(String(describing: model.receivedValue.last))")
            
            VStack {
                TextField("number: ", text: $number)
                TextField("letter: ", text: $letter)
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            
            HStack {
                Button("Send number") {
                    if let number = Int(number) {
                        model.sendNumber(number)
                    }
                }
                //.disabled(isDisabled)
                //.onReceive(<#T##publisher: Publisher##Publisher#>, perform: <#T##(Publisher.Output) -> Void#>)
                
                Spacer()
                
                Button("Send letter") {
                    if !letter.isEmpty {
                        model.sendLetter(letter)
                    }
                }
            }
            .buttonStyle(.automatic)
            .padding()
        }
        .onAppear {
            if isZip {
                model.zipFunc()
            } else {
                model.combineLatestFunc()
            }
        }
    }
}

#Preview {
    CombineLatestAndZipView()
}
