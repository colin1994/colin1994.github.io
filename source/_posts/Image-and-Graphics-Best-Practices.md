title: Image and Graphics Best Practices
date: 2019-12-22 23:35:29

tags:

- 图像处理
- iOS 开发
- WWDC
- 性能优化

------



> PS：
> 本文所得数据测试环境：iPhone 7 Plus，iOS 10，Xcode 9.1



## 预备知识

### 解码

**Q：什么是解码**

**A：**将**压缩的图片数据**解码成未压缩的**位图**形式，即**二进制数据**转换成**像素数据**的过程。

> PS：
>
> 这是一个非常耗时的 CPU 操作。



<!--more-->



**Q：是否可以不要解码（不经过解压缩，直接将图片显示到屏幕上）**

**A：不可以。**

逆推分析如下：

* GPU 可处理的是像素数据。
* 位图是一个像素数组，承载图片的原始像素数据，数组中的每个元素，就是一个像素。
* 我们平时用的 bmp，jpg，gif，png 等是一种压缩的位图图形格式。





### Buffer

Buffer 是一段**连续的内存区域**。

> PS：
>
> 当我们讨论内存的时候，如果它是由相同大小的元素（通常是相同的内部结构）组成的，我们更倾向于使用 Buffer 这个词来描述。

这里，我们详细讨论常见的三种：Data Buffer，Image Buffer 和 Frame Buffer。



**Data Buffer**

![image_06](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_06.png)

Data Buffers  存储图片文件（Image file，test.png）的元数据，即之前提到的，压缩后的二进制数据。

它的大小和图片存储在磁盘中文件大小一致。



**Image Buffer** 

![image_04](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_04.png)

Image Buffers 代表了图片（Image）在内存中的表示，每个元素代表一个像素点的颜色，即我们上文提到的位图。

它的大小与图像大小成正比。

> PS：
>
> 通常，图片的色彩空间是 sRGB，即每个像素占四个字节。
>
> 解压缩后的图片大小 = 图片的像素宽  * 图片的像素高  * 每个像素所占的字节数 (4)



**Frame Buffer**

![image_05](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_05.png)

Frame Buffer 存储了 App 的每帧的实际渲染输出（actual rendered output）。

当 App 更新视图层级（view hierarchy）的时候，UIKit 会结合 UIWindow 和 Subviews，渲染出一个 frame buffer，然后按一定帧率显示到屏幕上。

> PS：
>
> 从这个角度来说，这里的 frame buffer 和 GL 里面提到的 framebuffer 有所区别。GL 里头的定义更广泛，更通用。



综上，我们可以得到这样的一个渲染流程： ![image_08](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_08.png)



> 小结：
>
> * 图片加载到显示，需要有个解码操作，这是一个非常耗时的 CPU 操作。
> * 解码后，会导致内存占用变高。



现在记住两个点，准备开始我们接下去的 WWDC 2018 Session 219 的学习。



----------




## 理论
### 1. Memory & CPU

CPU 占用越高，耗电越快，响应速度越慢。

**内存占用高，引起 CPU 占用高，导致耗电快，响应速度慢。**

![image_01](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_01.png)



### 2. Image Rendering Pipeline

 从 MVC 架构的角度划分，UIImage 表示 Model，UIImageView 表示 View。

Model （UIImage）负责加载数据，View （UIImageView）负责展示数据。

![image_02](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_02.png)

在 UIImage 需要显示到 UIImageView 的过程中，还有一个**隐藏的操作**，就是我们之前提到的**解码**。

![image_03](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_03.png)

结合上文我们提到的，图像渲染过程，具体可以描述为：

我们通过 Data Buffer 加载 UIImage，当 UIImage 需要显示到 UIImageView 上时，UIImage 需要进行解码，生成 Image Buffer。之后被渲染到屏幕上。

![image_07](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_07.png)



## 最佳实践

### 1.降低采样（downsample） 

![image_09](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_09.png)

我们有时候，**视图本身比较小，图片比较大**（如上图的右下角图示），如果直接展示这个图片，会产生不必要的内存和 CPU 消耗。所以需要采取 **downsample**，即生成缩略图的方式。

![image_10](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_10.png)

通过获取到合适大小的图片，然后再解码显示。

![image_11](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_11.png)

这里有两个小细节，

* 设置 **kCGImageSourceShouldCache** 为 **false**，避免缓存解码后的数据。在 64 位设备上默认是缓存的。


* 设置 **kCGImageSourceShouldCacheImmediately** 为 **true**，**强制解码。避免等到显示渲染时才解码**（默认选项）。

```objc
/** Keys for the options dictionary of "CGImageSourceCopyPropertiesAtIndex"
 ** and "CGImageSourceCreateImageAtIndex". **/

/* Specifies whether the image should be cached in a decoded form. The
 * value of this key must be a CFBooleanRef.
 * kCFBooleanFalse indicates no caching, kCFBooleanTrue indicates caching.
 * For 64-bit architectures, the default is kCFBooleanTrue, for 32-bit the default is kCFBooleanFalse.
 */

IMAGEIO_EXTERN const CFStringRef kCGImageSourceShouldCache  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);

/* Specifies whether image decoding and caching should happen at image creation time.
 * The value of this key must be a CFBooleanRef. The default value is kCFBooleanFalse (image decoding will
 * happen at rendering time).
 */
IMAGEIO_EXTERN const CFStringRef kCGImageSourceShouldCacheImmediately  IMAGEIO_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0);
```



### 2. Prefetching + Background decoding

通常情况下，图片列表，配置图片的时候，是这么操作的：

![image_12](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_12.png)

当用户快速滑动的时候，就会频繁在主线程在进行图片的解码操作。

而我们之前提到过，解码操作是很耗时的，这就导致了在滑动过程中产生卡顿。

当然，我们可以通过 **Prefetching** 和 **Background decoding** 来优化这个流程。



**Prefetching :**

Prefetching 即**预加载**，提前为之后的 Cell 准备好数据。算是比较常见的做法，一些 Feed 流里面，基本都会有这样的操作。

iOS 10 之后，引入的 **tableView(_:prefetchRowsAt:)** 则更加方便预加载的实现。

感兴趣的可以了解下这个 Session：[WWDC 2018 - Session 225 - A Tour of UICollectionView](https://developer.apple.com/videos/play/wwdc2018/225/)



**Background decoding：**

通过多线程，在子线程获取解码后的图片，然后展示到主线程上，降低 CPU 的占用。

![image_13](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_13.png)

同样，这里也有个小技巧，用了一个**串行队列**来管理，而不是直接用 **DispatchQueue.global**，避免 **Thread Explosion** 的发生。

> PS：
>
> 当我们要求 CPUs 做的事超过它们能力范围外的时候，就会发生 Thread Explosion。
>
> 举个例子：
>
> 我们要同时解码 6 张图片，但是在只有 2 个 CPU 的设备上，我们不能同时完成所有的事情（不能在不存在的 CPU 上并行操作）。
>
> 为了避免在异步发送到全局队列时出现死锁，GCD 将创建新线程来捕获我们要求它做的工作。
>
> 然后，CPU 会花很多时间在这些线程之间移动，尝试在我们要求系统为我们做的所有工作上取得渐进的进展。
>
> 线程的切换是很昂贵的。如果有一个专门的线程来负责处理，效率会提高。
>
> 更多关于 Thread Explosion，可以查阅 [iOS App 使用 GCD 导致的卡顿问题](http://mrpeak.cn/blog/ios-gcd-bottleneck/)



到此，解码相关的内容就已经阐述完了，不过，对于之前提到的几点，是否有疑惑呢？

* UIImage 只有等到需要渲染（[UIImageView setImage:xxx]）的时候才解码？


* 解码是一个非常耗时的操作？

* 图片内存占用，具体都是哪些？

* imageNamed 加载图片会有缓存？

  


关于这几点，我们再具体验证一下。



#### 1. UIImageView setImage: 隐式解码

先上结论：

> 当使用 UIImage 或 CGImageSource 的那几个方法创建图片时，图片数据并不会立刻解码。
>
> 直到图片设置到 UIImageView 或者 CALayer.contents 中去，并且 CALayer 被提交到 GPU 前，CGImage 中的数据才会得到解码。
>
> 这一步是发生在主线程的，并且不可避免（UI 操作 setImage 必须在主线程，导致隐式解码也在主线程进行）。



添加一个简单的 setImage 操作，使用 **Instruments - Time Profiler** 验证如下：

```objective-c
for (int i=0; i<500; i++) {
      NSString *path = [[NSBundle mainBundle] pathForResource:@"test_4.jpg" ofType:nil];
      UIImage *image = [UIImage imageWithContentsOfFile:path];

      UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 200, 200)];
      imageView.image = image;
      [self.view addSubview:imageView];
  }
```

![image_26](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_26.png)

这里出现了很明显的 **decode**，**decompress** 关键字。

并且耗时的操作，也都集中在了 **createPixelBuffer** 这个操作上。

如果把 **imageView.image = image;** 注释掉，则 CPU 消耗，内存占用，耗时，都会同步降低，找不到解码相关操作。![image_27](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_27.png)







如果是 png，

![image__1](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image__1.png)

png 解码部分，应该是发生在 png_READ_IDAT_dataApple。  耗时都集中在这里。

PNG 的二进制数据可以分为 2 大部分：文件签名（Signature）和数据块（Chunks）。

Chunks 分为 IHDR、PLTE、TRNS、GAMA、IDAT 和 IEND。

其中，IDAT 存放着编码过的图像数据。所以，这里应该就是解码的操作。



很明显AppleJPEG的decode方法是做解码的函数。jpeg与png调用了两个同样函数，而不同的图片调了不同的解码函数。在画布上画图片的时候，会调用*ImageProviderCopyImageBlockSetCallback*设置*callback*，然后调用*copyImageBlock*，再调用设置的*callback*，但是解码函数是由*copyImageBlock*的调用的还是由*callback*调用的无法验证。

那*ImageProviderCopyImageBlockSetCallback*与*CGDataProviderCopyData*是否有关系？经过测试，*CGDataProviderCopyData*内部也会调用*ImageProviderCopyImageBlockSetCallback*和*copyImageBlock*。而且*CGDataProviderCopyData*得到的*CFDataRef*是解码过的像素数组。

结论：Image解码发生在*CGDataProviderCopyData*函数内部调用*ImageProviderCopyImageBlockSetCallback*设置的*callback*或者*copyImageBlock*函数，根据不同的图片格式调用的不同的方法中。





####2. 解码耗时 

之前一直提到解码是个耗时操作，那具体耗时多少呢？

这里对比了 **SDWebImage**，**YYKit** 以及 **UIGraphics**，分别解码 50 张 3000 * 4000 的图片，数据如下：

| 解码方式 | SDWebImage | YYKit  | UIGraphics |
| ---- | ---------- | ------ | ---------- |
| 耗时   | 4700ms     | 4800ms | 5000ms     |

平均解码一张图片耗时 100ms，这几乎是可以感知到的卡顿。

> PS：
>
> SDWebImage，YYKit 内部都是通过更底层的 ImageIO 接口实现的。
>
> UIGraphics 这里没有 SDWebImage，YYKit 那么多的状态判断，类型检测，代码简单，但是反而效率最低。



#### 3. 图片内存占用

最早我们提到了 Data Buffer 这个概念，那创建出来一个 UIImage，是否会有 Data Buffer 占用内存呢？

```objective-c
for (int index =0; index < 10000; index++) {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.jpg" ofType:nil];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    [self.array addObject:image];
}
```

尝试往数组里添加 10000 个 UIImage，发现运行良好。如果存在 Data Buffer 的话，一张 8.7M，那早就该 OOM 了。

那么具体发生什么了呢？借助 **Instruments - VM Tracker**，发现一个比较有意思的现象。

![image_14](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_14.png)

![image_15](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_15.png)

![image_16](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_16.png)



在创建 UIImage 的过程中，其实是有生成 Data Buffer 的，如上图 8.19M 的 **Mapped File**。随后，生成 CGImage 等一系列 ImageIO 对象，Mapped File 释放。这过程没有涉及解码操作。看起来只是维护了一系列句柄，然后直接映射到磁盘文件。



采用不同方式解码，其内存占用如下：

| 解码方式                   | Category              | 1000 × 1333 | 3000 × 4000 | 6065 × 5788 | 8688 × 5792 |
| ---------------------- | --------------------- | ----------- | ----------- | ----------- | ----------- |
| **UIImageView.image**  | IOKit                 | 2M          | 17M         | 50M         | 72M         |
| **YYKit / SDWebImage** | VM: CG raster data    | 5M          | 45M         | 134M        | 191M        |
| **UIGraphics**         | VM: ImageIO_jpeg_Data | 5M          | 45M         | 134M        | 134M        |



这里一个比较有意思的现象就是，**UIImageView 隐式的解码，貌似生成的 Image Buffer 都会偏小**，数据上看，占用的实际内存约为常规解码占用内存的 **50%** 左右。而其他几个，则和我们之前提到的 Image Buffer 计算规则一致。

难道内部有优化，或者纹理压缩？

压测解码 30张 6065 × 5788 的图片，UIImageView 的方式，内存占用达到 1.5G，还没有崩溃。

而其他方式，相同情况下，不出意外，提示无法分配内存，黑屏，甚至直接崩溃。

```objc
Jun 17 22:12:40  PerformanceDemo[1043] <Error>: CGSImageDataLock: Cannot allocate memory
```

**可见，UIImageView 内部是有做优化的。**



#### 4. 正确：imageNamed 缓存 

官方 Documents 说明：

> ## Discussion
>
> This method looks in the system caches for an image object with the specified name and returns the variant of that image that is best suited for the main screen. If a matching image object is not already in the cache, this method locates and loads the image data from disk or from an available asset catalog, and then returns the resulting object.
>
> The system may purge cached image data at any time to free up memory. Purging occurs only for images that are in the cache but are not currently being used.
>
> In iOS 9 and later, this method is thread safe.
>
> ### Special Considerations
>
> If you have an image file that will only be displayed once and wish to ensure that it does not get added to the system’s cache, you should instead create your image using [`imageWithContentsOfFile:`](https://developer.apple.com/documentation/uikit/uiimage/1624123-imagewithcontentsoffile?language=objc). This will keep your single-use image out of the system image cache, potentially improving the memory use characteristics of your app.

使用 **imageNamed** 创建的 UIImage，会立即被加入到 NSCache 中（解码后的 Image Buffer），直到收到内存警告的时候，才会释放不在使用的 UIImage。

有个私有 API，就是处理释放工作的： `[UIImage _flushSharedImageCache];`

如果不需要缓存，可以使用 **imageWithContentsOfFile**。它每次都会重新申请内存，相同图片不会缓存。

验证如下：

| 路径          | imageNamed | imageWithContentsOfFile |
| ----------- | ---------- | ----------------------- |
| 未加载图片       | 2M         | 2M                      |
| 加载 30 张相同图片 | 50M        | 1000M                   |
| 释放图片        | 50M        | 2M                      |

![image_028](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_028.png)

![image_029](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_029.png)

综上，imageNamed 和 imageWithContentsOfFile 各有自己的存在意义和适用场景，具体问题具体分析～



## 5. Prefer Image Assets

图片的主要来源，主要有：

1. Image Assets
2. Bundle，Framework 里面的图片
3. 在 Documents， Caches 目录下的图片
4. 网络下载的数据



这里 Apple 极力推荐我们使用 **Image Assets**，提到了主要的四点优化：

* 优化了基于名称和特效的查找，比起从磁盘读取等，查找图片更快
* 运行时，对内存的管理也有优化
* App Slicing，瘦包。iOS 9 后会从 **Image Assets** 中保留设备支持的图片 （2x 或者 3x）
* iOS 11 后的 **Preserve Vector Data**。它可以发挥矢量图的功能，即放大也不会失真（实际上，只是保留了 PDF 文件，然后在取 image 的时候，再根据 Size，动态生成对应的 image。）




## 6. Custom Drawing

这里指通过重写 UIView 的 **drawRect** 方法，来实现自定义视图。

Apple 举了个错误的例子：

![image_19](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_19.png)

要实现 Photos 里面的 **LIVE** 视图，我们需要自定义，这里通过重写 UIView 的 drawRect 方法来实现：

![image_20](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_20.png)

这种做法是不被建议的，它会造成额外的内存开销。

下面通过对比 UIImageView 设置图片，和 UIView draw，来具体分析。

![image_21](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_21.png)

我们知道 UIView，**实际上负责渲染的是 CALayer，而 UIView 主要做内容的管理和事件的响应。**

当我们往 UIImageView 上设置图片的时候，解码后的 Image Buffer 实际是被 CALayer 持有，作为它的 **contents**。

对于通过重写 drawRect 自定义视图，和这个很相似，但略有不同。

layer 会负责创建一个 Backing store，它的大小和视图本身成正比（ UIView Size 乘以 contentsScale）， 之后的 drawRect 会绘制在 Backing store，然后，根据显示硬件的需要将其传递到 frame buffer 中。这里，生成的 Image Buffer 就会比较大。

自定义一个视图，大小和屏幕大小一致，重写 drawRect，不做任何操作。验证如下：

![image_30](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_30.png)

额外占用了 10.5 M （1242 * 2208 * 4 / 1024 / 1024）内存。十分可观。



> PS:
>
> iOS 12，对 backing store 有做优化，它的大小会根据图片的色彩空间，动态改变。
>
> 在此之前，如果你使用 sRGB 格式，但是实际绘制的内容，只使用了单通道，那么大小会比实际要的大，造成不必要开销。
>
> iOS 12 会自动优化这部分，但是前提是你把控制权交给系统，而不要自己去显式设置相关的格式。
>
> 因此，检查你的 layerWillDraw 的实现。确保在 iOS 12 上运行时，不会因此影响了系统的自动优化（不要设置 CALayer.contentsFormat）。
>
> ```objective-c
> /* If defined, called by the default implementation of the -display method.
>  * Allows the delegate to configure any layer state affecting contents prior
>  * to -drawLayer:InContext: such as `contentsFormat' and `opaque'. It will not
>  * be called if the delegate implements -displayLayer. */
>
> - (void)layerWillDraw:(CALayer *)layer
>   CA_AVAILABLE_STARTING (10.12, 10.0, 10.0, 3.0);
>
> /* A hint for the desired storage format of the layer contents provided by
>  * -drawLayerInContext. Defaults to kCAContentsFormatRGBA8Uint. Note that this
>  * does not affect the interpretation of the `contents' property directly. */
>
> @property(copy) NSString *contentsFormat
>   CA_AVAILABLE_STARTING (10.12, 10.0, 10.0, 3.0);
> ```
>
> 【待验证】



虽说 iOS 12 有这个优化，但是我们可以做得更好。除非万不得已，不要重写 drawRect。

因为重写 drawRect 会不可避免的创建一个 backing store，而 backing store 并不是必须的，比如设置背景颜色就不需要（除非是 pattern colors）。

```objc
+ (UIColor *)colorWithPatternImage:(UIImage *)image;
```

 pattern colors：

![image_23](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_23.png)

如果需要显示 pattern colors 背景，可以通过 UIImageView 来实现，设置适当的平铺（tiling）参数。



所以，我们可以通过 UIKit 封装好的一些属性，拆分成各个子视图，来实现。


![image_22](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_22.png)



同样，这里也有几个细节。

**圆角**

绘制圆角的时候，我们应该使用 **CALayer.cornerRadius**，因为 Core Animation 能够在不额外分配任何内存的情况下，直接渲染出圆角。

而不要使用 **UIView.maskView** 或者 **CALayer.maskLayer**，虽然它们功能更强大，但是需要额外的内存存储 Mask。同样的，复杂情况下，建议使用 UIImageView，配合对应的切片。



**改变图片颜色**

当想显示不同颜色图片的颜色时候，可以直接通过 UIImageView 渲染，不占用额外的内存。从而达到图片复用目的。

而不是先拷贝一份原始图，然后根据颜色生成结果图。

![image_24](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Image-and-Graphics-Best-Practices/image_24.png)

具体做法是：

* UIImage.withRenderingMode(_:) 
* UIImageView.tintColor




**文本**

UILabel 优化了单色的文本的显示，可节省 75% 的 Backing Store。

并能自动更新 Backing Store 的大小来适配富文本和 emoji。 



## 7. Drawing Off-Screen

当我们需要离屏渲染，创建自己的 Image Buffers 时，我们通常会使用 UIGraphicsBeginImageContext，这个是比较早的接口。而 Apple 推荐我们使用 UIGraphicsImageRenderer，因为它的性能更好，并且支持广色域（wide color content）。



同样，在 iOS 12，UIGraphicsImageRenderer 也支持了上文提到的对 CALayer backing store 的优化，可以根据绘制的具体操作，动态优化 backing store 的大小。

> 待验证



## 8. CPU & GPU

当需要显示实时处理效果的时候，建议使用 Core Image。

UIImageView 针对 CIImage 有做优化，如果一个 UIImage 是通过 UIImage.init(ciImage:) 这种方式创建的，

设置到 UIImageView 上的时候，UIImageView 会在 GPU 上执行 Core Image 相关操作。GPU 处理很高效，并且能释放 CPU 压力。





## 延伸阅读

[WWDC2018 图像最佳实践](https://juejin.im/post/5b1a7c2c5188257d5a30c820)

[iOS 保持界面流畅的技巧](https://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/)

[iOS图片加载速度极限优化—FastImageCache解析](http://www.cocoachina.com/ios/20150210/11128.html)

[谈谈 iOS 中图片的解压缩](http://blog.leichunfeng.com/blog/2017/02/20/talking-about-the-decompression-of-the-image-in-ios/)

[如何打造易扩展的高性能图片组件](https://zhuanlan.zhihu.com/p/26955368)

