title: TDD 学习总结（Swift 实践）
date: 2016-06-03 19:33:40

tags:

- iOS开发
- TDD
- Swift

------

> 花了几天时间，看完了 [《Test-Driven iOS Development with Swift》](https://www.packtpub.com/application-development/test-driven-ios-development-swift) 这本书，虽然只有短短 500页的 epub，但是讲解的很生动透彻，全书围绕一个 `ToDo` 应用展开，讲解了 `Test-Driven Development （TDD，即测试驱动开发）` 的实际应用，让我对 TDD 有了更全面的认识。故此，开坑记录之~

![TDD](http://7xkc7a.com1.z0.glb.clouddn.com/TDDTDDFigure.png)

<!--more-->



## 什么是 TDD

测试驱动开发(TDD)是极限编程的重要特点，它以不断的测试推动代码的开发，既简化了代码，又保证了软件质量。

测试驱动开发的基本思想就是在开发功能代码之前，先编写测试代码。也就是说在明确要开发某个功能后，首先思考如何对这个功能进行测试，并完成测试代码的编写，然后编写相关的代码满足这些测试用例。然后循环进行添加其他功能，直到完全部功能的开发。

OK，概括来说，TDD 的开发过程可以用上图来描述：Red，Green，Refactor。

翻译过来就是：

1. 编写测试用例，测试不通过。（红色 Error）
2. 编写代码实现功能，测试通过。（绿色 Success）
3. 重构优化代码。（Refactor）

再详细点，测试驱动开发的基本过程如下：

1. 明确当前要完成的功能。记录成一个 TODO 列表。
2. 快速完成针对此功能的测试用例编写。
3. 测试代码编译不通过。
4. 编写对应的功能代码。
5. 测试通过。
6. 对代码进行重构，并保证测试通过。
7. 循环完成所有功能的开发。

怎么样，简单吧~



## 是否该用 TDD

简单是简单，但是很明显的，开发前期，工作量绝对不是 1+1 那么简单，那么是否该用 TDD 呢？对此，我不做过多的阐述。世上并没有放之四海皆准的法则，TDD 好坏在于你的判断，方法论的主体在于使用的人，本文并不会给你一个完美的答案，这需要你自己在实践中取舍。接下去，我将列举 TDD 目前公认的一些优缺点，以及使用原则，加深大家对 TDD 的理解。

**TDD 开发的优点：**

- 可以保证代码的质量。可以对自己的所需要的业务功能的每一步设计进行验证，并得到正确的结果，减少bug的出现的，特别对于复杂业务逻辑的项目，以小步慢走的方式，避免后期繁重的测试和维护工作。
- 找到了重构的信心，必要时候你还可以痛痛快快的并且满怀信心的对代码做一场大的变革。这样我们的代码变得干净了，扩展性、可以维护性以及易理解性纷至沓来。
- 在团队建设中能够进行分工，以可执行的形式文档化你的需求，迫使你分清职责隔离依赖以驱动你的设计，编织安全网以便将Bug扼杀在在摇篮状态，防止其逃逸。不同于传统开发（传统的开发人员开发的软件的测试是为了找出已经逃逸得bug，可能这个bug已经长成了毒瘤）。注：这两种活动都是必要的，而且毫不冲突，互为补充。
- 帮助你养成一个新的思维习惯，不光在你编程的道路上，在你的工作和生活中，你慢慢的会把自己的需求进行分析设计并不断地验证，最终更好去实现自己的人生目标。

**TDD 开发的缺点：**

- 对于测试驱动不熟练或者喜欢偷懒的的人员，加大了代码的编写量，测试代码是系统代码的两倍或更多。
- 可能不适合时间很紧的软件开发，更适合于产品和平台的开发。

**TDD 原则：**

- **独立测试：**不同代码的测试应该相互独立，一个类对应一个测试类，一个函数对应一个测试函数。用例也应各自独立，每个用例不能使用其他用例的结果数据，结果也不能依赖于用例执行顺序。 一个角色：开发过程包含多种工作，如：编写测试代码、编写产品代码、代码重构等。做不同的工作时，应专注于当前的角色，不要过多考虑其他方面的细节。

- **测试列表：**代码的功能点可能很多，并且需求可能是陆续出现的，任何阶段想添加功能时，应把相关功能点加到测试列表中，然后才能继续手头工作，避免疏漏。

- **测试驱动：**即利用测试来驱动开发，是TDD的核心。要实现某个功能，要编写某个类或某个函数，应首先编写测试代码，明确这个类、这个函数如何使用，如何测试，然后在对其进行设计、编码。

- **先写断言：**编写测试代码时，应该首先编写判断代码功能的断言语句，然后编写必要的辅助语句。

- **可测试性：**产品代码设计、开发时的应尽可能提高可测试性。每个代码单元的功能应该比较单纯，“各家自扫门前雪”，每个类、每个函数应该只做它该做的事，不要弄成大杂烩。尤其是增加新功能时，不要为了图一时之便，随便在原有代码中添加功能。

- **及时重构：**对结构不合理，重复等“味道”不好的代码，在测试通过后，应及时进行重构。

- **小步前进：**软件开发是复杂性非常高的工作，小步前进是降低复杂性的好办法。

  ​

看到这里，如果你还觉得，有必要体验一把 TDD，那么接着往下看，我将通过一个简单的例子，走一遍 TDD 开发的流程，加深大家对 TDD 的了解，也为 iOS 中应用 TDD 做个入门介绍。



## iOS 中如何使用 TDD

> Apple一直致力于在iOS开发中集成更加方便和可用的测试，在Xcode 5中，新的IDE和SDK引入了XCTest来替代原来的SenTestingKit，并且取消了新建工程时的“包括单元测试”的可选项（同样待遇的还有使用ARC的可选项）。新工程将自动包含测试的target，并且相关框架也搭建完毕，可以说测试终于摆脱了iOS开发中“二等公民”的地位，现在已经变得和产品代码一样重要了。  —————— 喵神

简单 Mark 下 TDD 在 Xcode 中的历程：

- In 1998, the Swiss company Sen:te developed OCUnit, a testing framework for Objective-C (hence, the OC prefix). OCUnit was a port of SUnit, a testing framework that Kent Beck had written for Smalltalk in 1994.
- With Xcode 2.1, Apple added OCUnit to Xcode.
- In 2008, OCUnit was integrated into the iPhone SDK 2.2 to allow unit testing of iPhone apps.
- Four years later, OCUnit was renamed XCUnit (XC stands for Xcode).

既然 Xcode 为我们内置了这么方便的 XCTest，我们没理由不好好使用阿~

接下去通过实现一个简单的功能：把句子中每个单词的首字母转成大写字母，来走一遍 TDD 的流程。话不多说，开车了~



### 1. 创建工程

这里创建一个常规的 iOS 工程，记得 `“ Include Unit Tests” ` 即可，语言我们选择 `Swift`。

![demo_0](http://7xkc7a.com1.z0.glb.clouddn.com/TDDdemo_0.jpeg)



创建完毕后的工程目录如下：

![demo_1](http://7xkc7a.com1.z0.glb.clouddn.com/TDDdemo_3.jpeg)

默认为我们创建了 `TDDDemoTests.swift` 文件，这里就是我们编写测试用例的地方。打开该文件，如下所示：

```swift
//
//  TDDDemoTests.swift
//  TDDDemoTests
//
//  Created by Colin on 16/6/3.
//  Copyright © 2016年 Colin. All rights reserved.
//

import XCTest
@testable import TDDDemo

class TDDDemoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
```

其中，有几个地方需要说明一下：

```swift
import XCTest
@testable import TDDDemo
```

每一个测试用例都需要引入 `XCTest` 框架，它定义了我们需要的 `XCTestCase` 类，以及之后会用到的一些断言，比如 `XCTAssertEqual` 等。另外，还需要手动导入 `TDDDemo` 模块，我们之后的相关代码都会在 `TDDDemo` 中编写，但是默认情况下，类，结构体，枚举以及它们的方法，都是内联的（`internal`），这意味着它们所处模块外无法直接访问到它们。所以在此之外的测试代码无法访问到它们，故而需要使用 `@testable` 关键字来让测试代码能访问它们。

再看 `setUp` 方法和 `tearDown` 。在每个测试用例调用前，都会先调用 `setUp` 方法，在每个测试用例执行结束后，都会调用 `tearDown` 方法，大体流程就是：setUp — test case — tearDown — setUp — test case — tearDown …. 所以我们一般在 `setUp` 中做一些初始化操作，在 `tearDown`  做一些清除释放操作。

另外，每一个测试方法都需要以 `test` 开头，这样 Xcode 才能自动识别出它。比如默认提供的 `testExample` 和 `testPerformanceExample` 。



再有，这里建议在 Bulid 开始的时候，新建一个导航栏，并且打印 Build Log，这样我们能更直观知道发生了什么，哪里出错了。具体设置如下： **Xcode | Preference | Behaviors** 

如图所示：

![demo_2](http://7xkc7a.com1.z0.glb.clouddn.com/TDDdemo_1.jpeg)

现在 **Command + U**，执行测试。毋庸置疑，测试通过（毕竟啥都还没开始写…）。你会看到如下界面：

![demo_3](http://7xkc7a.com1.z0.glb.clouddn.com/TDDdemo_4.jpeg)

左边的  **Test Navigation** 列举了所有的测试用例以及对应的测试结果。中间的编辑区展示了 **Bulid** 过程中具体做了什么，以及 **Build** 结果。



哦，对了。还有一处设置也很有用。

**Edit Scheme | Test** ，可以看到右边列举了所有参与测试的用例。当然我们知道，每个用例的测试都是需要时间的，如果想对某个用例单独测试，或者不想测试某个用例，相应的勾选和去选就可以了。

![demo_4](http://7xkc7a.com1.z0.glb.clouddn.com/TDDdemo_5.jpeg)



### 2. 编写测试用例

好了，万事俱备，是时候展示真正的技术了！

删除默认的 `TDDDemoTests.swift` 文件，重新创建一个 `CapitalTest.swift` 文件。在 `TDDDemoTests` 分组中，**File | New | File | iOS | Source | Unit Test Case Class** ，创建一个名为 **CapitalTest** 并 继承自 **XCTestCase** 的类。如图所示：

![demo_5](http://7xkc7a.com1.z0.glb.clouddn.com/TDDdemo_6.jpeg)



删掉无用的 **testExample，testPerformanceExample** 方法。

引用 **TDDDemo** 类。

```swift
@testable import TDDDemo
```

编写测试用例：

这里我们要做的是实现句子中单词首字母的大写转换，所以只要写个测试用例验证首字母是否都是大写即可。

```swift
    func testMakeHeadline_ReturnsStringWithEachWordStartCapital() {
        
        let viewController = ViewController()
        
        let string = "this is A test headline"
        let headline = viewController.makeHeadline(string)
        
        XCTAssertEqual(headline, "This Is A Test Headline")
    }
```

很简单，我们希望有这样一个函数 `makeHeadline`，它接受一个 **String** 类型的参数，并返回转换成功的  **String** 类型的结果。然后利用 `XCTAssertEqual` 判断一下，当左右值相同时，它才会通过。

很显然，这个时候会保持，且测试不通过，因为我们的 `makeHeadline` 函数根本就不存在，现在就去实现它。

回到 **ViewController.swift** 中，添加如下方法。

```swift
    func makeHeadline(string: String) -> String {
        
        return "This Is A Test Headline"
    }
```

**Command + U** 走一遍，恭喜你，测试走通了。全部显示绿色的 Build succeeded。（眼尖的朋友可能发现问题了，不过不急，至少目前为止，我们的测试用例已经通过了~）

然后接下去，做的就是重构了。虽然只写了几行代码，但是还是有优化空间的。

我们之前提到过，**setUp** 方法将在每个 **test case** 调用前都自动被调用，所以这里可以放一些初始化相关操作。我们这里初始化了一个 **ViewController** 类型的对象，不出意外的话，在每个测试用例中中需要初始化一个，这无疑是很麻烦的。所以我们可以把 **viewController** 提出来，当做 **CapitalTest** 类的一个属性，然后在 **setUp** 方法中去初始化它。具体如下：

```swift
class CapitalTest: XCTestCase {
    
    var viewController: ViewController!

    override func setUp() {
        super.setUp()
        
        viewController = ViewController()
    }
    
	/////////
}
```

接下去，我们需要在编写另外一个测试用例，以保证第一个测试用例并不是偶然的。这也是我们在实际开发中需要做的，列举多个测试用例，来保证某个功能确实通过了。

```swift
    func testMakeHeadline_ReturnsStringWithEachWordStartCapital2() {
        
        let string = "Here is another Example"
        let headline = viewController.makeHeadline(string)
        
        XCTAssertEqual(headline, "Here Is Another Example")
    }
```

再次 **Command + U**，不出意外，第一个还是通过，第二个则显示失败。原因大家都懂~

接下去修改 `makeHeadline` 的具体实现：

```swift
    func makeHeadline(string: String) -> String {
        
        // 1. 通过“ ”分割字符串, 存入数组
        let words = string.componentsSeparatedByString(" ")
        
        // 2. 遍历数组, 移除首字母, 并插入对应的大写字母
        var headline = ""
        for var word in words {
            let firstCharacter = word.removeAtIndex(word.startIndex)
            headline += "\(String(firstCharacter).uppercaseString)\(word) "
        }
        
        // 3. 移除最后的“ ”
        headline.removeAtIndex(headline.endIndex.predecessor())
        return headline
    }
```

代码很简单，注释也写的很清楚，这里就不累述了。再次 **Command + U**，bingo~ 通过了。

接下去再看看，是否有优化的空间。

1. 我们的测试用例描述的其实不太清楚，几个变量之间的关系比较凌乱。
2. **makeHeadline** 函数的实现太 Objc 化了，没有用上 Swift 里的高级功能。

OK，既然不好，那就优化一下呗~

```swift
func testMakeHeadline_ReturnsStringWithEachWordStartCapital() {

        let inputString =       "this is A test headline"
        let expectedHeadline =  "This Is A Test Headline"
        
        let result = viewController.makeHeadline(inputString)
        XCTAssertEqual(result, expectedHeadline)
    }
    
func makeHeadline(string: String) -> String {

        let words = string.componentsSeparatedByString(" ")
        
        let headline = words.map { (var word) -> String in
          let firstCharacter = word.removeAtIndex(word.startIndex)
          return "\(String(firstCharacter).uppercaseString)\(word)"
          }.joinWithSeparator(" ")
        
        return headline
    }
```



再次  **Command + U**，确保测试通过。至此，这个简单的例子算是介绍完了。

虽然例子简单，只实现了一个功能，但是 TDD 相关的东西，具体流程也都涉及了，剩下的，只是重复这些操作直至完成所有需求。



如果觉得这个例子太简单了，没学够，建议看下 [《Test-Driven iOS Development with Swift》](https://www.packtpub.com/application-development/test-driven-ios-development-swift)  一书中的 [ToDo 源码](http://www.packtpub.com/code_download/23832)，大篇幅介绍 TDD 的实际应用。



Have Fun~

## 参考链接



由衷感谢以下作者的贡献，文中出现的一些理论阐述，有从相关文章中摘取。

[TDD的iOS开发初步以及Kiwi使用入门](https://onevcat.com/2014/02/ios-test-with-kiwi/)

[浅谈测试驱动开发（TDD）](http://www.ibm.com/developerworks/cn/linux/l-tdd/index.html)

[TDD(测试驱动开发)培训录](http://www.cnblogs.com/whitewolf/p/4205761.html)

[《Test-Driven iOS Development with Swift》](https://www.packtpub.com/application-development/test-driven-ios-development-swift) 

