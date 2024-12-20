//
//  URLSessionView.swift
//  PublisherOperatorSubscriber
//
//  Created by hank on 2024/12/11.
//

import SwiftUI

struct URLSessionView: View {
    @StateObject private var model = URLSessionObject()
    
    var body: some View {
        if model.photos.isEmpty {
            if model.isFetching {
                ProgressView()
            } else {
//                Button {
//                    model.fetchPhotoData()
//                } label: {
//                    Text("Fetch photos data")
//                        .font(.title)
//                        .foregroundColor(Color.white)
//                }
                Button("Fetch photos data") {
                    model.fetchPhotoData()
                }
                .foregroundColor(Color.white)
                .background(Color.blue)
            }
        } else {
            List(model.photos) { photo in
                PhotoView(photo: photo)
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct PhotoView: View {
    let photo: Photo
    
    var body: some View {
        HStack(spacing: 15) {
            if #available(iOS 15.0, *) {
                AsyncImage(url: URL(string: photo.thumbnailUrl)!) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 83, height: 83)
            } else {
                Text(photo.thumbnailUrl)
                    .background(Color.gray.opacity(0.3))
                    .frame(width: 83, height: 83)
            }
            
            VStack(alignment: .leading) {
                Text(String(photo.id))
                    .font(.title)
                
                Text(photo.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    URLSessionView()
}
