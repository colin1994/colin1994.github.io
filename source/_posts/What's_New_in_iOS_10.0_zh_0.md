layout: "代码备忘"

title: What's New in iOS 10.0 中文版(上)

date: 2016-06-14 17:20:52

tags:

- iOS 10
- 翻译

------

> 由于原文篇幅较长，为了方便阅读，分为上下篇。
>
> 本文是 What's New in iOS 10.0 中文版的上篇，主要描述了iOS 10新引入的一些新特效，概括了重要的变化。
>
> 在What's New in iOS 10.0 中文版(下)中，将介绍一些已存在框架的改进以及一些弃用的 API。
>
> 原文链接：[What's New in iOS 10.0](https://developer.apple.com/library/prerelease/content/releasenotes/General/WhatsNewIniOS/Articles/iOS10.html#//apple_ref/doc/uid/TP40017084-SW1)

这篇文章总结了运行在目前 iOS设备上的 iOS 10中与开发者有关的功能，这篇文章还列出了与这些功能相关的详细文档。

<!--more-->

关于目前已知问题的最新新闻和信息，可以查阅 [https://developer.apple.com/ios/download/](https://developer.apple.com/ios/download/) 。添加到 iOS 10中的 API 的完整列表，详见 *[iOS 10.0 API Diffs](https://developer.apple.com/library/prerelease/content/releasenotes/General/iOS10APIDiffs/index.html)*。有关新设备的更多信息，详见 *[iOS Device Compatibility Reference](https://developer.apple.com/library/prerelease/content/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Introduction/Introduction.html#//apple_ref/doc/uid/TP40013599)*.

更多关于 Swift,详见 [Swift Language](https://developer.apple.com/library/prerelease/content/documentation/DeveloperTools/Conceptual/WhatsNewXcode/introduction.html#//apple_ref/doc/uid/TP40004635-SW3) and *[The Swift Programming Language (Swift 3)](https://developer.apple.com/library/prerelease/content/documentation/Swift/Conceptual/Swift_Programming_Language/index.html#//apple_ref/doc/uid/TP40014097)*.

## SiriKit

Apps 在特定的领域提供服务，可以使用 SiriKit来在 iOS中通过 Siri使用这些服务。 想要提供这些服务，需要创建一个或多个使用这些意图和意图 UI frameworks的   App extensions(app extensions using the Intents and Intents UI frameworks)。SiriKit提供如下领域的服务：

- 音频或视频通话
- 消息传递
- 发送或接收付款
- 搜索照片
- 乘坐预定
- 管理训练

当用户发起一个包含了你所提供服务的请求时， SiriKit会向你的 extension发送一个意图对象( intent object )，它描述了用户了请求并且提供了与这个请求相关的所有数据。你使用这个意图对象来提供一个相关的响应对象(response object)，它包含了如何处理用户请求的详情。Siri通常处理所有的用户交互，但是你也可以使用一个 extension来提供自定义 UI，它包含来自你的 App中的品牌或者其他额外信息。

SiriKit还提供了一个机制，你可以使用它来告诉系统发生在你的 App中的交互和活动。 当你告诉系统这些交互，系统会判断你的 App是否可以处理用户当前的请求，如果可以，就把这个请求传递给你的 App。 除了意图，SiriKit还定义了一个交互对象(interaction object)，它把意图(intent)和意图处理过程(intent-handling process)的信息相结合，包含开始时间和特定事件发生的持续时间等细节。如果你的 App注册为可以处理一个活动，这个活动具有一个相同的名称并且作为一个意图，系统可以启动你的 App，并且携带一个包含了意图的交互对象，即使你没有提供一个意图 App extension。

Maps和 Siri 都提供乘坐预定，用户也可以使用 Maps来订餐。你的意图 extension处理源于 Maps的交互，同样地它处理来自 Siri的请求。如果你自定义用户界面，你的意图 UI extension还可以自行配置，取决于你的请求是来自 Siri 还是 Maps。

为了学习如何支持 SiriKit来给用户提供使用服务的新途径，阅读 *[SiriKit Programming Guide](https://developer.apple.com/library/prerelease/content/documentation/Intents/Conceptual/SiriIntegrationGuide/index.html#//apple_ref/doc/uid/TP40016875)*. 当你准备实现处理各种意图的 App extensions，参考 *[Intents Framework Reference](https://developer.apple.com/reference/intents)* 和 *[Intents UI Framework Reference](https://developer.apple.com/reference/intentsui)*.

## 积极的建议

iOS 10引入了新的方式来来增强与你的 App的交互度(engagement)，通过帮助系统在适当的时机把你的 App推荐给用户。 如果你通过 App搜索你的 iOS 9 App，通过 Spotlight，Safari搜索结果，Handoff以及 Siri建议，允许用户访问你的 App深处的活动(activities)以及内容。 在 iOS 10之后，你可以提供用户在你的 App中做什么的信息，这有助于系统在额外的地方推广你的 App，比如键盘和 QuickType，Maps和 CarPlay，应用切换器(app switcher)，Siri交互和(媒体播放 Apps) 的锁屏界面。这些机会提高与系统的整合，它由一系列的技术支持，比如  `NSUserActivity`，由 [Schema.org](http://schema.org/)定义的 Web标记(web markup)，以及定义在 Core Spotlight，MapKit，UIKit，以及 Media Player框架中的 API。.

在 iOS 10中，`NSUserActivity` 对象包含  `mapItem` 属性，该属性允许你提供可以在上下文(other contexts)使用的位置信息。比如，你的 App展示酒店信息，你可以使用 `mapItem` 属性来保存用户正在浏览的酒店的位置信息，当用户切换到另外一个旅行规划 App，酒店的位置是自动可用的。如果你支持 App搜索，你可以使用 `CSSearchableItemAttributeSet` 中新的基于文本的地址(text-based address)的属性，比如 `thoroughfare` 和 `postalCode`，来指定用户可能想要去的具体位置。注意，当你使用  `mapItem` 属性，系统自动填充  `contentAttributeSet`  属性。

为了与系统共享一个位置，一定要指定 `latitude` 和 `longitude` 值，除了 `CSSearchableItemAttributeSet` 中的地址属性。也建议你提供值给 `namedLocation`，这样用户可以查看位置的名称，以及  `phoneNumbers` 属性，以便用户可以使用 Siri来发起呼叫给指定位置。

在 iOS 9中，将标记添加到你的网站上的结构数据来丰富内容，用户可以在 Spotlight和 Safari搜索结果中看到。在 iOS 10中，你可以使用  [Schema.org](http://schema.org/) 定义的位置相关词汇，比如 [PostalAddress](http://schema.org/PostalAddress)，进一步提高用户体验。例如，如果用户查看你网站上描述的一个位置，系统可以在用户切换到 Maps中的时候建议相同的位置。注意 Safari 同时支持 JSON-LD 和 Microdata 编码的 [Schema.org](http://schema.org/) 词汇。

UIKit介绍了 `UITextInputTraits` 协议中的  `textContentType` 属性，它可以让你指定你希望用户输入文本区域的内容的语义。当你提供这些信息时，系统可以在某些情况下自动选择一个合适的键盘并且提高键盘修正和主动集成来自其他 App或者网站的信息。比如，如果你使用 `UITextContentTypeFullStreetAddress` 来告诉系统你希望用户在文本区域中输入一个完整的地址，系统可以显示用户最近查看的位置地址。

如果你的 App播放多媒体并且使用  `MPPlayableContentManager` APIs， iOS 10 帮你在锁屏界面通过你的 App，使得用户可以查看专辑封面和播放多媒体。

如果你的骑乘共享(ride-sharing) App使用  `MKDirectionsRequest` API，iOS 10 可以在用户想要骑行的时候，在应用程序切换器(app switcher)中展示它。想要注册成一个骑行共享提供者，在 `Info.plist` 文件中设置 [MKDirectionsApplicationSupportedModes](https://developer.apple.com/library/prerelease/content/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW33) 的值为 `MKDirectionsModeRideShare` 。如果你的 App 只提供骑行共享，系统建议你的 App使用这样开头的文本  “Get a ride to…”；如果你的 App支持骑行共享和其他路由类型（如汽车或摩托车），系统建议你使用这样开头的文本  “Get directions to…”。注意 你收到的 `MKMapItem` 对象可能不包含经度和纬度信息，需要地理编码。

## 与 Messages App 交互

在 iOS 10中，你可以创建 App extensions 来与 Messages App交互，使得用户可以发送文本，贴纸，媒体文件以及交互式消息。你也可以支持更新为每个收件人响应消息的交互式消息。你还可以创建两种类型的 App extensions:

- 贴纸包提供一系列的贴纸，用户可以添加到他们的信息内容中。

- *iMessage app* 让你在 Messages App 中展示一个自定义用户界面，创建一个标签的浏览器，包括一次对话中的文本，贴纸和媒体文件，并且创建，发送和更新消息交互。

   iMessage App也可以帮助用户搜索保存在你的 App中相关网站的图片，当它们处在  Messages App 中的时候。

你可以创建一个贴纸包而无需编写任何代码：简单地拖拽图片到 Xcode中贴纸包文件夹内贴纸 asset 目录。

为了开发一个  iMessage App，你可以使用 Messages 框架中的 API (`Messages.framework`)。更多关于 Messages 框架，详见 *[Messages Framework Reference](https://developer.apple.com/reference/messages)*. 对于创建 App Extensions的普遍信息，详见 *[App Extension Programming Guide](https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214)*.

如果你的 App提供图片在 Messages中分享，你想要用户可以使用 Spotlight 的流行图片搜索  (即, “#images”) 来搜索图片，而不用离开 Messages App，首先创建一个 iMessage app。然后遵循下面步骤： 

- 给你 App 的 entitlements 添加  `com.apple.developer.associated-domains` 键。包括保存你想要搜索的图片的网站域名的一个列表。对于每个域，指定 `spotlight-image-search` 服务。
- 添加一个 `apple-app-site-association` 文件到你的网站。为 `spotlight-image-search` 服务添加一个字典，包含你的 app ID, 它是 team ID 或者 app ID 前缀，后跟  bundle ID。你可以指定多打500个路径和模式，应该包含 Spotlight 流行图片搜索索引。 (关于网站路径的一些实例，详见 [Creating and Uploading the Association File](https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html#//apple_ref/doc/uid/TP40016308-CH12-SW4)).
- 允许 Applebot 爬虫 (详见 [About Applebot](https://support.apple.com/en-us/HT204683)).

## 用户通知

iOS 10 引入了用户通知框架(`UserNotifications.framework`)，它支持本地和远程通知的发送和处理。你可以使用这个框架的类来安排基于特定条件的本地通知。比如时间或者位置。当它们被发送到用户设备的时候，App 和App extensions 可以使用这个框架来接收和修改本地和远程的通知。

还介绍了在 iOS 10 中，用户通知 UI框架 (`UserNotificationsUI.framework`) 允许你自定义显示在用户设备上的本地和远程推送通知。你使用这个框架来定义一个接收通知数据并且提供相应可视化表示的 App extension 。这个 extension也可以响应相关的自定义动作和通知。 

## 语音识别

iOS 10 引入了一个新的 API，支持连续语音识别和帮助你构建支持语音识别并且转换成文本的 App。使用  Speech 框架 (`Speech.framework`) 中的 API，你可以执行实时语音转录和记录音频。例如，你可以得到一个语音识别器，开始简单的语音识别，代码如下所示： 

```swift
let recognizer = SFSpeechRecognizer()
let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
     print (result?.bestTranscription.formattedString)
})
```

与访问其他类型的受保护数据一样，如日历，照片资料，进行语音识别需要用户的授权 (更多关于访问受保护的数据类，详见[Security and Privacy Enhancements](https://developer.apple.com/library/prerelease/content/releasenotes/General/WhatsNewIniOS/Articles/iOS10.html#//apple_ref/doc/uid/TP40017084-SW3))。在语音识别的情况下，许可是必需的，因为数据被传递，并且暂时存储在苹果的服务器上，以提高语音识别的准确性。请求用户的权限，必须在 `Info.plist` 文件中添加`NSSpeechRecognitionUsageDescription`  键。

当你在你的 App中采用语音识别，一定要向用户表明他们的语音将被识别，并且他们不应该使用敏感话语。

## 广泛的颜色

贯穿系统的大多数图形框架，包括 Core Graphics, Core Image, Metal, 和 AVFoundation, 有大幅的改进来支持 extended-range 像素格式和 wide-gamut 颜色空间。通过将此行为扩展到整个图形栈中，它比以往任何时间更容易支持具有宽颜色显示的设备。此外，UIKit 使在新扩展的 sRGB颜色空间上工作标准化，因此很容易混合 sRGB和其他颜色，更广泛的色域没有明显的性能损失。

这里有一些你开始使用广泛颜色的最佳实践。

- 在 iOS 10 中，[UIColor](https://developer.apple.com/reference/uikit/uicolor) 类使用扩展的 sRGB 颜色空间，并且它的构造器(initializers)不再限制初始值在  `0.0` 和 `1.0` 之间。如果你的应用程序依赖于 UIKit来限制组件(component)值 (无论你是创建一个颜色或者一个颜色的组件值)，当你链接到 iOS 10的时候，你需要改变这些行为。 
- 当在 iPad Pro (9.7 inch) 的  [UIView](https://developer.apple.com/reference/uikit/uiview) 上执行自定义的绘制时，底层的绘图环境配置了一个扩展的 sRGB颜色空间。
- 如果你的 App 渲染自定义的图像对象，使用新的  [UIGraphicsImageRenderer](https://developer.apple.com/reference/uikit/uigraphicsimagerenderer) 类来控制目标位图是使用扩展范围(extended-range)还是标准范围 (standard-range) 格式。
- 如果你使用较低级别的 API，比如 Core Graphics 和 Metal来执行你自己的图像处理，你需要使用一个扩展的颜色空间和一个支持16位浮点值的像素格式的组件值。当限制颜色值是必要的时候，你应该明确这样做。
- Core Graphics, Core Image,以及 Metal 性能着色器提供了新的选择，可以在颜色空间之间轻松转换颜色和图像。

## 适应真实的色调显示

真实的色调显示使用环境光传感器自动调整显示器的颜色和强度，以配合当前环境的照明条件。为了确保你的 App可以与真实的色调提供的标准颜色变化很好的工作，在 `Info.plist` 中添加新的 [UIWhitePointAdaptivityStyle](https://developer.apple.com/library/prerelease/content/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW31) 键来描述你的 App的主要视觉内容。比如： 

- 如果你的 App是一个照片编辑应用，颜色的准确性(fidelity)比自动调整环境白点(white point)更重要。在这种情况下，你可以使用 `UIWhitePointAdaptivityStylePhoto` 方式来降低系统提供的真实色调变化的强度。
- 如果你的 App是一个阅读应用，符合环境白点将为用户提供帮助。在这种情况下，你可以使用 `UIWhitePointAdaptivityStyleReading` 方式来加强系统提供的真实色调变化的强度。

## App搜索 的改进

iOS 10 和 Core Spotlight框架介绍了几个 App搜索的改进点： 

- 应用内(In-app)搜索
- 继续搜索(Search continuation)
- 众包(crowdsourcing:是互联网带来的新的生产组织形式)与差分隐私(differential privacy)的深度链接
- 可视化的验证结果

新的 `CSSearchQuery` 类支持应用内内容搜索，使用现有的 Core Spotlight APIs。使用这个 API可以消除需要保持你自己单独的搜索索引，让你发挥 Spotlight的强大搜索技术和匹配规则，允许用户搜索内容不离开你的 App，就像他们在 Mail, Messages,和 Notes.

在 iOS 9中，使用搜索 API(比如 Core Spotlight, [NSUserActivity](https://developer.apple.com/reference/foundation/nsuseractivity) 和 web标记) 在你的 App中，让用户使用Spotlight 和 Safari搜索界面来搜索索引的内容。在 iOS 10中，你可以使用新的 Core Spotlight 符号，当用户打开你的 App时候，用户可以继续使用 Spotlight进行搜索。要启用这个功能，在 `Info.plist` 文件中添加 `CoreSpotlightContinuation` 键，并且设置它的值为  `YES`，然后更新你的代码来处理一个  [CSQueryContinuationActionType](https://developer.apple.com/reference/corespotlight/csquerycontinuationactiontype) 类型的活动延续。在  [application:continueUserActivity:restorationHandler:](https://developer.apple.com/reference/uikit/uiapplicationdelegate/1623072-application) 方法中收到的 [NSUserActivity](https://developer.apple.com/reference/foundation/nsuseractivity) 对象中的用户信息字典包含了 [CSSearchQueryString](https://developer.apple.com/reference/corespotlight/cssearchquerystring) 键，它的值是一个字符串，表示用户的查询。

iOS 10 引入了一个不同的私人方式来帮助提高你的 App的内容在搜索结果中的排名。 iOS 提交一部分差分隐私到 Apple的服务器随着用户使用你的 App 以及  [NSUserActivity](https://developer.apple.com/reference/foundation/nsuseractivity) 对象包含深度链接地址并且它们的 [eligibleForPublicIndexing](https://developer.apple.com/reference/foundation/nsuseractivity/1414701-eligibleforpublicindexing) 属性设置为  `YES` 被提交到 iOS中。差分隐形散列允许 Apple统计流行的深度链接的频率，而不曾与用户关联的链接进行访问。

当你使用 App 搜索 API 验证工具来测试你的网站标记和深度链接，现在展示你的结果的可视化表示，包括支持的标记，比如  [Schema.org](http://schema.org/) 中定义的。验证工具可以帮你看到 Applebot web爬虫索引信息，比如标题，描述，URL和其他支持的元素。你可以在这里获取这个验证工具： [https://search.developer.apple.com/appsearch-validation-tool](https://search.developer.apple.com/appsearch-validation-tool). 更多关于支持深度链接和添加标记，详见： [Mark Up Web Content](https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/AppSearch/WebContent.html#//apple_ref/doc/uid/TP40016308-CH8).

学习如何让你的网站中的图片在 Messages App内可搜索，详见 [Integrating with the Messages App](https://developer.apple.com/library/prerelease/content/releasenotes/General/WhatsNewIniOS/Articles/iOS10.html#//apple_ref/doc/uid/TP40017084-SW4).

## Widget 的改进

iOS 10 为锁屏界面引入了一个新的设计，现在可以显示 widgets。为了保证你的 widget 在任何背景下看起来都不错，你可以适当地设置 [widgetPrimaryVibrancyEffect](https://developer.apple.com/reference/uikit/uivibrancyeffect/1771278-widgetprimaryvibrancyeffect) 或者 [widgetSecondaryVibrancyEffect](https://developer.apple.com/reference/uikit/uivibrancyeffect/1771277-widgetsecondaryvibrancyeffect)(使用这些属性取代已废弃的 [notificationCenterVibrancyEffect](https://developer.apple.com/reference/uikit/uivibrancyeffect/1613917-notificationcentervibrancyeffect) 属性)。此外， widgets现在包括显示模式(由 [NCWidgetDisplayMode](https://developer.apple.com/reference/notificationcenter/ncwidgetdisplaymode) 表示)的概念，它可以让你描述有多少内容是可用的，并允许用户选择一个紧凑或者扩展型的视图。 

## Apple Pay 的改进

在 iOS 10中，用户可以通过 Siri和 Maps使用网页版的 Apple Pay 来便捷安全的完成支付。对于开发者来说， iOS 10 引入了新的 API，你可以在代码中使用运行在 iOS和  watchOS上，支持动态支付网络的能力和一个新的沙盒测试环境。

iOS 10 引入了新的 API，帮助你将 Apple Pay 直接引入你的网站。当你在你的网站支持 Apple Pay，用户在 iOS或者 OS X上通过 Safari浏览的时候，可以通过它们的 iPhone或 Apple Watch来使用 Apple Pay上的信用卡进行支付。 详见 [*ApplePay JS Framework Reference*](https://developer.apple.com/reference/applepayjs).

 PassKit框架 (`PassKit.framework`) 介绍了让你在 UIKit不可用的地方支持 Apple Pay的 API。具体来说， [PKPaymentAuthorizationController](https://developer.apple.com/reference/passkit/pkpaymentauthorizationcontroller) 和 [PKPaymentAuthorizationControllerDelegate](https://developer.apple.com/reference/passkit/pkpaymentauthorizationcontrollerdelegate) 使得  [PKPaymentAuthorizationViewController](https://developer.apple.com/reference/passkit/pkpaymentauthorizationviewcontroller) 提供的功能以及它的 delegate 可用，而不需要 UIKit。尽管新的 API 需要在特定的意图下在 watchOS上提供 Apple Pay，还是建议你在代码的任何地方采用它。这样你就可以用一套基础代码来广泛提供 Apple Pay支持。(更多关于意图和 Siri集成，详见 [SiriKit](https://developer.apple.com/library/prerelease/content/releasenotes/General/WhatsNewIniOS/Articles/iOS10.html#//apple_ref/doc/uid/TP40017084-SW5).)

 PassKit 框架还增加了新的功能，让信用卡发行机构在它们的 App中展示他们的信用卡。具体来说， `PKPaymentButtonTypeInStore` 按钮类型允许你为信用卡展示一个 Apple Pay 按钮，  `presentPaymentPass:` 方法允许你以编程方式展示信用卡。 ( `presentPaymentPass:` 方法定义在  [PKPassLibrary](https://developer.apple.com/reference/passkit/pkpasslibrary)中)。

当一个新的支付网络可用时，你的 App可用自动支持新的网络，而不需要修改和重新编译你的 App。[availableNetworks](https://developer.apple.com/reference/passkit/pkpaymentrequest/1833288-availablenetworks) 方法允许你在运行时发现用户设备可用的网络。此外， [supportedNetworks](https://developer.apple.com/reference/passkit/pkpaymentrequest/1619329-supportednetworks) 属性被扩展了，以便可以携带一些支付服务提供商的名字作为参数。然后你的 App自动支持任何支付提供商支持的网络。详见[https://developer.apple.com/apple-pay/](https://developer.apple.com/apple-pay/).

iOS 10 引入了一个新的测试环境，它允许你直接在设备上提供测试信用卡。测试环境返回加密后的测试支付数据。要使用这种环境，遵循以下步骤：

1. 在 iTunes Connect上创建一个测试 iCloud账号
2. 在你的设备上登录该账号
3. 设置测试所需的区域
4. 使用 [https://developer.apple.com/apple-pay/](https://developer.apple.com/apple-pay/) 上列举的测试信用卡

**注意:** 当你切换 iCloud账号，环境自动切换。你还必须在实际生产环境中测试支付。

## 安全和隐私的改进

iOS 10 引入了一些修改和补充，帮助你提高你的代码的安全和维护用户数据的隐私。更多关于这方面的内容，详见 [Security](https://developer.apple.com/security/ ) .

- `Info.plist` 文件中新的 `NSAllowsArbitraryLoadsInWebContent` 键，提供了一个便捷的方式来允许任意的 web页面加载任务，同时保留 ATS保护你的 App的其余部分。
- SecKey API包括不对称密钥生成的改进。使用 SecKey API 替代已经弃用的 CDSA(Common Data Security Architecture: 通用数据安全架构) API。
- RC4 对称加密套件现在默认禁用所有的 SSL/TLS 连接，以及 SSLv3 不再支持安全传输 API。建议你尽快停止使用  SHA-1和 3DES 加密算法。
- [UIPasteboard](https://developer.apple.com/reference/uikit/uipasteboard) 类支持剪贴板功能，该功能允许用户设置之间复制和粘贴，包括 API可以用来限制一个纸板到特定设备和设置到达过期时间戳后，纸板被清除。此外，命名过的纸板不再重复出现，取而代之的是，你应该使用共享的容器，以及“发现”纸板（也就是说，纸板被  [UIPasteboardNameFind](https://developer.apple.com/reference/uikit/uipasteboardnamefind)  常数定义）是无效的。
- 你必须静态声明你的应用程序使用受保护的数据类，通过在 `Info.plist` 文件中包含相关的目的字符串键。例如，你必须包含 [NSCalendarsUsageDescription](https://developer.apple.com/library/prerelease/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW15) 键来访问用户日历的数据。如果你不包含相关的目的字符串键，当你试图访问相关数据的时候，你的 App会退出。

## CallKit

 CallKit 框架 (`CallKit.framework`) 让  VoIP App与 iPhone UI相结合，给用户一个很棒的体验。使用这个框架来让用户在锁屏界面查看和接听到来的 VoIP电话，以及管理手机上 Favorites和 Recents视图上的联系人。

CallKit 还介绍了 App extensions，允许来电拦截并且来电识别。你可以创建一个 App extension，将一个电话号码和一个名称联系起来，或者告诉系统某个号码需要被拦截。

## News Publisher 的改进

News Publisher 可以使用 Apple News格式，很容易地提供设计精美的新闻，杂志和网络内容给 Apple News。任何人都可以注册，从主要的杂志或者新闻机构，到独立的出版商和博客。开始或学习更多关于最近的更新，访问  [https://newsresources.apple.com](https://newsresources.apple.com/).

## Video Subscriber Account

iOS 10 引入  Video Subscriber Account 框架 (`VideoSubscriberAccount.framework`) 来帮助 App支持支持身份验证流或验证视频点播(也称为 TV)与他们的有线或卫星 TV提供商进行身份验证。使用这个框架的 API可以帮助你支持一个单一的登录体验，用户登录一次解锁访问所有的视频应用程序订阅支持。

## App Extensions

iOS 10 引入了几个可以创建 App extension的新的 extension points，比如：

- Call Directory
- Intents
- Intents UI
- Messages
- Notification Content
- Notification Service
- Sticker Pack

此外，iOS 10包含了如下的第三方键盘 app extensions的改进：

- 你可以使用 `UITextDocumentProxy`  类中的  `documentInputMode` 属性，来自动检测文档的输入语言，并且改变你的键盘 extension来符合这个语言(如果支持的话)。当你用这种方式决定输入的语言时， 你可以做每一种语言的键盘切换，比如为 Messages内建的。
- 新的 `handleInputModeListFromView:withEvent:` 方法让键盘 extension 显示系统的键盘选择菜单(即地球标志的菜单).

键盘 extension 必须放置地球标志和系统标志相同的位置。此外，如果你需要提供一个自定义的按键来启动键盘设置，例如，你应该把这个按键放在系统键盘听写键的相同位置。

更多关于 App extensions，详见 [*App Extension Programming Guide*](https://developer.apple.com/library/prerelease/content/documentation/General/Conceptual/ExtensibilityPG/index.html#//apple_ref/doc/uid/TP40014214).

