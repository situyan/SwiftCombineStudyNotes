//
//  URLSessionObject.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/11.
//

import Foundation
import SwiftUI
import Combine

struct Photo: Identifiable, Decodable {
    let id: Int
    let albumId: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}

class URLSessionObject: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    @Published var photos: [Photo] = []
    @Published var isFetching: Bool = false
    
    func fetchPhotoData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/photos") else { return;
        }
        
        isFetching = true
        let request = URLRequest(url: url)
        URLSession.DataTaskPublisher(request: request, session: .shared)
            .map(\.data)
            .decode(type: [Photo].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("request completed")
                case .failure(let error):
                    print("request failed with ", error)
                }
            } receiveValue: { photos in
                print("request response(\(photos.count)): \(String(describing: photos.first))")
                self.isFetching = false
                self.photos = photos
            }
            .store(in: &cancellable)
        
//        Timer.publish(every: <#T##TimeInterval#>, on: <#T##RunLoop#>, in: <#T##RunLoop.Mode#>)
    }
}
