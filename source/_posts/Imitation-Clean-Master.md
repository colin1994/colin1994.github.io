layout: "iOS开发小记"

title: 仿猎豹垃圾清理

date: 2015-07-13 10:14:52

tags:

- iOS开发
- 教程

---

> 前几天无意打开猎豹内存大师, 发现它的垃圾清理很强大, 效果也不错, 闲着就研究了下。 不过.. 结果貌似和我想象的不太一样。怎么说呢, 听我下文一一分析。

效果图:

<img src="http://7xkc7a.com1.z0.glb.clouddn.com/imageliebao_0.PNG">

<!--more-->

<img src="http://7xkc7a.com1.z0.glb.clouddn.com/imageliebao_1.PNG">



从效果图, 我们可以看出它有以下几个功能:

1. 获取设备上已安装的所有App
2. 获取App的信息, 包括图标和名称
3. 获取当前已用存储和可用存储
4. 扫描App动画效果
5. 清除所有App垃圾文件

看到这里, 你是不是也觉得很强大?

然后然后, 感叹的同时, 我有几点疑惑。

1. 获取到所有已安装的App, 这个功能能通过审核?(我是去年在App Store上下载的这个App)
2. App的图标如何获取到的? (因为扫描到的App包括我自己没上架的demo, icon只能是本地获取, 从其他App沙盒拿？)
3. 垃圾清理过程, 为什么会出现“存储容量已满”这个提示？ 明明是清理垃圾, 中途还会出现存储满的情况?

困惑, 不解..~ 于是乎, 折腾呗。 花了两天时间。写了个小demo。

效果如下:

<img src="http://img.my.csdn.net/uploads/201505/28/1432801698_3530.gif" width=400>



接下去, 我会介绍以下各个功能的实现过程, 包括:

1. 获取设备已安装App列表已经App信息
2. 扫描动画的实现
3. 获取已用存储和可用存储
4. 垃圾清理

不过, 分析之前, 说明以下, 该功能不能够上传到App Store上! 也就是说, 它通不过审核的。原因有二:

1. 使用了私有API
2. 苹果不允许App有处理内存相关功能

至于猎豹内存大师这个App、它也早已经被下架了。我怀疑它利用混淆代码通过的审核。至于功能的实现, 我觉得和猎豹的实现思路应该是一样的。

至此, 如果你还对这篇文章感兴趣, 欢迎继续往下阅读。

本文参考源码: [CSDN下载_防猎豹垃圾清理](http://download.csdn.net/detail/hitwhylz/8748739)



**********

## 获取设备已安装App列表已经App信息



### 不越狱, 非私有API

没有越狱的设备，官方没有提供api，所以只能用一些技巧，但是获取内容不全。

这里主要有两种办法:

> 方法一：利用URL scheme，看对于某一应用特有的url scheme，有没有响应。如果有响应，就说明安装了这个特定的app。

说实在.. 这个办法比较傻。 App Store几百万的App, 如何枚举的过来? 并且, 也无法扫描到自己的demo。 不过, 还真有人这么干..

这是对应的demo, 感兴趣可以看看。 [iHasApp](https://github.com/danielamitay/iHasApp)

[官方教程: iPhoneURLScheme_Reference](http://developer.apple.com/library/ios/#featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html)



> 方法二：利用一些方法获得当前正在运行的进程信息，从进程信息中获得安装的app信息。

[参考: UIDevice_Category_For_Processes](http://forrst.com/posts/UIDevice_Category_For_Processes-h1H)

总的来说, 不越狱, 非私有API, 想获得完整列表, 基本没什么可能。



### 不越狱, 私有API。

这里就是我demo所采用的办法, 比较简单。

``` objc
#include <objc/runtime.h>

Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");  
NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];  
NSLog(@"apps: %@", [workspace performSelector:@selector(allApplications)]);  
```

**返回结果**

``` objc

	"LSApplicationProxy: com.qunar.iphoneclient8",
    "LSApplicationProxy: com.apple.mobilemail",
    "LSApplicationProxy: com.apple.mobilenotes",
    "LSApplicationProxy: com.apple.compass",
    "LSApplicationProxy: com.tencent.happymj",
    "LSApplicationProxy: com.apple.mobilesafari",
    "LSApplicationProxy: com.apple.reminders"
```

返回的是个数据, 每个元素都是`LSApplicationProxy `.它的description只返回了 它的bundle id。然而这并不是我们想要的。



接下去我们看

[LSApplicationProxy.h](https://searchcode.com/codesearch/view/15673930/)

形如:

``` objc
@class LSApplicationProxy, NSArray, NSDictionary, NSProgress, NSString, NSURL, NSUUID;

@interface LSApplicationProxy : LSResourceProxy <NSSecureCoding> {
    NSArray *_UIBackgroundModes;
    NSString *_applicationType;
    NSArray *_audioComponents;
    unsigned int _bundleFlags;
    NSURL *_bundleURL;
    NSString *_bundleVersion;
    NSArray *_directionsModes;
    NSDictionary *_entitlements;
    NSDictionary *_envi

	...
	...
```

这里列举了`LSApplicationProxy `对应的属性和方法。

我们可以用如下代码, 打印下每个属性的值, 找出我们想要的。

``` objc
2、/* 获取对象的所有属性 以及属性值 */
- (NSDictionary *)properties_aps
{
   NSMutableDictionary *props = [NSMutableDictionary dictionary];   
   unsigned int outCount, i;   
   objc_property_t *properties = class_copyPropertyList([self class], &outCount);   
   for (i = 0; i<outCount; i++)
    {
       objc_property_t property = properties[i];
       const char* char_f =property_getName(property);
       NSString *propertyName = [NSString stringWithUTF8String:char_f];
       id propertyValue = [self valueForKey:(NSString *)propertyName];   
       if (propertyValue) [props setObject:propertyValue forKey:propertyName];   
    }   
   free(properties);   
   return props;   
} 
```

参考: [IOS 遍历未知对象的属性和方法](http://blog.csdn.net/crazychickone/article/details/36413671)



然后我们提取出我们需要的, 图标和应用名。

``` objc
[appsInfoArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
        {
            NSDictionary *boundIconsDictionary = [obj performSelector:@selector(boundIconsDictionary)];

            NSString *iconPath = [NSString stringWithFormat:@"%@/%@.png", [[obj performSelector:@selector(resourcesDirectoryURL)] path], [[[boundIconsDictionary objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"]lastObject]];

             UIImage *image = [[[UIImage alloc]initWithContentsOfFile:iconPath] TransformtoSize:CGSizeMake(65, 65)];
            if (image)
            {
                [self.appsIconArr addObject:image];
                [self.appsNameArr addObject:[obj performSelector:@selector(localizedName)]];
            }
        }];
```

如此, `_self.appsIconArr` 和 `_appsNameArr`中存储的就是我们需要的App数据了。



### 越狱

.. 这里我也不懂, 也没去研究。 感兴趣的可以看看 `MobileInstallation.framework`

************

## 扫描动画的实现

这里主要有两个动画。

1. 利用UIScrollView, 实现每个App自动滚动。
2. Animation动画, 中间扫描线的往返运动。

至于动画, 这里我不想介绍太多。 源码里面都写清楚了。(当然, 写的比较粗糙...)

简单带一下扫描线的动画实现:

``` objc
/* 向左移动 */
    CABasicAnimation *animationLeft = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];

    // 动画选项的设定
    animationLeft.duration = 0.5f; // 持续时间
    animationLeft.beginTime = 0.0f;
    animationLeft.autoreverses = YES; // 结束后执行逆动画
    // 动画先加速后减速
    animationLeft.timingFunction =
    [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];

    // 终了帧
    animationLeft.toValue = [NSNumber numberWithFloat:-40];;



    /* 向右移动 */
    CABasicAnimation *animationRight = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];

    // 动画选项的设定
    animationRight.duration = 0.5f; // 持续时间
    animationRight.beginTime = 1.0f;
    animationRight.autoreverses = YES; // 结束后执行逆动画
    // 动画先加速后减速
    animationRight.timingFunction =
    [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];

    // 终了帧
    animationRight.toValue = [NSNumber numberWithFloat:40];;



    /* 动画组 */
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.delegate = self;
    group.duration = 2.0;
    group.repeatCount = 15;


    // 动画结束后不变回初始状态
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;

    // 添加动画
    group.animations = [NSArray arrayWithObjects:animationLeft, animationRight, nil];
    [mySL.layer addAnimation:group forKey:@"moveLeft-moveRight-layer"];

```

******

## 获取已用存储和可用存储

这个没什么好说的了.. Apple提供了API, 直接用就是了。



``` objc
// 获取占用内存
-(void)usedSpaceAndfreeSpace
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] ;
    NSFileManager* fileManager = [[NSFileManager alloc ]init];
    NSDictionary *fileSysAttributes = [fileManager attributesOfFileSystemForPath:path error:nil];
    NSNumber *freeSpace = [fileSysAttributes objectForKey:NSFileSystemFreeSize];
    NSNumber *totalSpace = [fileSysAttributes objectForKey:NSFileSystemSize];
    NSString  * str= [NSString stringWithFormat:@"已占用%0.1f G / 剩余%0.1f MB",([totalSpace longLongValue] - [freeSpace longLongValue])/1024.0/1024.0/1024.0,[freeSpace longLongValue]/1024.0/1024.0];
    NSLog(@"--------%@",str);
}
```

## 垃圾清理

这里我本来是不想提的，毕竟这个功能，苹果是不能接受的。

之前提到了, 猎豹在清理过程中, 会出现“存储已满的提示”。然后我开始考虑了。

1. 为什么要弹出提示？
2. 存储真的在某一刻满了吗？
3. 它清理的时候, QQ直接被杀死, 应用名变成"正在清理..."（和安装中一个状态）。 真有这么厉害? !!!!!!
4. 这个好像在哪里见过...

最后, 我确定了猎豹的实现方式。它只不过是触发了Apple自己的垃圾回收机制而已。

当存储满的时候, 系统会自动帮我们进行垃圾清理, 并弹出提示说明存储已满。

所以, 猎豹只不过是计算了剩余多少存储, 然后制造了一个与之差不多大小的垃圾文件。 然后触发苹果的清理机制。清理完后, 删除之前生成的垃圾文件。再次统计当前可用存储, 差值即为本次清理的垃圾大小。 

是吧, 其实也没那么神~

至于如何快速制造几百M, 甚至几G的垃圾文件? 

``` objc
// 将文件的长度设定为offset 
 -(void)truncateFileAtOffset:offset 
```

`truncateFileAtOffset:offset`就能搞定了。 感兴趣的可以自己研究下。



**********

至此, 猎豹垃圾清理分析完毕。

当然, 这只是我个人的看法。如果有更好的方式, 或者文章中存在任何错误。 欢迎交流指正。