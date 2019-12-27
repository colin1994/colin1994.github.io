title: iOS 内存调试技巧

date: 2019-12-27 21:25:12

tags:

- iOS开发
- 性能优化

------



**前言：**

本文会介绍如何快速定位、解决内存问题的一些技巧，如下：

- signal SIGABRT，EXC_BAD_ACCESS，Memory Leak 问题
- Breakpoint，Zombie Objects，Address Sanitizer，Instruments，Malloc Stack，Debug Memory Graph，Analyze 的正确使用姿势



<!--more-->

----------------

前一阵遇到了一个 EXC_BAD_ACCESS 问题，概率性出现，不太好定位。

最后通过 Address Sanitizer，分分钟解决，那酸爽～

顺便总结下平时会遇到的一些内存相关问题，可能是直接崩溃，也有可能是概率性崩溃，当然最常见的还是未正常释放对象引起的内存占用等问题。

文末有本文配套的实验 Demo。



工欲善其事，必先利其器～

> PS：
>
> 本文是针对真机调试下，遇到了内存问题，如何快速定位。
>
> 当然，内存相关的问题，绝不仅仅如此，包括内存如何分配，如何降低内存占用，OOM 等。
>
> 这，又是另外一个故事了，我们以后再讲。



[TOC]

------



## 1. SIGABRT 

> 建议查错方式：Breakpoint

SIGABRT 类的问题，基本上都能定位到，因为系统明确捕获并提示，你的 App 发生了错误。

虽然很简单… 但作为一个系列，顺带提一下。

iOS 中发生 SIGABRT，内存方面一般表现为**越界，访问没有初始化的地址或者错误地址**。

举个最最最最简单的例子：

```objective-c
NSArray *array = [NSArray new];
id object = [array objectAtIndex:0];
```

这里很明显越界了，App 崩溃，并且报错：

 **-[__NSArrayM objectAtIndex:]: index 0 beyond bounds for empty array'**

![](https://diycode.b0.upaiyun.com/photo/2018/0acfe0738b89e0ca8fa23d9dfc07a0f7.png)

报错是报错了，但是我们看左边的调用栈，指向了无用的 **main**，并没有定位到我们的具体代码。



### image lookup

**First throw call stack** 里输出的调用栈，但是并没有符号化，无法直接阅读。

当然，如果要解析，也是可以借助 **image 寻址** 来实现，如下：

```shell
(lldb) image lookup --address 0x1001b26c0
      Address: MemoryDemo[0x00000001000066c0] (MemoryDemo.__TEXT.__text + 136)
      Summary: MemoryDemo`-[ViewController viewDidLoad] + 136 at ViewController.m:22
```

可以看到，能够定位到具体的代码。但是这就显得比较麻烦了。



### Breakpoint

这时候，可以通过添加一个**全局异常断点**，来定位问题：

**Breakpoint navigator —> Create a breakpoint —> Exception Breakpoint**

![](https://diycode.b0.upaiyun.com/photo/2018/d2eeac8a9191821408b766173a999b03.png)

重新运行，效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/4b59bcc47632d624c95e0bf6312587ef.png)

当然，**Exception Breakpoint** 的作用远远比这个强大。建议移动到用户组下，便于所有工程都开启。

![](https://diycode.b0.upaiyun.com/photo/2018/e3ae446259bab722d2d0d4102c121a12.png)



----



## 2. EXC_BAD_ACCESS

> 建议查错方式：Zombie Objects & Address Sanitizer



**EXC_BAD_ACCESS，意味着向某块内存发送消息，但是该内存无法响应对应的消息指令。**

> In summary, when you run into EXC_BAD_ACCESS, it means that you try to send a message to a block of memory that can't execute that message.

通常，我们遇到的大多数情况下都是**向一个已释放的对象发送消息。**这在 MRC 时代比较常见，但不代表 ARC 中不会有这样的问题。

为了方便模拟，我们在 MRC 环境中测试。



### Zombie Objects

添加如下代码：

```objective-c
@implementation MRCObject

- (void)zomibleObjectsTest {
    NSObject *obj = [NSObject new];
    [obj release];
    [obj release];
}

@end
  
  
// 测试代码
MRCObject *mObject = [MRCObject new];
[mObject zomibleObjectsTest];
```

运行后，效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/f2bad3956fa42bc5895a2d9dd653375a.png)

可以看到，报了 **EXC_BAD_ACCESS**，也定位到了具体代码。但是，并没有相关的崩溃说明。如果直接排查问题，是比较麻烦的（这里的 MRC 代码很简单，但是实际项目中，要比这复杂的多）。

这时候，就可以借助 **Zombie Objects** 来辅助调试。

**Edit Scheme —> Diagnostics —> Memory Management —> Zombie Objects。**

开启后，再次运行，效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/da3bb9bf6abfe0a7cd8a8aa88fd3d9e9.png)

**-[NSObject release]: message sent to deallocated instance 0x1c400e180**

很明确的告诉我们，向一个已释放的对象（0x1c400e180）发送了 release 消息。

并且，我们可以在左侧 Variables View 面板中，找到 0x1c400e180 代表的对象，

![](https://diycode.b0.upaiyun.com/photo/2018/cec011abe2fbe37dc68fc20f4fc0f5ef.png)

那这里，我们可以知道，是 obj 这个对象被释放后，又向他发送 release 消息引起的崩溃。
这时候，就可以愉快的、针对性的解决问题啦～



不过，不知道大家有没有注意到。我们的 obj 对象，类型明明是 NSObject，为什么变成了 `_NSZoombie_NSObject` ？



#### Zombie Objects 实现原理



为了解释这个问题，我们顺带讲下 Zombie Objects 的官方实现原理。



通过在 [CFRuntime.c](https://opensource.apple.com/source/CF/CF-1153.18/CFRuntime.c) 中查阅源码，搜索 Zombie，发现了疑似相关的定义**__CFZombifyNSObject** ：

![](https://diycode.b0.upaiyun.com/photo/2018/a303bb190dd30a3fc5903c09972acd31.png)

回到项目中，加上对应的**符号断点**，尝试查看内部具体实现。

![](https://diycode.b0.upaiyun.com/photo/2018/4ab3b7e323fb386b3e51d71fb78c788f.png)



![](https://diycode.b0.upaiyun.com/photo/2018/9f387d4a88f6ab3bafee3ae4405b7b65.png)



再次运行后（保持 Zombie Objects 开启），可以发现 __CFZombifyNSObject 确实被调用了。

![](https://diycode.b0.upaiyun.com/photo/2018/e59258b1f725abe64ed59f9773077dc3.png)

虽然是汇编代码，但是配合右侧的注释，可读性非常高。

有用过 Method Swizzling 的，相信对这块的实现都不陌生，就不累述。总结来说，__CFZombifyNSObject 做了这么一件事：

```objective-c
将 NSObject 的 dealloc 方法，替换成 __dealloc_zombie 来实现。
```

既然如此，我们继续添加一个符号断点：-[NSObject __dealloc_zombie]，来看看它内部的实现。

![](https://diycode.b0.upaiyun.com/photo/2018/cf1c32f5b3b5fc63b68e122a2d6be84f.png)

到这里，整个实现就很明朗了，虽然稍微复杂了点，但是还是能从中获取一些信息的。

大致流程翻译过来，就是：

* 判断是否开启 __CFZombieEnabled
* object_getClass，class_getName 获取当前对象类名
* 通过 asprintf，把格式化后的数据（`_NSZombie_%s`）写入某个字符串缓冲区，做为新类名
* 通过 objc_lookUpClass，查找新类名的类是否存在，不存在，则往下创建
* 通过 objc_lookUpClass，获取名为 `_NSZombie_` 的类。这个类比较特殊，里面没有实现任何的方法
* 通过 objc_duplicateClass，复制  `_NSZombie_` 类，生成新的 `_NSZombie_%s` 类
* 通过 object_setClass，将当前对象的类型设置成新的 `_NSZombie_%s` 类


至此，原先的对象，类型已经被替换成 `_NSZombie_%s`  了，而这个类没有实现任何方法，所以往该对象发送任何消息的时候，必定会崩溃，从而被 Xcode 捕获到。

这就解释了为什么会有个 `_NSZoombie_NSObject` 类型对象的问题。

> PS：
>
> 总结 Zombie 的实现，是 Swizzling NSObject 的 dealloc 方法，创建一个不包含任何方法的 class 将原来的 class 内存内容替换掉，即用生成僵尸对象来替换 dealloc 的实现，当对象引用计数为 0 的时候，将需要 dealloc 的对象转化为僵尸对象。如果之后再给这个僵尸对象发消息，则抛出异常，并打印出相应的信息，这样调试者可以很轻松的找到异常发生位置。 



-----

###  Address Sanitizer

绝大多数情况下，EXC_BAD_ACCESS 问题，我们都可以通过 Zombie Objects 来定位到。但也有些时候，Zombie Objects 就显得比较无力。

测试下下面这段代码：

```objective-c
char *buffer2 = malloc(80);
buffer2[90] = 'Y';
free(buffer2);
```

这段代码，我们看过去，是很明显存在问题，越界访问了无效的内存区域。
但实际上，90% 是不会产生 Crash，就算产生 Crash 也不会在具体代码处指明错误，并打印错误 Log。如下：

![](https://diycode.b0.upaiyun.com/photo/2018/9d75c3e11ffbe331ecdc04878b81ea6f.png)

熟悉的 main...

> PS：
>
> 开头提到了，前一阵我遇到的一个概率性崩溃问题。就是这种类型的。
>
> 在 memcpy 的时候，前后内存块大小不一致引起，大致代码就是：
>
> ```objective-c
> char a[YLZ_FACE_COUNT], b[YLZ_S_FACE_COUNT];
> memcpy(a, b,sizeof(b));
> ```
>
> YLZ_FACE_COUNT 和 YLZ_S_FACE_COUNT 是两个宏定义（为了说明，随便命名的），值不一样，但是本身命名又非常接近，导致 Xcode 自动补全的时候，不小心就会选择错。
> 而这又是概率性的崩溃，就很难定位到问题了。




这时候，如果开启 Zombie Objects，也是一样的，无法快速定位到具体问题。原因就是 Zombie 设计本身，在 malloc 对象和内存越界方面，几乎无能为力。

这时候，**Address Sanitizer** 就要派上用场了。

首先，开启 Address Sanitizer。

**Target —> Edit Scheme —> Diagnostics —> Runtime Sanitization —> Address Sanitizer**

再次运行，效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/64ceaf926ad32fdf6876bdb69c726afb.png)

定位到了具体代码，同时也说明了崩溃原因：**Heap buﬀer overﬂow**，溢出了。

于是，就可以再次愉快的、针对性的解决问题啦～

十分强大！



#### Address Sanitizer 介绍

那么，**Address Sanitizer** 是什么？

> Address Sanitizer 是 Xcode7 中最早引入的  Runtime Tool，它用于发现内存问题。比如野指针 EXC_BAD_ACCESS ，内存越界等问题。



在 Xcode9 之前，Address Sanitizer 就已经支持的错误检查包括：

- Use-after-free
- Heap buﬀer overﬂow
- Stack buﬀer overﬂow
- Global variable overﬂow
- Overﬂows in C++ containers
- Use-after-return

这里再额外介绍 **Use-after-free** 的情况，即常见的野指针问题，访问已释放的内存区域。官方的例子如下：

![](https://diycode.b0.upaiyun.com/photo/2018/b0d1be3eba365442aba1994f93fff289.png)

可以看到，Address Sanitizer 检测到了内存问题 — **Use of deallocated memory**，同时在 Issue ⾯板，可以看到 Memory 具体情况。Address Sanitizer 会告诉我们对象创建和销毁的调用栈。这就很方便我们定位，哪里不小心释放了对象，哪里又访问了不该访问的对象。问题自然迎刃而解 ～



#### Address Sanitizer 原理 / vs  Zombie Objects

那么，**Address Sanitizer 和之前提到的 Zombie Objects 有什么区别？**

一句话，**Address Sanitizer 比 Zombie 更强大，适用性更广！特别在 malloc 对象方面。**

Address Sanitizer 的原理是当程序创建变量分配一段内存时，将此内存后面的一段内存也冻结住，标识为中毒内存（poisoned memory）。如图所示，黄色是变量所占内存，紫色是冻结的中毒内存。

![](https://diycode.b0.upaiyun.com/photo/2018/fb36e9331bebaeea0f615a9a5d55d54e.png)

当程序访问到中毒内存时（buﬀer overﬂow），就会抛出异常，并打印出相应 Log 信息。调试者可以根据中断位置和的 Log 信息，定位问题。如果对象释放了，对象所占的内存也会标识为中毒内存，这时候访问这段内存同样会抛出异常（Use-after-free）。 

Xcode 9 中， Address Sanitizer 可以检测到两种新的内存问题：use-after-scope 和 use-after-return。并且在日常的 Debug 过程中，也能直接查看对象对应的内存信息。顺带再提一下：



#### use-after-scope/return

> PS：
> 如果要检测 use-after-return，需要额外勾选 "Detect use of stack after return” 选项。


![](https://diycode.b0.upaiyun.com/photo/2018/b68e92404ea5bda1618a5c491336213a.png)

![](https://diycode.b0.upaiyun.com/photo/2018/86443c1c38335d329dcad444c9507a3d.png)

出了 Scope 或者 Function 后，局部变量被删除，对应的内存区域被释放回收。如果没有改变相关指针的值，即该指针仍然指向原来的内存地址，那这指针就变成了野指针（迷途指针），它指向的内存地址是不确定的。这类问题，通过 Address Sanitizer 则可很容易发现。



#### Compatible with Malloc Scribble

在日常的 Debug 过程中，也能直接查看对象对应的内存信息，并持续观察它的内存变化情况，如下一个简单的测试代码：

```objective-c
NSObject *testObject = [NSObject new];
testObject = nil;
```

在执行 testObject = nil，之前，打个断点，右键左侧 Variables View 面板中的 testObject 对象，选中 View Memory of 添加内存观察。

![](https://diycode.b0.upaiyun.com/photo/2018/7bd12f2a8d41641b0af30681047172c3.png)

添加后，会看到这样的界面：


![](https://diycode.b0.upaiyun.com/photo/2018/73417491b12130d4656db1fbb03169a5.png)

左侧显示了对象创建和销毁的调用栈。右侧显示了对应内存地址具体的内容。其中，白色高亮的是为对象分配的实际内存。灰色则是之前提到的中毒内存（poisoned memory），Address Sanitizer 则会检测是否异常访问了这部分灰色内存。

点击左侧的调用栈，能准确定位到具体的代码，如下

![](https://diycode.b0.upaiyun.com/photo/2018/53e47107698b13f25a165750b15e0f5d.png)

断点继续执行，释放 testObject 对象。这时候，多了销毁的调用栈。


![](https://diycode.b0.upaiyun.com/photo/2018/0035e0d05ebe0a8c133282dd5c2443da.png)

另外，在看下原先内存地址对应的具体内容都已经置灰了。

![](https://diycode.b0.upaiyun.com/photo/2018/c60b0636ba6f611265d67deb17385479.png)

> PS：
>
> 不知道有没有发现释放前后的内存地址不太一样.. （没发现就算了～）
>
> 其实是写 Demo 过程，稍微出了点差错，不小心把工程关掉了。导致截图前后不是同一次运行..



Address Sanitizer 就先介绍到这里，更多的功能，需要大家在实际使用过程中去发掘。

-----



## 3. Memory Leak

> 建议查错方式：Instruments & Malloc Stack & Debug Memory Graph



Memory Leak，内存泄漏，概括来说就是，你希望某个对象释放掉的时候，它没有按照预想被释放掉，导致不必要的内存占用。Leak 产生的方式很多，最经常遇到的应该就是 Retain Cycle，循环引用引起的。

至于为什么会产生泄漏，就不累述了，这里简单举两个例子，说明不同情况下的解决方案。



### Retain Cycle

新建 LeakViewController，在现有的 ViewController 中添加一个按钮，执行 Push 到 

LeakViewController 的操作。

YLZNetworkFetcher 是一个网络请求管理类，有个 block 返回请求结果。

```objective-c
// YLZNetworkFetcher.h
#import <Foundation/Foundation.h>

typedef void (^YLZNetworkFetcherCompletionHandler)(NSData *data);

@interface YLZNetworkFetcher : NSObject

@property (nonatomic, strong, readonly) NSURL *url;

- (id)initWithURL:(NSURL *)url;
- (void)startWithCompletionHandler:(YLZNetworkFetcherCompletionHandler)completion;

@end;


//  YLZNetworkFetcher.m
#import "YLZNetworkFetcher.h"

@interface YLZNetworkFetcher ()

@property (nonatomic, copy) YLZNetworkFetcherCompletionHandler completionHandler;

@end

@implementation YLZNetworkFetcher

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _url = url;
    }
    return self;
}

- (void)startWithCompletionHandler:(YLZNetworkFetcherCompletionHandler)completion {
    self.completionHandler = completion;
}

@end

//  LeakViewController.m
#import "LeakViewController.h"
#import "YLZNetworkFetcher.h"

@interface LeakViewController ()

@property (nonatomic, strong) YLZNetworkFetcher *networkFetcher;

@end

@implementation LeakViewController

- (void)dealloc {
    NSLog(@"ylz -- dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *url = [[NSURL alloc] initWithString:@""];
    _networkFetcher = [[YLZNetworkFetcher alloc] initWithURL:url];
    [_networkFetcher startWithCompletionHandler:^(NSData *data) {
        NSLog(@"%@", _networkFetcher);
    }];
}

@end
```

运行后，来回 Push 几次，发现 LeakViewController 的 dealloc 始终没有调用，没有 Log 输出，很明显，这里发生了内存泄漏。

当程序复杂到一定程度的时候，很难从某个 .m 文件中，直接找到哪个地方发生泄漏了。这时候工具就要派上用场了。

Instruments 应该是之前大家用到最多的工具了。而这类的泄漏，Instruments 也能很好的帮我们定位到。运行 Instruments 后，效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/d77eaaeee301991086b394b074c6331c.png)



红色的 X，表示捕获到了内存泄漏。点击下面的 Leaks 面板，这类的循环引用问题。会有很详细的说明和对应的图表。我们可以很清楚的看到，LeakViewController 和  YLZNetworkFetcher 之间形成了闭环，相互持有，导致都释放不了。

那么，继续愉快的打破闭环吧～



不过 Leaks 里面，如果被判定是循环引用，就会在 Cycles & Roots 面板里面展示，反而 Call Tree 面板里面找不到相关的信息（也有可能是我姿势不对），没法直接跳到对应产生问题的代码处。

而 **Debug Memory Graph**，则可以很方便的解决这个问题。

> Debug Memory Graph 是 Xcode8 开始加入的一项功能，它把原先就支持的一些指令，比如 heap AppName、leaks AppName、malloc_history AppName Address 等整合起来，提供可视化界面，方便使用。

所以，使用它的时候，真的非常简单。

建议先开启 **Malloc Stack，它会记录每个对象的内存分配历史，扩展 Debug Memory Graph 的能力。**

开启方式：

**Target —> Edit Scheme —> Diagnostics —> Logging —> Malloc Stack。**

然后在 Xcode 中调试 App 的时候，随时点击 Debug Memory Graph 按钮即可。

![](https://diycode.b0.upaiyun.com/photo/2018/6cccd7a46a7939782739cdb6f1596d78.png)

针对上面那个例子，会出现这样的界面：

![](https://diycode.b0.upaiyun.com/photo/2018/f433b8de61376746bdf0551f8fd92bb1.png)

这里可以讲的内容比较多，我们按序说明下。

第一个，左下角的过滤面板：

* 左侧输入框，输入对应类名，可以很方便过滤
* 右侧第一个按钮，**show only leaked blocks**，只显示被判定为泄漏的对象
* 右侧第二个按钮，**show only content from workspace**，只显示当前工程相关



筛选后，第二个面板，就列出了相关的泄漏点。

第三个面板，详细展示了对应的持有关系。 一般我们会关注 capture 这种类型，80% 的泄漏只要解决这块，就能修复。

第四个面板，就是 Debug Memory Graph + Malloc Stack 强大的地方。在第三个面板中，我们看到一个 block 持有了 LeakViewController，但是这个 block 是什么？什么时候持有的？点击后，右侧的 Backtrace 就会很清楚的展示这整个过程。点击后也是跳到具体的代码处，十分强大。

这个例子，比较简单，看起来没什么，但是实际项目中，遇到的一般是这样的：

![](https://diycode.b0.upaiyun.com/photo/2018/261bbf716c6835ca66550a556b0fc8d4.png)

没有具体的变量名，没有具体的类名，这定位起来头就大了。

![](https://diycode.b0.upaiyun.com/photo/2018/02d8fda379f107b5292c91d14d7b7e96.png)

但是当你发现， Malloc Stack 能显示完整调用栈的时候，那感觉真的是没法形容...



### Not Release

最后再提一种情况，单纯的没有释放，可能 VC 的 dealloc 走了，但是某块内存没有释放。

比如下面这段代码：

```objective-c
int size = 1024 * 1024 * 30;
char *pData = malloc(size);
for (int index = 0; index < size; index++) {
    pData[index] = 'Y';
}
```

反复进入，你会发现 dealloc 触发了，但是内存却是不断上升。

![](https://diycode.b0.upaiyun.com/photo/2018/9ff20135385f8a5e746d092d0c994e51.png)



这种泄漏，一般不容易发现，除非你有没次都对比内存占用的好习惯。

这时候，如果用 Instruments 查看，你会发现一个神奇的现象，没有泄漏报错，同时内存占用一直没有上升。

![](https://diycode.b0.upaiyun.com/photo/2018/3da8282d7fdd60499f5d434fd6535b62.png)

这就很可怕了..  我们知道，malloc 出来的，是需要手动 free 的，否则就会引起不必要的内存占用。

那上述的表现是为什么呢？

区别在于，我们使用 Xcode 联调的时候，是在 Debug 模式，但是 Instruments Profile 的时候，是在 Release 环境下，而 Release 默认是开启编译优化的，这部分代码，实际会被优化掉，导致看起来没有问题。

![](https://diycode.b0.upaiyun.com/photo/2018/084aa2bc17dd02a89d32154355376369.png)

所以有时候，Debug 和 Release 环境下，表现会有差异，多半是因为这个原因。



但我们当然是不希望自己的代码，被默认优化，而屏蔽了可能存在的问题，所以，Debug Memory Graph 又要派上用场了。效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/cf11cf089774f12e50a326d0f44ff868.png)

![](https://diycode.b0.upaiyun.com/photo/2018/81ef085129e0064fd607a26169643a1c.png)

自动发现了 30 * 4 = 120M 的内存泄漏，并且指出了对应的代码。很舒服有没有～



-------



## 4. Analyze

最后介绍一个不太一样的工具，Analyze，它是编译时静态分析，通过分析代码，自动找出可能存在问题的地方。

使用方式：

**Product —> Analyze（Shift + Command + B）**

运行一下我们这个漏洞百出的 Demo，效果如下：

![](https://diycode.b0.upaiyun.com/photo/2018/d57e3914d6658d82a751997965e01b75.png)

虽然没能把所有问题都找出来，但是还是有一定的参考价值。



------



## 总结

写到这里，长舒一口气… 

这篇三十多张配图的文章，前前后后花了两个周末完成。

内容虽然说不上多么高深，但针对内存调试这块，相信很难找到这么全面的了。

希望，能有所收获。



文中的示例程序，已经放到 [iOS-Memory-Debug](https://github.com/colin1994/iOS-Memory-Debug) 上了，可以下载下来实际操作一番。方便的话，来个星星也是极好的。



再往后，如果可能的话，我们再聊聊降低内存占用，OOM 定位等问题～

----------




## 延伸阅读

[Advanced Debugging and the Address Sanitizer](https://developer.apple.com/videos/play/wwdc2015/413/)

[Finding Bugs Using Xcode Runtime Tools](https://developer.apple.com/videos/play/wwdc2017/406)

[What Is EXC_BAD_ACCESS and How to Debug It](https://code.tutsplus.com/tutorials/what-is-exc_bad_access-and-how-to-debug-it--cms-24544)

