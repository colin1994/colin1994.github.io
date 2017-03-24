layout: "代码备忘"

title: TODO宏实现

date: 2015-07-12 10:14:52

tags:

- iOS开发
- 宏

---

# 代码备忘, TODO宏实现

> 我们平时在开发过程中, 往往并不是憋足气一股脑敲完全部代码。每个模块, 每个函数的实现总有个先后顺序。又或者哪个部分需要做调整, 修改... 所以, 我们需要有一个东西, 来提醒我们, 起到代码备忘功能, 避免某个功能忘记实现, 也能让我们快速定位。 所以这篇文章, 就是要实现一个TODO宏, 来达到代码备忘功能。

**效果如下:**

<img src="http://img.my.csdn.net/uploads/201503/15/1426387345_9339.jpeg" width="500"/>

<img src="http://img.my.csdn.net/uploads/201503/15/1426387346_3643.jpeg" width="500"/>



<!--more-->

## **下面来分析下如何实现这个宏**



************

在实现TODO之前, 已经自带了几个预处理指令来实现报警/报错:

``` objc
#warning Colin
#error Colin
#pragma message "Colin"
#pragma GCC warning "Colin"
#pragma GCC error "Colin"
```

**效果如下:**

<img src="http://img.my.csdn.net/uploads/201503/15/1426387346_8391.jpeg" width="500"/>

既然有了, 那为什么还需要自己实现这个TODO宏呢?

1. error 和 warning所代表的意义已经深入猿心, 我们没有理由使用它来做备忘。
2. 如果也使用warning, 在警告导航栏中, 我们很难区分哪个才是我们手动打的标记, 哪个是程序本身的warning
3. 带#的预处理指令是无法被#define的, 也就是没办法直接利用这个来定义我们的TODO

好在C99提供了一个 **_Pragma** 运算符可以把部分#pragma指令字符串化, 如下:



``` objc
#pragma message "Colin"
// 等价于
_Pragma("message \"Colin\"") // 需要注意双引号的转义
// 或
_Pragma("message(\"Colin\")") // 需要注意双引号的转义

```

利用这个特性，我们就可以将warning定义成宏:

``` objc
#define MY_WARNING _Pragma("message (\"警察临检, 男左女右!\")")


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    MY_WARNING
}
```

**效果如下:**

<img src="http://img.my.csdn.net/uploads/201503/15/1426387346_6563.jpeg" width="500"/>

到这里, 大体有那么一个感觉。 不过我们提示的内容, 是define的, 也就是写死固定的, 不太合适。

所以我们希望这个宏能接受入参, 让它正常显示到warning中。

这就涉及了一些宏的基本用法。



``` objc
#define STRINGIFY(S) #S
#define PRAGMA_MESSAGE(MSG) _Pragma(STRINGIFY(message(MSG)))

```

STRINGIFY(S) 将入参转化成字符串，省去了_Pragma中全串加转义字符的困扰。

**效果如下:**

<img src="http://img.my.csdn.net/uploads/201503/15/1426387347_2653.jpeg" width="500"/>



这时，一个基本功能的TODO宏就完成了，下面向其中加入额外的信息：

``` objc
// 两个已有的宏
#define STRINGIFY(S) #S
#define PRAGMA_MESSAGE(MSG) _Pragma(STRINGIFY(message(MSG)))
// 延迟1次展开的宏
#define DEFER_STRINGIFY(S) STRINGIFY(S)
// 下面的宏在第一行用`\`折行
#define FORMATTED_MESSAGE(MSG) "[TODO-" DEFER_STRINGIFY(__COUNTER__) "] " MSG " \n"  \
    DEFER_STRINGIFY(__FILE__) " line " DEFER_STRINGIFY(__LINE__)
```



其中涉及到的知识：

* 两个常量字符串可以拼接成一个整串 “123””456” => “123456”
* 使用到3个预定义宏，__COUNTER__宏展开次数的计数器，全局唯一；__FILE__当前文件完整目录字符串；__LINE__在当前文件第几行
* 在字符串中预定义宏应延时展开，如果将上面的DEFER_STRINGIFY换成STRINGIFY的话，如__LINE__不能被正确展开成行数，而是成了一个常量字符串"__LINE__"
* 为了美化，warning message中可以使用\n换行

于是，使用FORMATTED_MESSAGE(MSG)宏就可以将带文件路径、序号、行数等信息加入到最终的warning中。

*********

其实到这步已经OK了，为了让这个宏更加抢眼，还可以借鉴RAC，把宏定义成前面加@的形式：

``` objc
#define KEYWORDIFY try {} @catch (...) {}

```

***********

## **最终版本**



``` objc

// 转成字符串
#define STRINGIFY(S) #S
// 需要解两次才解开的宏
#define DEFER_STRINGIFY(S) STRINGIFY(S)

#define PRAGMA_MESSAGE(MSG) _Pragma(STRINGIFY(message(MSG)))

// 为warning增加更多信息
#define FORMATTED_MESSAGE(MSG) "[TODO-" DEFER_STRINGIFY(__COUNTER__) "] " MSG " \n" DEFER_STRINGIFY(__FILE__) " line " DEFER_STRINGIFY(__LINE__)

// 使宏前面可以加@
#define KEYWORDIFY try {} @catch (...) {}

// 最终使用的宏
#define TODO(MSG) KEYWORDIFY PRAGMA_MESSAGE(FORMATTED_MESSAGE(MSG))

```



# References

[http://blog.sunnyxx.com/2015/03/01/todo-macro/](http://blog.sunnyxx.com/2015/03/01/todo-macro/)

[http://clang.llvm.org/docs/UsersManual.html](http://clang.llvm.org/docs/UsersManual.html)

[https://gcc.gnu.org/onlinedocs/cpp/Pragmas.html](https://gcc.gnu.org/onlinedocs/cpp/Pragmas.html)