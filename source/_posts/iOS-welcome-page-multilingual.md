layout: "iOS开发小记"

title: iOS启动页多语言

date: 2016-03-12 17:06:29

tags:

- iOS开发
- 教程

------

>  启动页适配多语言, 想必很多 App 都有类似的需求。但是之前尝试过程中, 发现  “多语言” 的那几种实现方式, 在欢迎页上都不适应, 直到遇到了 `UILaunchImages` ~ 下文将详细描述如何实现启动页多语言。

<!--more-->

## 传统多语言设置

说起多语言, 我们无非这样实现:

1. 为 App 添加多语言支持。![LaunchImages_0](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/LaunchImage/LaunchImagesLaunchImages_0.png)
   
2. 添加对应的配置, 资源。 比如：
   
   文本: ![LaunchImages_1](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/LaunchImage/LaunchImagesLaunchImages_1.png)
   
   图片:![LaunchImages_2](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/LaunchImage/LaunchImagesLaunchImages_2.png)
   
3. 使用对应资源, 比如:
   
   ``` objc
   label.text = NSLocalizedString(@"多语言", nil);
   ```



再麻烦一点, 就是xib, storyboard的多语言的。 但是原理一样, 这样的方式都能实现多语言支持。So, 就是这么简单~

![emoji](http://wanzao2.b0.upaiyun.com/system/pictures/181/original/%E5%BC%80%E5%BF%8309.png)

 然而, 启动页貌似不吃这套 ,,,



## 启动页设置

先说说我们如何设置启动页吧。

`Assets.xcassets` 这玩意引入之前, 我们是对启动页图片按规范命名, 比如 Default, -568h, @2x, @3x 之类的, 让系统帮助我们自动判断对应的启动页图片。

`Assets.xcassets` 之后, 我们都了一种选择, 可以直接拖拽图片到 `LaunchImage` 中, 并且图片命名也没那么多要求。

![LaunchImage_3](http://upload-images.jianshu.io/upload_images/262538-a84f9bece1aa8b37.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240/format/jpg)



再之后, 多了 `LaunchScreen.storyboard` , 意味着我们有了更多的选择, 可以做更多的事情, 把它当做一个xib, 拖拽相关控件上去就好~



方式很多, 是否意味着实现多语言的办法也很多 ?

然而并不是,, ![emoji](http://wanzao2.b0.upaiyun.com/system/pictures/283/original/%E7%94%9F%E6%B0%9411.png)



不论是对` 图片` 进行多语言, 还是 `LaunchScreen.storyboard` 多语言, 发现启动页始终没有跟着系统语言变, 血崩..



当然, 办法并不是没有, 只是没找到对的而已~ 下面介绍如何通过`UILaunchImages` 实现启动页多语言。

> PS: 感觉 LaunchScreen.storyboard 是能做到多语言支持的, 难道是我实现过程中有问题 ? 



## UILaunchImages

先看一下官方文档:



> UILaunchImages (Array - iOS) Explicitly specifies the launch images to use for the app. This key contains an array of dictionaries. Each dictionary contains detailed information about a single launch image and how it is used. Xcode fills in the value of each dictionary based on information you provide in your project settings.

显然, 我们可以通过设置 `UILaunchImages` 来配置启动图片。

至于 `UILaunchImages` 的几个 Key , 简单描述如下: 

- `UILaunchImageName` (required) 启动页资源名称
  
- `UILaunchImageMinimumOSVersion`(required) 启动页支持的最低版本
  
- `UILaunchImageSize` 启动页尺寸
  
- `UILaunchImageOrientation` 启动页方向
  
  ​

代表什么, 都比较简单, 具体可以参考官方文档~ [  [UILaunchImages](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW28) ]

用这种方式配置启动页也十分简单, 具体步骤:

1. 取消启动页使用的 Asset Catalog
   
   ![](http://7xkc7a.com1.z0.glb.clouddn.com/LaunchImages%E5%B1%8F%E5%B9%95%E5%BF%AB%E7%85%A7%202016-03-12%20%E4%B8%8B%E5%8D%884.44.06.png)
   
2. 在Info.plist 中添加UILaunchImages项
   
   ``` xml
   <key>UILaunchImages</key>
           <array>
               <dict>
                   <key>UILaunchImageName</key>
                   <string>LaunchImage</string>
                   <key>UILaunchImageMinimumOSVersion</key>
                   <string>7.0</string>
                   <key>UILaunchImageSize</key>
                   <string>{320, 480}</string>
                   <key>UILaunchImageOrientation</key>
                   <string>Portrait</string>
               </dict>
               <dict>
                   <key>UILaunchImageName</key>
                   <string>LaunchImage-568h</string>
                   <key>UILaunchImageMinimumOSVersion</key>
                   <string>7.0</string>
                   <key>UILaunchImageSize</key>
                   <string>{320, 568}</string>
                   <key>UILaunchImageOrientation</key>
                   <string>Portrait</string>
               </dict>
               <dict>
                   <key>UILaunchImageName</key>
                   <string>LaunchImage-667h</string>
                   <key>UILaunchImageMinimumOSVersion</key>
                   <string>8.0</string>
                   <key>UILaunchImageSize</key>
                   <string>{375, 667}</string>
                   <key>UILaunchImageOrientation</key>
                   <string>Portrait</string>
               </dict>
               <dict>
                   <key>UILaunchImageName</key>
                   <string>LaunchImage-736h</string>
                   <key>UILaunchImageMinimumOSVersion</key>
                   <string>8.0</string>
                   <key>UILaunchImageSize</key>
                   <string>{414, 736}</string>
                   <key>UILaunchImageOrientation</key>
                   <string>Portrait</string>
               </dict>
           </array>
   ```
   
   ![](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/LaunchImage/LaunchImagesLaunchImages_4.png)
   
3. 添加对应的启动页资源
   
   ![](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/LaunchImage/LaunchImagesLaunchImages_3.png)
   
   ​



如此, 即可完成 启动页 多语言的适配, 不信你就试试呗~ 

![](http://wanzao2.b0.upaiyun.com/system/pictures/270/original/%E5%BE%97%E7%91%9F10.png)



> PS: 这里, 说明一点。 启动页只会保留一份, 也就是说, 你第一次加载完以后, 切换了语言, 再重新打开App, 它的启动页不会跟着更新的。 这也符合苹果的用户交互指引。
> 
> 如果你想要动态修改启动页面图LaunchImage, 抱歉！**根据苹果的用户交互指引,该页面是在程序加载时显示的,不建议动态修改.**
> 
> 正确的做法一般都是用固定的图片做启动页面图,在启动页面结束之后做任何你想做的事.
> 
> 如果真想动态修改启动页面,启动页面是固定的名字,可以在程序执行之后强制把页面替换掉,不过这样APP可能会被拒.
> 
> 该怎么设置一个动态的启动图呢？在启动图结束的时候，用一个View来展示你的动图，记得placeHolder设置为和你的LaunchImage的图片一样就行，这样就可以做出类似的效果了