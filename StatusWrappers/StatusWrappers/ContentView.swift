//
//  ContentView.swift
//  StatusWrappers
//
//  Created by hank on 2024/11/27.
//

/**
 @State, @Binding, @ObservedObject, @StateObject, @Environment, @EnvironmentObject
 https://blog.csdn.net/weixin_44786530/article/details/139449096
 https://www.jianshu.com/p/3c8c77372e9c
 https://blog.csdn.net/IOSSHAN/article/details/141212949
 https://cloud.tencent.com/developer/article/1908881
 
 https://www.cnblogs.com/Aliancn/p/18378648
 
 后面
 https://www.cnblogs.com/zhou--fei/p/17720908.html
 https://www.jianshu.com/p/bc6443a8a083
 https://www.jianshu.com/p/ce07f3334500
 https://blog.csdn.net/zgpeace/article/details/136063837
 https://developer.aliyun.com/article/1587885
 https://cloud.tencent.com/developer/information/使用SwiftUI和Combine进行双向绑定-album
 */

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            VStack {
    //            StateView()
//                BindingView()
//                ObservedObjectView()
//                EnvironmentObjectView()
//                StateObjectView()
//                StateObservableView()
//                ParentView()
                MultiOjbView()
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

//MARK: - @State 属性包装器
struct StateView: View {
    /**
     和一般的存储属性不同，@State 修饰的值，在 SwiftUI 内部会被自动转换为一对 setter 和 getter，对这个属性进行赋值的操作将会触发 View 的刷新，它的 body 会被再次调用，底层渲染引擎会找出界面上被改变的部分，根据新的属性值计算出新的 View，并进行刷新。
     */
    @State var count = 0
    var body: some View {
        HStack {
            VStack {
                Text("测试 \(count)")
                Button("点击+1") {
                    //没有属性包装器时无法被修改，属于不可变属性 （推测因为其所属结构体StateView是不变的，所以内部变量无法直接修改)
                    count += 1
                }
                .foregroundStyle(Color.white)
                .background(Color.blue)
                Spacer()
            }
            Spacer()
        }
    }
}

//MARK: - @Binding 属性包装器
struct BindingView: View {
    /**
     使用@state可以实现在当前view视图内的状态管理，
     但是如果需要将状态传递到子视图，并且实现双向绑定就需要使用@Binding来实现，
     示例中通过@Binding绑定上层传递过来的count1, 当点击按钮后，会发现最上层view的Text内容变成了1234567890，这里就实现了双向绑定，
     
     并且通过@Binding绑定的数据或者对象其生命周期同MapView保存一致
     */
    @State var count = "eeer"
    
    var body: some View {
        VStack {
            MapView(countC: $count)
            Text(count)
                .padding()
        }
    }
}
struct MapView: View {
    /**
     和 @State 类似，@Binding 也是对属性的修饰（setter getter, 相关联的View在值变化时刷新）；
     它做的事情是将值语义的属性“转换”为引用语义；
     对被声明为 @Binding 的属性进行赋值，改变的将不是属性本身，而是它的引用，这个改变将被向外传递。
     */
    @Binding var countC: String
    
    var body: some View {
        VStack {
            Text(countC)
                .padding()
            Button("点击") {
                countC = "1234567"
            }
        }
        .background(Color.gray.opacity(0.5))
        .padding()
    }
}

//MARK: - @ObservedObject 属性包装器
/**
 如果说 @State 是全自动驾驶的话，ObservableObject 就是半自动，它需要一些额外的声明。
 ObservableObject 协议要求实现类型是 class，
 它只有一个需要实现的属性：objectWillChange。在数据将要发生改变时，这个属性用来向外进行“广播”，它的订阅者 (一般是 View 相关的逻辑) 在收到通知后，对 View 进行刷新。
 @ObservedObject 比通知更为结构化和强类型。它不仅用于观察对象的变化，还能直接驱动视图更新
 
 创建 ObservableObject 后，实际在 View 里使用时，我们需要将它声明为 @ObservedObject。这也是一个属性包装，它负责通过订阅 objectWillChange 这个“广播”，将具体管理数据的 ObservableObject 和当前的 View 关联起来。
 
 ObservableObject 用于声明一个可以发布变化的对象。
 @Published 属性包装器用于触发视图更新。
 @StateObject 和 @ObservedObject 用于在视图中引用 ObservableObject，而 @EnvironmentObject 允许全局共享和访问状态。

 */
class Person: ObservableObject {
    /**
     class对象的属性只有被@Published修饰时，属性的值修改时，才能被监听到
     推测：@Published 修饰符实现协议 ObservableObject 的属性：objectWillChange
     
     被 @Published 包装的属性发送变化时，所有观察这个对象属性的视图都会自动更新， 这种方式强调数据驱动的UI更新，紧密结合状态和视图
     
     使用 @Published 属性包装器标记的属性在变化时，会自动通知视图更新/ 通知所有订阅者。这使得视图能够实时响应数据的变化。
     订阅者是被  @ObservedObject 属性包装器标记的 对象
     
     @Published 修饰的属性发送了变化，会自动触发 ObservableObject 的objectWillChange 的 send方法，刷新页面，SwiftUI 已经默认帮我实现好了，但也可以自己手动触发这个行为。
     
     ObservableObjectPublisher().send()
     https://cloud.tencent.com/developer/article/1585679
     */
    @Published var name = "李某" {
        willSet {
            // 可以在这里改变其他属性的值，进而触发联动变化
            print("name属性发送变化 \(newValue)")
        }
    }
    
    @Published var number = 1
    
    deinit {
        print("Person 被销毁")
    }
}

struct ObservedObjectView: View {
    @ObservedObject var p = Person()
    
    var body: some View {
        VStack {
            Text(p.name)
                .padding()
            Button("点击") {
                p.name = "1234567"
            }
        }
    }
}

//MARK: - @StateObject 属性包装器 (与 @ObservedObject 比较不同点）
/**
 StateObject行为类似ObservedObject对象，区别是StateObject由SwiftUI负责针对一个指定的View，创建和管理一个实例对象，不管多少次View更新，都能够使用本地对象数据而不丢失
 @StateObject 只能用于创建 ObservableObject 的实例，并持有它以确保对象在视图的整个生命周期内保持一致。
 @StateObject 是因为 State 管理了该对象的生命周期，确保对象在视图的整个生命周期中存在。
 
 如果希望在多个视图中共享同一对象，通常会在【顶层视图中使用】 @StateObject 来创建并管理对象，然后在子视图中通过 @ObservedObject 来观察这个对象。跨层级多的视图可以
 通过 @EnvironmentObject 来观察，不需要逐层传递
 */
struct StateObjectView: View {
    // 被 @StateObject 修饰对象的生命周期由视图管理，并且在视图的整个生命周期内一直被持有
    @StateObject var p = Person()
    var body: some View {
        VStack {
            Text("测试\(p.number)")
            Button("点击") {
                p.number += 1
            }
        }
    }
}

struct StateObservableView: View {
    @StateObject var p = Person()
    @State var count = 0
    
    var body: some View {
        VStack {
            Text("刷新当前View次数 \(count)")
            Button("刷新") {
                count += 1
            }
            SOMapView()
            SOEMapView()
        }
        .environmentObject(p)
    }
}

/**
 @StateObject和@ObservedObject区别
 1、@ObservedObject 只是作为View的数据依赖，不被View持有，View更新时ObservedObject对象可能会被销毁
 适合数据在SwiftUI外部存储，把@ObservedObject 包裹的数据作为视图的依赖，比如数据库中存储的数据
 @ObservedObject不被View持有，生命周期不一定与View一致，即数据可能被保持或者销毁
 
 2、@StateObject 针对引用类型设计，当View更新时，实例不会被销毁，与State类似，使得View本身拥有数据
 @StateObject的生命周期与当前所在View生命周期保持一致，即当View被销毁后，StateObject的数据销毁，当View被刷新时，StateObject的数据r仍会保持
 
 @ObservedObject: 用于视图观察外部的 ObservableObject，当对象的属性变化时会重新渲染视图。它不像通知那样松耦合，更加结构化。
 @StateObject: 用于在视图内部声明和持有一个 ObservableObject 的实例，确保该对象在视图的生命周期内保持一致。
 @StateObject 创建并持有对象的实例，适用于视图生命周期内的状态管理。
 @ObservedObject 则用于观察由外部传入的对象实例，适用于共享和订阅变化。
 */
struct SOMapView: View {
    @Environment(\.colorScheme) var colorScame
    /**
     点击刷新时,Person 的deinit方法被调用，说明p对象被销毁；
     先连续点击+1,Text上的数字在一直递增，当点击刷新时Text上的数字恢复为1，这个现象也说明p对象被销毁
     */
    @ObservedObject var p = Person()
    /**
     怎么操作，p都不会销毁
     */
    // @StateObject var p = Person()
    /**
     怎么操作，count都不会销毁
     @State 变量是由视图自己管理的，它的生命周期与视图绑定
     */
    @State var count: Int = 0
    
    var body: some View {
        VStack {
            Text("\(p.number)")
            Button("+1") {
                p.number += 1
                // colorScame == .light
            }
            
            Spacer()
                .frame(height: 1.5)
                .background(Color.gray)
            
            Text("\(count)")
            Button("+1") {
                count += 1
            }
        }
        .padding()
        .background(Color.gray.opacity(0.5))
    }
}

struct SOEMapView: View {
    @EnvironmentObject var p: Person
    
    var body: some View {
        VStack {
            Text(p.name)
        }
    }
}

//MARK: - @EnvironmentObject 属性包装器
/**
 View 提供了 environmentObject(xxx) 方法，来把某个 ObservableObject 的值注入到当前 View 层级及其子层级中去。
 在这个 View 的子层级中，可以使用 @EnvironmentObject 来直接获取这个绑定的环境值。
 
 通常用于跨越多个视图层级共享数据。
 可以在顶层视图或应用的根视图中通过 .environmentObject() 方法注入一个 ObservableObject 实例，然后在任意子视图中通过 @EnvironmentObject 来访问和修改这个对象。
 这对于需要在应用中广泛共享状态的场景非常适用，例如用户设置、应用主题、全局配置等。
 
 理解“通过环境注入对象”和“跨多个视图共享 ObservableObject”

 通过环境注入对象: @EnvironmentObject 是通过 SwiftUI 的环境系统来注入的，它依赖于视图层次结构中上级视图的 .environmentObject() 调用。这种注入机制使得视图层次结构中的任意子视图都可以访问同一个 ObservableObject 实例，而不需要显式地传递对象引用。这种方式对于全局状态管理非常便利。

 跨多个视图共享 ObservableObject: 由于 @EnvironmentObject 是通过环境注入的，这意味着任何一个视图都可以访问同一个 ObservableObject，而不需要明确地传递它。它非常适合用于那些需要在多个视图之间共享的状态，例如用户设置、应用主题等。
 */
struct EnvironmentObjectView: View {
//    @ObservedObject var p = Person()
    var body: some View {
        VStack {
            let p = Person() // 内部创建的临时变量无法联动（受子视图的属性变化影响）
            Text("--\(p.name)--")
            EnvironmentSubView().environmentObject(p)
        }
    }
}
/**
 @EnvironmentObject 修饰器是针对全局环境的。
 通过它，我们可以避免在初始 View 时创建 ObservableObject, 而是从环境中获取 ObservableObject
 可以看出我们获取 p这个 ObservableObject 是通过 @EnvironmentObject 修饰器，但是在入口需要传入 .environmentObject(p) 。
 @EnvironmentObject 的工作方式是在 Environment 查找 Person 实例。
 */
struct EnvironmentSubView: View {
    // @EnvironmentObject 属性包装器修饰的变量不能直接赋值，由外层提供
    @EnvironmentObject var p: Person
    
    var body: some View {
        VStack {
            Text(p.name)
            Button("点击") {
                p.name = "1241353"
            }
        }
    }
}

//MARK: - @Environment
/**
 @Environment 用于访问 SwiftUI 环境中的值，这些值通常由系统或上级视图提供。@Environment 的值可以是系统提供的，例如 colorScheme、locale，也可以是你自定义的值。
 @Environment 更适用于读取那些依赖于视图上下文或全局配置的值，通常这些值是只读的，但你也可以通过设置这些值来影响整个应用的行为。
 
 确认值是只读的，还是可读可写？
 @Environment 更适合访问依赖上下文的环境值，通常用于“读取”系统配置或上级视图提供的环境值。
 */
struct EnvironmentView: View {
    // 用于访问系统的当前颜色模式（例如浅色模式或深色模式），并根据它动态更新视图
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            let color = colorScheme == .light ? "浅色模式" : "深色模式"
            Text("颜色模式: \(color)")
        }
    }
}

//MARK: 区别及各种使用场景 @EnvironmentObject, @Environment, @Binding, @ObservedObject, @StateObject
/**
 @EnvironmentObject 和 @Binding 的对比

 @EnvironmentObject: 适用于跨多个视图层次结构共享 ObservableObject，尤其是当视图层次结构深且需要访问全局状态时。它通过环境注入对象，简化了对象在多层级视图间的传递。
 即数据在多个视图层级中传递，不需要逐层传值，只需要在上层视图/根视图中注入数据，然后在需要的子视图中提取即可

 @Binding: 适用于父子视图之间的状态共享和双向绑定。它让子视图可以访问并修改父视图的状态。@Binding 更适合在直接的父子关系中使用，当你只需要在两个层级之间共享状态时，它是最好的选择。
 
 -------------------------------------
 -------------------------------------
 总结与应用场景：
 @EnvironmentObject 是为了解决全局状态共享问题，特别适用于需要在应用中广泛使用的 ObservableObject。它使得在深层次的视图层次结构中访问共享状态更加简单，而无需显式传递。

 @Environment 更适合访问依赖上下文的环境值，通常用于读取系统配置或上级视图提供的环境值。

 @Binding 则是为父子视图之间的状态共享设计的，适用于简单的双向数据绑定。
 
 属性包装器解释

 @StateObject: 用于在视图创建时初始化 ObservableObject，且该【对象生命周期与视图绑定】。
 @ObservedObject: 用于在父视图传递 ObservableObject 对象给子视图时，【子视图对该对象进行监听】。
 @EnvironmentObject: 提供一种【注入式全局共享 】ObservableObject 的机制，方便【全局状态管理】。
 */

/**
 @StateObject: 它只在视图创建时初始化，并且在视图的整个生命周期内保持不变。适用于视图自己创建和拥有的 ObservableObject。
 理解----只在视图创建时初始化：视图被创建时，对象也被创建，且只此一次，当视图被再次创建时，对象重新被创建，所以对象的生命周期和视图是保定的，是一致的
 @ObservedObject: 它用于外部注入 ObservableObject 实例（例如从父视图传递过来的对象），子视图对这个对象进行监听。
 */
struct SOSuperView: View {
    @StateObject var p = Person()
    
    var body: some View {
        VStack {
            Text("父视图")
            SOSubView(p: p)
        }
    }
}

struct SOSubView: View {
    @ObservedObject var p: Person
    
    var body: some View {
        Text("子视图: \(p.name)")
    }
}

#Preview {
    ContentView()
        //.environmentObject(GlobalSettings(theme: "Dark"))
        //.environmentObject(UserSettings(username: "1241235"))
}
