title: iOS 单元测试
date: 2017-08-31 20:10:15

tags:

- iOS开发
- 设计思想
- 测试

------



## 什么是单元测试

**形象版：**

> 工厂在组装一台机器之前，会**对每个元件都进行测试**。这，就是单元测试。

**官方版：**

> 单元测试是指对软件中的**最小可测试单元**进行**检查和验证**。



<!--more-->

**特点：FIRST 原则**

- **Fast**：测试的运行速度要快，这样就不介意运行它们。
- **Independent / Isolated**：一个测试不应当依赖于另一个测试，不依赖外部环境。
- **Repeatable**：同一个测试，每次都应当获得相同的结果。
- **Self-validating**：测试应当是完全自动化的，输出结果要么是 pass 要么是 fail，而不是依靠程序员对日志文件的解释。
- **Timely**：理想情况下，测试的编写，应当在编写要测试的产品代码之前。



**Q：单元测试和其他的测试方法有什么不同呢？**

**A：单元测试是在软件开发过程中要进行的最低级别的测试活动。**

这里我们和常见的集成测试，系统测试做对比，如下：

| 测试方式 | 类别   | 察范围                              | 基准       |
| ---- | ---- | -------------------------------- | -------- |
| 单元测试 | 白盒测试 | 单元内部的数据结构、逻辑控制、异常处理..            | 逻辑覆盖率    |
| 集成测试 | 灰盒测试 | 模块之间的接口和接口数据传递的关系，以及模块组合后的整体功能.. | 接口覆盖率    |
| 系统测试 | 黑盒测试 | 整个系统相对于需求的符合度                    | 需求规格的覆盖率 |



------



## 是否需要单元测试

首先我们要知道，写代码的最终目标有两个：

- **实现需求**
- **提高代码质量和可维护性。**

> PS：代码的可维护性是指增加一个新功能，或改变现有功能的成本。**成本越低，可维护性即越高**。

那，在保证完成需求的前提下，单元测试能否提高代码质量和可维护性，则关系到我们是否需要采用它。



> 先划个重点，**单元测试能提高代码质量和可维护性**。

如果要加入单元测试这个环节，那么前提就得保证，代码是"**可测试**"的。所谓可测试，就是要满足之前提到的那几个基本特性。

单元测试，要求你能 mock 掉**数据库**、**线程操作**、**文件操作**、**网络操作**、**UI**等等，它是可以独立工作，不依赖其他单元。不难想象，一份能独立进行这种 mock 的代码，耦合程度肯定很低。

所以单元测试其实本身最重要的不是测试的那个阶段，而是**代码最初设计结构**的那个阶段。不是为了发现 Bug，而是为了提高开发效率，为了我们的代码健康可持续发展。写单元测试会让你**更好地去思考模块划分是否合理，解耦是否到位**。



总结来说，执行单元测试有如下好处：

- 可以放心修改、重构业务代码，而不用担心修改某处代码后带来的副作用。（因为每次修改，都要保证测试用例能通过）
- 帮助反思模块划分的合理性，解耦是否到位。（如果一个单元测试写得逻辑非常复杂、或者说一个函数复杂到无法写单测，那就说明模块的抽象有问题)
- 使得软件具备更好的可维护性、具备更好的可读性。对于团队的新人来说，可以从单元测试入手，比文档更容易被程序员接受。
- 保证代码被测试，更容易及早发现问题，降低风险。



> PS：单元测试不是万能的，它也是存在一些弊端的：
>
> - 不能减少研发的代码量，反而会花费很多精力在编写单元测试上，增加了开发成本，而且对开发人员的要求也会更高。
> - 对于小项目来说，是否执行单元测试意义不大。
> - 单元测试聚焦的是一个模块单元的功能完整性和鲁棒性，但是模块间互动可能带来的问题并不属于单元测试的范畴，同时也有很大部分的界面测试和功能测试仍旧离不开测试工程。



**Q：为什么不用 UI 测试？**
**A：**

- 耗时长。特别是需要运行多个 case 的时候
- 无法测试内部的具体逻辑，比如 URL 是否正确




------



## iOS 上的单元测试

### XCTest 能做什么

XCTest 是 Apple 提供的测试框架，和 Xcode 无缝结合。使用它，可以很方便的进行 **UI 测试，测试点录制，单元测试，性能测试，调试测试点，查看代码覆盖率，集成自动化测试..**

![](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/Art/twx-results-srceditor_2x.png)

![](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/Art/twx-runtst-10_2x.png)

![](http://upload-images.jianshu.io/upload_images/465386-6bfe56ab9062ffb9.gif?imageMogr2/auto-orient/strip)



![2017081632121A35A7F5A-553B-48B0-9608-CD12A98D4CED.png](http://7xkc7a.com1.z0.glb.clouddn.com/2017081632121A35A7F5A-553B-48B0-9608-CD12A98D4CED.png)

![2017081627419EC435EE6-6007-4FD4-BA3C-73C12435D254.png](http://7xkc7a.com1.z0.glb.clouddn.com/2017081627419EC435EE6-6007-4FD4-BA3C-73C12435D254.png)

至于如何使用 XCTest，这不是本文要讨论的内容，直接对照官方文档 [Testing with Xcode](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/01-introduction.html#//apple_ref/doc/uid/TP40014132-CH1-SW1) 就能上手了。



### 应该测试什么

那么，讲了这么久的单元测试，在 iOS 上，我们到底应该要测哪些内容呢？

单元测试侧重的是**逻辑测试和接口测试**。在我看来，以下几部分是可以进行测试的：

- 公共类中的公开方法
- 网络数据层
- 业务逻辑层
- 修复 Bug 的测试

实际操作过程中，要**自下而上**进行。从最基础的 Base 层，往上写测试。确保基础的 Model，Manager 测试通过，才开始为 Controller 编写测试，因为这部分业务是最复杂的，也是最容易改变的。



> PS：编写单元测试需要注意的一点是**责任分离**。即你的测试**只需要针对特定单元内部的逻辑**，至于其他模块是否正确，是由该模块的编写者来负责测试的。
>
> 把这一点应用到实际场景，就能看出 HTTP 通信的实现并不属于我们网络请求类的逻辑。不管是用第三方的 AFNetworking，还是用系统的 NSURLConnection，这些类本身的接口不需要我们来写单元测试。



------



## 可测试的代码（Swift)

先来看一段基本的测试代码：

```swift
func testArraySorting() {
    // Given
	let input = [1, 7, 6, 3, 10]
	// When
	let output = input.sorted()
	// Then
	XCTAssertEqual(output, [1, 3, 6, 7, 10])
}
```



![20170823150345694914363.jpg](http://7xkc7a.com1.z0.glb.clouddn.com/20170823150345694914363.jpg?imageView2/0/format/jpg)



总结来说，测试用例可以按以下三步执行：

1. **Given**：配置测试的初始状态
2. **When**：对要测试的目标执行代码
3. **Then**：对测试结果进行断言（成功 or 失败）

这样我们一眼扫过去就可以清晰的看出一个 case 大体上都在干什么。

> PS：同样一个方法，要写多个测试用例，确保每一种，每一条路径都执行到，特别是边界值。另外 Bugfix 也需要补上对应的 case。确保验证通过。
>
> 另外，确保一个 case 只测试一种情况。可能我们调用的一个 API 内部有一个 if…else…。建议 if 一个case，else 一个 case。分两个不同的 case 来作测试，这样每个 case 就很清晰自己在测试什么东西。当然，如果存在大量的 if…else…，那就要考虑下代码设计上，是否存在问题了。

但是实际上，我们的项目中很少有这样单一，中规中矩的方法。很多时候，项目中难免发生多个类之间的交互处理，耦合度高，而这种操作非常的不好调试。单元测试的原则之一就在于我们用来**测试的代码要求功能很单一**，这其实与良好的代码设计的思想是非常相符的。

那，如何保证每一个方法都是可测试的呢？

下面通过一个例子，来介绍 Swift 应该如何让代码变的可测试：

```swift
class Phone {
    func call(number: String){
        print ("Real phone calling to \(number)")
    }
}
class PersonalAssitant {
    let phone = Phone()
    let bossNumber = "12345678"

    func callBoss(){
        phone.call(number: bossNumber)
    }
}
```

这段代码也很简单，但是，我们要怎么进行测试呢？

```swift
class PersonalAssistantTestClass: XCTestCase {
    func testCallingBoss(){
        let assistant = PersonalAssistant()
        assistant.callBoss()
        
        // Asset ？？
    }
}
```

这里存在这么几个问题：

1. phone，bossNumber 都是不可控的，由 PersonalAssitant 内部自己管理，他们的**耦合度很高**。
2. 我们没法验证 callBoss **是否正确执行**了。
3. 这只是测试用例，难道每次测试，都需要**真正调用** phone.call，给 boss 打电话？（小心人才网）
4. 没法**快速执行**



#### Dependency Injection

为了降低代码本身的耦合，也为了让代码更好测试，这里我们需要引入 DI（Dependency Injection，依赖注入）。

```swift
protocol PhoneProtocol {
    func call(number: String)
}

class Phone: PhoneProtocol {
    func call(number: String){
        print ("Real phone calling to \(number)")
    }
}

class PersonalAssistant {
    let phone: PhoneProtocol
    let bossNumber: String
    
    init(aPhone: PhoneProtocol, myBossNumber: String) {
        phone = aPhone
        bossNumber = myBossNumber
    }
    
    func callBoss(){
        phone.call(number: bossNumber)
    }
} 
```

甚至可以**提供默认值**： 

```swift
init(aPhone: PhoneProtocol = Phone(), myBossNumber: String = "12345678")
```



通过 DI，我们获得了对 phone 和 number 的完全控制，我们可以传人任意的号码，任意的通讯设备，这使得整个代码的扩展性更好了。同时，也解决了我们提到的第一个问题，降低耦合度。

**Q：为什么说这降低了耦合度呢？**

A：这里，依赖注入通过声明 phone 这个属性就可以获得对这个对象的控制权，而对该对象的依赖关系管理、加载、配置都由外部完成。

更具体来说，依赖注入使得你不用关心对象的生命周期，什么时候被创建，怎么创建的，什么时候销毁。只需直接使用即可，对象的生命周期由提供依赖注入的框架来管理。

**总之，依赖注入的意思是你需要的东西不是由你创建的，而是第三方，或者说容器提供给你的。这样的设计符合正交性，即所谓的松耦合。**

上面的前后代码，可以这样比喻：
前：在原始社会里，几乎没有社会分工。需要斧子的人只能自己去磨一把斧子。

后：进入工业社会，工厂出现了，斧子不再由普通人完成，而在工厂里被生产出来，此时需要斧子的人找到工厂，购买斧子，无须关心斧子的制造过程。



#### Mock

至于剩下的三个问题，其实本质上是一个问题，归纳起来就是：如何快速的模拟 phone.call 这个操作，并验证它是否成功调用。

> 有的人可能有疑惑，我们现在是在测 assistant.callBoss 这个方法，但是为什么变成验证 phone.call 是否调用成功？我们之前说过。当前模块的测试，只需要关注该模块本身，所以 phone.call 的测试，应该是 Phone 模块自己需要完成的。所以，如果 phone.call 被正常调用了。 那是不是就变相意味着，assistant.callBoss 这个方法测试通过？（至于调用后，是否拨打成功，这个应该是 Phone 模块应该关心的）



所以，这里我们引入 Mock 这个概念，来完成这个操作。

> 所谓 mock，即模拟出我们想要的内容。

```swift
class MockPhone: PhoneProtocol {
    var wasCalled = false
    
    func call(number: String) {
        wasCalled = true
    }
}

func testCallingBoss() {
    let mockPhone = MockPhone()
    let assistant = PersonalAssistant(aPhone: mockPhone, myBossNumber: "12345678") 
    assistant.callBoss()
    XCTAssertTrue(mockPhone.wasCalled, "Assistant should have called the boss")
}
```

这里我们模拟出了一个专门用来测试的 “Phone”。（它应该声明在 test 文件里。test bundle 的内容，不会包含在正式包里头）。它也实现了 call 方法，但是并不是真正的拨打电话，而是标记已经调用了 call，拨打出去了。这使得，我们的 asset 得以书写。

至此，这个简单的例子，就介绍完了。通过 Protocol 依赖注入，使得我们代码的耦合度更低，扩展性更好，可测试。所以，良好的代码设计是很有必要的。



------



## 自测

如果说，下面一个例子，能通过重构代码，写出对应的 case，那么，我这篇文章也就没白写..

```swift
@IBAction func openTapped(_ sender: Any) {
    let mode: String

    switch segmentedControl.selectedSegmentIndex {
    case 0:
        mode = "view"
    case 1:
        mode = "edit"
    default:
        fatalError("Impossible Case")
    }

    let url = URL(string: "myappscheme://open?id=\(document!.identifier)&mode=\(mode)")!

    if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
        print("url error")
    }
}

// Test
func testOpensDocumentURLWhenButtonIsTapped() {
    let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Preview") as! PreviewViewController
    controller.loadViewIfNeeded()
    controller.segmentedControl.selectedSegmentIndex = 1
    controller.document = Document(identifier: "TheID")

    controller.openTapped(controller.button)
    
    // Asset ??
}
```



Enjoy it～



------



## 参考链接

[Testing with Xcode](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/01-introduction.html#//apple_ref/doc/uid/TP40014132-CH1-SW1)

[What should we Unit Test in our iOS apps?](https://medium.com/practical-ios-development/what-should-we-unit-test-in-our-ios-apps-769d55a2423b)

[Better Unit Testing with Swift](http://masilotti.com/better-swift-unit-testing/)

[Practical Protocol-Oriented-Programming](https://academy.realm.io/posts/appbuilders-natasha-muraschev-practical-protocol-oriented-programming/)



[单元测试准则](https://github.com/yangyubo/zh-unit-testing-guidelines)

[12 个单元测试秘籍和实践](https://www.oschina.net/translate/12-unit-testing-myths-and-practices)

[面向协议编程与 Cocoa 的邂逅](https://onevcat.com/2016/11/pop-cocoa-1/)