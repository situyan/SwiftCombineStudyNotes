//
//  AttributeWrapperView.swift
//  StatusWrappers
//
//  Created by hank on 2024/11/29.
//

import SwiftUI

/**
 ObservableObject 用于声明一个可以发布变化的对象。
 @Published 属性包装器用于触发视图更新。
 @StateObject 和 @ObservedObject 用于在视图中引用 ObservableObject，而 @EnvironmentObject 允许全局共享和访问状态。
 */

// 定义全局设置
class GlobalSettings: ObservableObject {
    @Published var theme: String = "Light"
    
    init(theme: String) {
        self.theme = theme
    }
}

// 用户设置
class UserSettings: ObservableObject {
    @Published var username: String = "Guest"
    
    init(username: String) {
        self.username = username
    }
}

struct ParentView: View {
    @StateObject var global = GlobalSettings(theme: "Light1")
    @StateObject var user = UserSettings(username: "Guest1")
    
    var body: some View {
        NavigationView {
            HStack {
                VStack {
                    NavigationLink("Child View") {
                        ChildView(user: user)
                    }
                    .padding()
                    
                    Text("Theme: \(global.theme)")
                        .padding()
                    Text("Username: \(user.username)")
                        .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
            /**
             StatusWrappers crashed due to missing environment of type: GlobalSettings. To resolve this add `.environmentObject(GlobalSettings(...))` to the appropriate preview.
             */
            //.environmentObject(global)
            //.environmentObject(user)
        }
        .environmentObject(global)
        .environmentObject(user)
    }
}

struct ChildView: View {
    @ObservedObject var user: UserSettings
    
    var body: some View {
        HStack {
            VStack {
                Text("Username: \(user.username)")
                Button("Change") {
                    user.username = "John Doe"
                }
                .padding()
                
                NavigationLink("Theme View") {
                    ThemeView()
                }
                .padding()
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

struct ThemeView: View {
    @EnvironmentObject var global: GlobalSettings
    @EnvironmentObject var user: UserSettings
    
    var body: some View {
        HStack {
            VStack {
                Text("user: \(user.username)")
                Spacer()
                    .frame(height: 1.5)
                    .background(Color.gray)
                Text("Current Theme: \(global.theme)")
                Button("Toggle Theme") {
                    global.theme = global.theme == "Light" ? "Dark" : "Light"
                }
                .padding()
                
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    ParentView()
}


/*******************----------------------------******************/
/*******************----------------------------******************/
/*******************----------------------------******************/


class WorkModel: ObservableObject {
    @Published var name = "name"
    @Published var count = 1
}

class UserModel: ObservableObject {
    @Published var name = "name"
    @Published var header = "hyyps://www.baidu.com"
}

class WrapperModel: ObservableObject {
    @ObservedObject var workModel = WorkModel()
    @ObservedObject var userModel = UserModel()
}

struct MultiOjbView: View {
    @ObservedObject var workModel = WorkModel()
    @ObservedObject var userModel = UserModel()
    
    var body: some View {
        VStack {
            Text("work.name \(workModel.name)")
            Text("work.count \(workModel.count)")
            Text("user.name \(userModel.name)")
            Text("user.header \(userModel.header)")
            
            Button("更新") {
                workModel.name = "12345"
                workModel.count = 10
                userModel.name = "Jon"
                userModel.header = "https://xxx.xxx......"
            }
        }
    }
}
