title: Call Directory Extension 初探
date: 2016-06-17 22:33:15

tags:

- iOS 10
- CallKit

------

> iOS 10中引入了许多令人振奋的新特性，其中 CallKit让我特别感兴趣。这是一个非常重要的 API，继2014年苹果推出 VoIP证书后，这次 VoIP 接口的开放，以及一个全新的 App Extension，简直是VOIP的福音，可见苹果对VOIP的重视。并且，**”that enable call blocking and caller identification. You can create an app extension that can associate a phone number with a name or tell the system when a number should be blocked.”** 这意味着现在可以通过 Call Directory Extension 来实现电话黑名单功能了。Cool~ 本文简单阐述了如果实现简单的来电黑名单功能。



**阅读须知：目前学习的资料也仅限相关 API，另外 API也没有详细的注释，所以本文主要是个人探索所得，如果有什么错误，还望见谅并予以指正。现在，让我们开始吧~**

<!--more-->

## API介绍

**Extension** 一直给我的印象就是很轻量，单一的，就如之前接触的  [Photo Editing Extension](http://colin1994.github.io/2016/03/12/Photo-Editing-Extension/) 一样，使用起来十分简单。这次的 **Call Directory Extension** 也不出例外，出奇的简单。只涉及了两个类，四个方法。下面我们逐一介绍：

```swift
//
//  CXCallDirectoryProvider.h
//  CallKit
//
//  Copyright © 2016 Apple. All rights reserved.
//

@available(iOS 10.0, *)
public class CXCallDirectoryProvider : NSObject, NSExtensionRequestHandling {

    public func beginRequest(with context: CXCallDirectoryExtensionContext)
}
```

首先是第一个类 **CXCallDirectoryProvider**，它是来电的响应者，为我们提供了 **beginRequest** 方法，该方法在 Containing App 调用 reload 或者在 设置 —> 电话 —> Call Blocking & Identification里开启权限的时候，会自动被调用。所以我们之后将要重写它，来实现黑名单相关逻辑。怎么样，简单吧~ ![emoji_1](http://wanzao2.b0.upaiyun.com/system/pictures/2/original/21.png)

Now, Go on~

接下来是另外一个类 **CXCallDirectoryExtensionContext**，它提供了另外三个方法，如下所示：

```swift
//
//  CXCallDirectoryExtensionContext.h
//  CallKit
//
//  Copyright © 2016 Apple. All rights reserved.
//

@available(iOS 10.0, *)
public class CXCallDirectoryExtensionContext : NSExtensionContext {
    
    public func addBlockingEntry(withNextSequentialPhoneNumber phoneNumber: String)
    
    public func addIdentificationEntry(withNextSequentialPhoneNumber phoneNumber: String, label: String)
    
    public func completeRequest(completionHandler completion: ((Bool) -> Swift.Void)? = nil)
}
```

不难看出，**CXCallDirectoryExtensionContext** 主要负责提交我们处理好的请求。说白点，我们利用它来让系统知道，我们对某个来电所做出的判断。 **addBlockingEntry** 方法，接受一个电话号码字符串，形如 **“+8618...69”** (PS：不要问我为什么要加区号.. 这都是血与泪的经验)，来直接加入黑名单，也就是不接听该来电。**addIdentificationEntry** 方法，接受一个电话号码字符串以及对该号码的描述，也就是来电的时候需要显示的内容。 **completeRequest** 也就是提交之前的处理结果。至此，我们所要做的工作就完成了。![emoji_2](http://wanzao2.b0.upaiyun.com/system/pictures/16/original/15.png)



## 实战演示

虽然自认为上面的描述已经够详细了，不过这里还是有必要详细走一遍流程，以免遗漏。

开发环境：Xcode8.0 Beta + 64位 iOS10设备（至于为什么64位，之后再解释，说多了都是泪..）

### 1. 创建工程

没什么特别。 **Xcode —> File —> New —> Project**。随便选个 iOS Application，创建即可。这里我选择开发语言为 Swift，你随意~。

这里我们的目标是来电黑名单，也就是 Extension部分，所以创建好的 Containing App，不用做什么改动。

### 2.添加 Extension

**Xcode —> File —> New —> Target**。创建一个 **Call Directory Extension**，如下图所示：

![Extension_1](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/CallDirectory/callExtension_1.jpeg)



这里注意下底部的说明， （This extension and the app it is bundled with must be **64-bit only**）也就是，这个 extension只支持 64位的设备，坑爹有没有！！之前创建太急，没认真看，用那台 5C倒腾了半天，就是出问题。只好狠心把主力机也升级了。

创建好 Extension，会弹出这样的提示框：

![Extension_2](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/CallDirectory/callExtension_2.jpeg)

询问我们是否激活这个 scheme，当然选择激活咯，继续~

之后只要关注 **xxxHandler.swift** 即可，xxx是你之前创建的 extension命名。

这里的相关代码如下：

```swift
import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
    	// --- 1
        guard let phoneNumbersToBlock = retrievePhoneNumbersToBlock() else {
            NSLog("Unable to retrieve phone numbers to block")
            let error = NSError(domain: "CallDirectoryHandler", code: 1, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }
        
        // --- 2
        for phoneNumber in phoneNumbersToBlock {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
        
        // --- 3
        guard let (phoneNumbersToIdentify, phoneNumberIdentificationLabels) = retrievePhoneNumbersToIdentifyAndLabels() else {
            NSLog("Unable to retrieve phone numbers to identify and their labels")
            let error = NSError(domain: "CallDirectoryHandler", code: 2, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }
        
        // --- 4
        for (phoneNumber, label) in zip(phoneNumbersToIdentify, phoneNumberIdentificationLabels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
        
        // --- 5
        context.completeRequest()
    }
    
    private func retrievePhoneNumbersToBlock() -> [String]? {
        // retrieve list of phone numbers to block
        return ["+8618xxxx157"]
    }
    
    private func retrievePhoneNumbersToIdentifyAndLabels() -> (phoneNumbers: [String], labels: [String])? {
        // retrieve list of phone numbers to identify, and their labels
        return (["+8618xxxx569"], ["测试"])
    }
    
}
```

一个简单的来电黑名单，我们只要补全 `retrievePhoneNumbersToBlock` 和 `retrievePhoneNumbersToIdentifyAndLabels` 中的相关数据即可，它们分别表示直接加入黑名单的号码以及识别出来，需要判断的号码。

现在我们具体看一下这个类到底做了什么。

`beginRequest` ，该方法在 Containing App 调用 reload 或者在 设置 —> 电话 —> Call Blocking & Identification里开启权限的时候，会自动被调用。每次调用，都会提交当前的黑名单列表，具体操作如下：

在 **// --- 1** 中，先判断是否成功调用了 `retrievePhoneNumbersToBlock` 方法，如果没有，则打印 Log： **Unable to retrieve phone numbers to block**，然后直接终止这次请求并返回。

在 **// --- 2** 中，遍历添加黑名单中的号码，这里的号码将直接拦截。

在 **// --- 3** 中，先判断是否成功调用了 `retrievePhoneNumbersToIdentifyAndLabels` 方法，如果没有，则打印 Log： **Unable to retrieve phone numbers to identify and their labels**，然后直接终止这次请求并返回。

在 **// --- 4** 中，遍历添加识别后的号码及其描述，这里的号码将连带描述一起显示。

在 **// --- 5** 中，完成提交请求。 

到这里，代码已经全部完成了。

### 3. 开启权限

之后我们运行该 App到设备中，然后进入设备的设置 —> 电话 —> Call Blocking & Identification，开启我们的 App即可。如下图所示：

![Extension_3](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/CallDirectory/callExtension_3.png)



至此，相关的工作就都完成了，我们的来电黑名单也已经实现了，可以用添加到列表中的号码来测试啦，如下所示：

![Extension_4](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/CallDirectory/callExtension_4.png)



## 相关思考及后续

虽然实现黑名单功能很简单，但是这里我认为主要的问题应该是集中在，如何编辑这个黑名单列表。列表数据项可能很多，并且数据可能是实时更新添加的，那应该怎么做才更好呢？这里我的第一反应就是利用 App Group实现数据共享，在 Containing App完成相关的数据操作，在 Extension App中去获取即可。至于可行性，倒是没有验证过，如果不行，就当我瞎比比咯~。 当然，可能还有其他的办法，以及可能还会遇到其他的问题，这里在之后的学习过程中，我会逐步完善。

当然，对于 CallKit的学习，我也仅限于这一两天，还是没有资料的情况下。所以文中难免存在各种错误以及遗漏，欢迎指正。

这之后，继续 CallKit的学习，实现它的另外一个功能：VoIP App。 wait...



Enjoy it~

## 参考链接

[Enhancing VoIP Apps with CallKit](https://developer.apple.com/videos/play/wwdc2016/230/)

[CallKit](https://developer.apple.com/reference/callkit)

