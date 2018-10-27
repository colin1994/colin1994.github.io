title: Core Image 之自定义 Filter~
date: 2016-10-21 22:37:08

tags:

- Core Image

------

Core Image 系列，目前的文章如下：

- [Core Image 你需要了解的那些事~](http://colin1994.github.io/2016/10/21/Core-Image-OverView/)
- [Core Image 之自定义 Filter~](http://colin1994.github.io/2016/10/21/Core-Image-Custom-Filter/)
- [Core Image【3】—— 2017 新特性](https://xiaozhuanlan.com/topic/3095648721)
- [Core Image【4】—— 2018 新特性](https://xiaozhuanlan.com/topic/5094762183)



------



## 前言

最近在研究 Core Image 自定义 Filter 相关内容，重新学习了 Core Image，对 Core Image 的一些优化点也有了一定的了解。故此记录，与君交流~

本文主要讲解 Core Image 自定义滤镜部分的内容，包括如何使用自定义 Filter，如何编写 kernel，QC 工具介绍，注意点以及一些开发技巧。

在这之前，我默认你了解 Core Image 的基本原理以及使用方式。如果没有，我建议你花点时间看看我的上一篇文章：[Core Image 你需要了解的那些事~](http://colin1994.github.io/2016/10/21/Core-Image-OverView/)，它介绍 Core Image 相关基础概念、使用方式、注意点以及和其他图像处理方案的对比，想必会有所收获。

现在，开始吧～![](http://wanzao2.b0.upaiyun.com/system/pictures/1/original/27.png)



<!--more-->



## 自定义 Filter 流程

自定义的 Filter 和系统内置的各种 CIFilter，使用起来方式是一样的。我们唯一要做的，就是实现一个符合规范的 CIFilter 的子类，然后该怎么用怎么用。

这里总结起来就3步：

- 编写 CIKernel：使用 CIKL，自定义滤镜效果。
- 加载 CIKernel：CIFilter 读取编写好的 CIKernel。
- 设置参数：设置 CIKernel 需要的输入参数以及 DOD 和 ROI。

不难看出，这些操作都是围绕 **CIKernel** 展开的，那么，它是什么？ CIKL，DOD，ROI 又是什么鬼？![](http://wanzao2.b0.upaiyun.com/system/pictures/14/original/5.png)



先撇开这些麻烦的东西，我们先这样简单的认为：

- CIKernel 是我们 Filter 对应的脚本，它描述 Filter 的具体工作原理。
- CIKL （Core Image Kernel Language）是编写 CIKernel 的语言。
- DOD，ROI 当做普通的参数处理。



弄清了这些，我们再来看具体操作过程。

拿一个图片翻转效果举例，效果如下：

![2016101449356mirrorX.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/mirrorX.png)

### 1. 编写 CIKernel

**File —> New —> File —> Empty**， 创建一个名为 **MirrorX.cikernel** 的文件。

编辑 .cikernel 文件，比如：

```objc
kernel vec2 mirrorX ( float imageWidth ) 
{
  	// 获取待处理点的位置
  	vec2 currentVec = destCoord();
    // 返回最终显示位置
  	return vec2 ( imageWidth - currentVec.x , currentVec.y ); 
}
```

> PS：这个 kernel 如果有不懂的，可以先跳过。下文会重点说明。



### 2. 加载 CIKernel

**File —> New —> File —> Cocoa Touch Clas**，新建一个继承自 CIFilter 的类，比如 **MirrorXFilter**。

在 **MirrorXFilter.m** 中，添加如下代码：

```objc
static CIKernel *customKernel = nil;

- (instancetype)init {
    
    self = [super init];
    if (self) {
        if (customKernel == nil)
        {
            NSBundle *bundle = [NSBundle bundleForClass: [self class]];
            NSURL *kernelURL = [bundle URLForResource:@"MirrorX" withExtension:@"cikernel"];
            
            NSError *error;
            NSString *kernelCode = [NSString stringWithContentsOfURL:kernelURL
                                                            encoding:NSUTF8StringEncoding error:&error];
            if (kernelCode == nil) {
                NSLog(@"Error loading kernel code string in %@\n%@",
                      NSStringFromSelector(_cmd),
                      [error localizedDescription]);
                abort();
            }
            
            NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
            customKernel = [kernels objectAtIndex:0];
        }
    }
    return self;
}
```



这段代码很简单，重写 **init** 方法，主要就是读取 .cikernel 文件中代表 CIKernel 的字符串（当然， CIKernel 也可以直接写在 NSString 里头，免去文件读取这步），然后使用 **kernelsWithString**

方法获取到真正的 CIKernel 对象。

```objc
+ (nullable NSArray<CIKernel *> *)kernelsWithString:(NSString *)string  NS_AVAILABLE(10_4, 8_0);
```

至此，CIKernel 加载完毕。



### 3. 设置参数

在 **MirrorXFilter.m** 中，添加需要的成员变量。

```objc
@interface MirrorXFilter () {
    CIImage  *inputImage;
}
```

这里只需要一个成员变量，**inputImage** 表示我们的输入图片。

之后，就是设置参数，传入 kernel 中。

```objc
// 使用
- (CIImage *)outputImage
{
    CGFloat inputWidth = inputImage.extent.size.width;
    CIImage *result = [customKernel applyWithExtent: inputImage.extent roiCallback: ^( int index, CGRect rect ) {
        return rect;
    } inputImage: inputImage arguments: @[@(inputWidth)]];
    return result;
}
```

这里只需要重写 outputImage 方法即可。

**extent** 用于返回 CIImage 对象对应的 bounds，通过它可以拿到图片的宽度。

```objc
/* Return a rect the defines the bounds of non-(0,0,0,0) pixels */
@property (NS_NONATOMIC_IOSONLY, readonly) CGRect extent;
```

然后通过  applyWithExtent 来设置对应的参数。

```objc
- (nullable CIImage *)applyWithExtent:(CGRect)extent
                          roiCallback:(CIKernelROICallback)callback
                           inputImage:(CIImage*)image
                            arguments:(nullable NSArray<id> *)args;
```

这里有4个参数。

- extent，也就是之前提到的 DOD，暂且略过。
- callback，也就是之前提到的 ROI，暂且略过。
- image，缺省的 inputImage，传入我们的成员变量 inputImage 即可。
- args，输入参数数组，与 CIKernel 中定义的一一对应。这里只有一个 inputWidth。

> PS：这里可能有同学会有疑惑，为什么 inputImage 可以缺省，inputWidth 就需要传入呢。这里暂且不纠结，下面会详细说明~

如此，一个自定义 Filter 就完成了。简单吧~

![](http://wanzao2.b0.upaiyun.com/system/pictures/16/original/15.png)



### 4. 使用

至于使用上，则和普通的 CIFilter 基本一致。

```objc
#import "MirrorXFilter.h"

// 1. 将UIImage转换成CIImage
CIImage *ciImage = [[CIImage alloc] initWithImage:self.imageView.image];

// 2. 创建滤镜
self.filter = [[MirrorXFilter alloc] init];
// 设置相关参数
[self.filter setValue:ciImage forKey:@"inputImage"];

// 3. 渲染并输出CIImage
CIImage *outputImage = [self.filter outputImage];

// 4. 获取绘制上下文
self.context = [CIContext contextWithOptions:nil];

// 5. 创建输出CGImage
CGImageRef cgImage = [self.context createCGImage:outputImage fromRect:[outputImage extent]];
UIImage *image = [UIImage imageWithCGImage:cgImage];
// 6. 释放CGImage
CGImageRelease(cgImage);
```

如此，我们便可得到翻转后的图片。



### 5. 更多

当然，如果你是一个完美主义者，我觉得你还还可以做更多~

```objc
- (NSDictionary *)customAttributes
{
    return @{
        @"inputDistance" :  @{
            kCIAttributeMin       : @0.0,
            kCIAttributeMax       : @1.0,
            kCIAttributeSliderMin : @0.0,
            kCIAttributeSliderMax : @0.7,
            kCIAttributeDefault   : @0.2,
            kCIAttributeIdentity  : @0.0,
            kCIAttributeType      : kCIAttributeTypeScalar
            },
        @"inputSlope" : @{
            kCIAttributeSliderMin : @-0.01,
            kCIAttributeSliderMax : @0.01,
            kCIAttributeDefault   : @0.00,
            kCIAttributeIdentity  : @0.00,
            kCIAttributeType      : kCIAttributeTypeScalar
            },
         kCIInputColorKey : @{
         kCIAttributeDefault : [CIColor colorWithRed:1.0
                                               green:1.0
                                                blue:1.0
                                               alpha:1.0]
           },
   };
}
```

可以为自定义的 Filter 添加对应的参数描述，以及默认值，范围限制等。

这不是必须的，但却是可取的。至于如何设置，可以参考 CIFilter 对应的 **attributes** 属性，或者参照上面这个例子。



另外，iOS 9之后，引入了 **registerFilterName** , 你可以通过重写 `+ (CIFilter *)filterWithName: (NSString *)name;` ，然后外部使用的时候，跟 CIFilter 一模一样。

```objc
/** Publishes a new filter called 'name'.

 The constructor object 'anObject' should implement the filterWithName: method.
 That method will be invoked with the name of the filter to create.
 The class attributes must have a kCIAttributeFilterCategories key associated with a set of categories.
 @param   attributes    Dictionary of the registration attributes of the filter. See below for attribute keys.
*/
+ (void)registerFilterName:(NSString *)name
               constructor:(id<CIFilterConstructor>)anObject
           classAttributes:(NSDictionary<NSString *,id> *)attributes NS_AVAILABLE(10_4, 9_0);
```

不过需要 iOS 9以上才支持，另外一般用于打包成 Image Units 给他人使用。

正常情况下应该是用不到。如果真有这个需求，可以参考这篇文章： [Packaging and Loading Image Units](https://developer.apple.com/library/prerelease/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_image_units/ci_image_units.html#//apple_ref/doc/uid/TP30001185-CH7-SW12)。



至此，自定义 Filter 的流程就算走完了，我们很容易就可以配置好需要的环境。

然而，真正的自定义部分，才刚刚开始！

![](http://wanzao2.b0.upaiyun.com/system/pictures/183/original/%E5%BC%80%E5%BF%8336.png)



## DOD & ROI

### 1. DOD

DOD ( domain of definition ) ，简单来说就是 Filter 处理后，输入的图片区域。

一般来说，Filter 操作都是基于原图，添加上效果，但是并不会改变图片的大小，显示区域。所以一般与原图的一致即可。

```objc
CGRect dod = inputImage.extent; 
```

但是针对形变类的 Filter，则需要根据输出图片大小，设置正确的 DOD。



### 2. ROI

ROI ( region of interest )，在一定的时间内特别感兴趣的区域，即当前处理区域。

可以简单的理解为：当前处理区域对应于原图中的哪个区域。

ROI 的定义如下：

```objc
/* Block callback used by Core Image to ask what rectangles of a kernel's input images
 * are needed to produce a desired rectangle of the kernel's output image.
 *
 * 'index' is the 0-based index specifying which of the kernel's input images is being queried.
 * 'destRect' is the extent rectangle of kernel's output image being queried.
 *
 * Returns the rectangle of the index'th input image that is needed to produce destRect.
 * Returning CGRectNull indicates that the index'th input image is not needed to produce destRect.
 * The returned rectangle need not be contained by the extent of the index'th input image.
 */
typedef CGRect (^CIKernelROICallback)(int index, CGRect destRect);
```

CIKernelROICallback 在 Core Image 内部进行处理的时候，会多次调用。

**index** 表示输入图片的下标，顺序和 kernel 中的入参顺序一致，从0开始。

**destRect** 表示输出图片的区域。 也就是我们先前设置的 DOD。

那，我们为什么要显示设置 ROI 呢 ？

因为输入图片中，参与处理的实际区域，Core Image 是无法知道的，我们需要显式的告诉 CI 这个区域。

这么讲可能有点难以理解，下面我们看两个具体的例子。

先看一个旋转的例子。

![2016101449433roi_1.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/roi_1.png)

这里就是进行了 x，y 互换操作。很容易得到我们的 DOD：

```objc
CGRect dod = CGRectMake(inputImage.extent.origin.y, inputImage.extent.origin.x, inputImage.extent.size.height, inputImage.extent.size.width);

// e.g.
// 原图片extent (0, 0, 200, 300)
// 旋转后的输出图片 (0, 0, 300, 200)，也就是 DOD
```

那 ROI 应该怎么设置呢 ？我们之前说过，ROI 计算就是计算当前处理区域对应于原图中的哪个区域。

也就是一个逆向过程。

假如，A：输入图片中的某点   B：输出图片中的某点。那么 ROI 计算可以理解成  ROI（B）= A。

理解好这点，我们不难写出这个操作对应的 ROI：

```objc
CIKernelROICallback callback = ^(int index, CGRect rect) {
    return CGRectMake(rect.origin.y, rect.origin.x, rect.size.height, rect.size.width);
};
```

另外，当输入图片不止一个的时候，则需要根据 **index** 来做区别。因为这里的 **rect** 每次都是返回 **DOD**，而不是当前图片的 extent。



## CIKernel 介绍

终于到了本文最重要的部分了，CIKernel 介绍！

![](http://wanzao2.b0.upaiyun.com/system/pictures/187/original/%E5%BC%80%E5%BF%83ForeverAloneExcited.png)

在此之前，我们先了解下它的一些背景知识。

CIKernel 需要使用 Core Image Kernel Language (CIKL) 来编写，CIKL 是 OpenGL Shading Language (GLSL) 的子集，如果你之前有过 OpenGL 着色器编写的经验，这部分你会感觉格外亲切。CIKL 集成了 GLSL 绝大部分的参数类型和内置函数，另外它还添加了一些适应 Core Image 的参数类似和函数。

一个 kernel 的处理过程，可以用下面伪代码表示：

```objc
for i in 1 ... image.width
    for j in 1 ... image.height
        New_Image[i][j] = CustomKernel(Current_Image[i][j])
    end
end
```

也就是说，每个需要处理的 fragment 都会调用一次 kernel 相关操作，每次操作的目的就是返回当前 fragment 对应的结果 fragment，这里 fragment 可以理解为像素点。

所以我们的 kernel，应该是针对一个点，而不是一张图片。



Core Image 内置了3种适用于不同场景的 Kernel，可以根据实际需求来选择。

- CIColorKernel：用于处理色值变化的 Filter。
- CIWarpKernel：用于处理形变的 Filter。
- CIKernel：通用。

CIColorKernel，CIWarpKernel 是官方推荐使用的。某个 Filter，在使用它们能实现的情况下，应该使用它们，即使是一个 CIKernel 拆分成多个 CIColorKernel 以及 CIWarpKernel，也应该用这种方式。因为 Core Image 内部对这两张 Kernel 做了优化。

当然，它们的使用时有限制的。目的一定要很纯粹，比如 CIColorKernel 只能处理色值上的变化。否则就算定义为 CIColorKernel，如果实现上涉及了其他 CIColorKernel 不允许的操作，Core Image 也会当做普通的 CIFilter 处理。

另外，kernel 的入参只支持下面这么几种：

| Kernel routine input parameter | Object    |
| ------------------------------ | --------- |
| sampler                        | CISampler |
| __table sampler                | CISampler |
| __color                        | `CIColor` |
| float                          | NSNumber  |
| vec2, vec3, or vec4            | CIVector  |

简单说明一下：

- sampler：可以理解成纹理，或者图片。外部以 CIImage 形式传入。
- __table sampler：表示颜色查找表（lookup table），虽然它也是图片，但是添加该声明可以避免被修改。外部以 CIImage 形式传入。
- __color：表示颜色。外部以 CIColor 形式传入。
- float：kernel 内部处理都是 float 类型。外部以 NSNumber 形式传入。
- vecN：表示一个多元向量。比如 vec2 可以表示一个点，vec4 可以表示一个色值。外部以 CIVector 形式传入。

至于 kernel 中可以使用的函数，那就太多了。这里不一一枚举，在下面的具体讲解中，会说明几个常用的。如果想了解更多，可以参考  [Core Image Kernel Language Reference](https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CIKernelLangRef/Introduction/Introduction.html#//apple_ref/doc/uid/TP40004397)，以及 [OpenGL ES Shading Language Reference](http://www.shaderific.com/glsl/)。



下面我会通过一个 Demo，讲解这三种 Kernel 的具体用法。

> PS：建议阅读之前，下载 [源码](https://github.com/colin1994/CoreImageDemo) 配合着看。



### 1. CIColorKernel

首先看下官方的定义：

```objc
/*
 * CIColorKernel is an object that encapsulates a Core Image Kernel Language
 * routine that processes only the color information in images.
 *
 * Color kernels functions are declared akin to this example:
 *   kernel vec4 myColorKernel (__sample fore, __sample back, vec4 params)
 *
 * The function must take a __sample argument for each input image.
 * Additional arguments can be of type float, vec2, vec3, vec4, or __color.
 * The destination pixel location is obtained by calling destCoord().
 * The kernel should not call sample(), sampleCoord(), or samplerTransform().
 * The function must return a vec4 pixel color.
 */
NS_CLASS_AVAILABLE(10_11, 8_0)
@interface CIColorKernel : CIKernel
```

很重要的一点：**processes only the color information in images**，它只处理图片的颜色信息。

所以在使用它之前，一定要确保该 Filter 只涉及颜色处理。

CIKL 的语法和大多数 C 阵营一样，变量，运算符，控制结构，函数等都大同小异，所以它的学习成本是很低的。

真正的核心应该是：**如果用这样的语言来实现这个滤镜，也就是我们经常说的算法。**

下面我们以一个 **Vignette** 来实际讲解一下。

它的效果如下所示：

![2016101796011vignette_demo.gif](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/vignette_demo.gif)

不难看出，Vignette 滤镜，它实际上就是一个FOV（Field of View） 的效果，即视野中央看的最清楚，清晰程度与到中心距离呈反比，与人类的视觉是类似的。

![2016101524815vignette.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/vignette.png)

所以针对图片上的每个像素点 A，经过 Vignette 滤镜处理后得到的 B，应该满足：

Vignette（A）＝ A * Darken ＝ B； 而 Darken 的计算依赖 A 与中心点的距离。

如此，我们可以很容易的写出对应的 kernel：

```objc
kernel vec4 vignetteKernel(__sample image, vec2 center, float radius, float alpha)
{
    // 计算出当前点与中心的距离
    float distance = distance(destCoord(), center) ;
    // 根据距离计算出暗淡程度
    float darken = 1.0 - (distance / radius * alpha);
    // 返回该像素点最终的色值
    image.rgb *= darken;

    return image.rgba;
}
```

和 C 语言的一样，函数需要具备：

- 返回类型：vec4
- 函数名：vignetteKernel
- 参数列表：__sample image, vec2 center, float radius, float alpha）
- 函数体：｛｝中的具体实现

有所不同的，kernel 函数需要带上 kernel 关键字，与其它普通函数做区分。一个 .cikernel 文件中，允许包括多个函数，甚至是多个 kernel 函数，不过**函数调用要出现在函数定义之后**！

另外，这里有个特别的参数类型，**__sample** ，和之前讲的 **sampler** 有所不同。因为这里我们使用的是 **CIColorKernel**，在得到高效性能的同时，也有一定的局限性。因为只是处理图片当前位置的颜色信息，所以 **__sample** 提供的 **rgba** 变量足够了，无法获取一些其它的信息。

> 比如在 CIKernel 中，可以通过 sample() 等函数获取其它位置的色值，而在 CIColorKernel 中，无法使用 sample()， sampleCoord() 以及 samplerTransform() 。

下面逐行解释这个 kernel。

```objc
// 计算出当前点与中心的距离
float distance = distance(destCoord(), center) ;
```

**destCoord**

- `varying vec2 destCoord ()`

  返回当前正在处理的像素点所处坐标。(working space coordinates)

这里使用的 CIKL 内置的函数 destCoord，它返回的坐标是基于 **working space** 的。所谓 working space，即工作空间，它的取值范围对应图片实际大小。比如 inputImage 的大小为 300 * 200，那么 destCoord() 返回坐标的取值范围在 (0, 0) - (300, 200)。

**distance**

- `float distance (vec2 p0, vec2 p1)`

  计算向量p0，p1之间的距离

如此便能很容易得到当前点与中心的距离。

```objc
// 根据距离计算出暗淡程度
float darken = 1.0 - (distance / radius * alpha);
```

之后根据清晰程度与到中心距离呈反比这一原理，结合外部控制的 **alpha** 变量，计算出暗淡程度。

```objc
// 返回该像素点最终的色值
image.rgb *= darken;
return image.rgba;
```

这里之前提到，**__sample** 有个 rgba 变量，通过它可以获取到当前处理点的色值。

在 CIKL 中，vec4 的任何一个分量都可以单独获取，也可以组合获取，例如 **image.a**，**image.rrgg** 等，都是可行的。

CIColorKernel 是针对色值的处理，所以它的返回值必须是一个代表色值的 vec4 类型变量。

至此，这个 vignetteKernel 就分析完毕了。很简单吧～



### 2. CIWarpKernel

同样，先看下文档定义：

```objc
/*
 * CIWarpKernel is an object that encapsulates a Core Image Kernel Language
 * function that processes only the geometry of an image.
 *
 * Warp kernels functions are declared akin to this example:
 *   kernel vec2 myWarpKernel (vec4 params)
 *
 * Additional arguments can be of type float, vec2, vec3, vec4.
 * The destination pixel location is obtained by calling destCoord().
 * The kernel should not call sample(), sampleCoord(), or samplerTransform().
 * The function must return a vec2 source location.
 */
NS_CLASS_AVAILABLE(10_11, 8_0)
@interface CIWarpKernel : CIKernel
```

同样，它也有很重要一点：**processes only the geometry of an image**。它只处理图片的几何形状。

所谓的改变几何形状，也就是形变，把原本放置在 A 处的点，用 B 处的点去填充，或者反过来，把原本 B 处的点，挪到 A 处去，也是一样的。

它可以用这个表达式表示：**Warp（A）＝ B；**

所以它和之前的 CIColorKernel 不同，它的返回值是 vec2，代表点的坐标。另外它只允许传入一张图片，所以这里的 inputImage 缺省了。

> 同样的，在 CIWarpKernel 中，无法使用 sample()， sampleCoord() 以及 samplerTransform() 。



下面以一个马赛克，像素化（Pixellate）的例子来讲解。它的效果如下：

![2016101762677pixellate_demo.gif](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/pixellate_demo.gif)

马赛克，比较简单的一种算法是按照固定的间隔取像素点，将图片分割成一些小块，然后每个小块内选择一个像素点，然后把这个区域全部用这个像素点填充即可。这里的每个小块，称作晶格，晶格越大，马赛克效果越好。

依照这个简单算法，我们可以很容易的写出对应的 kernel：

```objc
kernel vec2 pixellateKernel(float radius)
{
    vec2 positionOfDestPixel, centerPoint;
    // 获取当前点坐标
    positionOfDestPixel = destCoord();
    // 获取对应晶格内的中心像素点
    centerPoint.x = positionOfDestPixel.x - mod(positionOfDestPixel.x, radius * 2.0) + radius;
    centerPoint.y = positionOfDestPixel.y - mod(positionOfDestPixel.y, radius * 2.0) + radius;

    return centerPoint;
}
```

同样的，先是获取到当前处理点的坐标，positionOfDestPixel。

```objc
// 获取对应晶格内的中心像素点
centerPoint.x = positionOfDestPixel.x - mod(positionOfDestPixel.x, radius * 2.0) + radius;
centerPoint.y = positionOfDestPixel.y - mod(positionOfDestPixel.y, radius * 2.0) + radius;
```

然后这里的 **mod (x, y)** 和平时使用的一样，计算 **x / y 的余数**。

至于为什么这个式子能获得**中心像素点坐标**，想必一看就懂了吧～（不懂的可以拿张纸画画）

最后返回中心点坐标，替换当前点。

如此，一个简单的马赛克就完成了～



### 3. CIKernel

我们之前说过，CIColorKernel 和 CIWarpKernel 内部做了优化，要尽可能的使用它们。除非真的有特殊需求，是它们无法实现的。下面罗列了 CIColorKernel 和 CIWarpKernel 的一些局限：

**CIColorKernel ：**

- 只处理当前处理点色值，无法获取到其它点的状态。

**CIWarpKernel：**

- 只处理当前处理点位置，无法获取到其它点的状态。
- 只能传入一张图片。

比如说，美图秀秀里面的一些简单马赛克，效果如下：

![2016101864134mosaic_demo.gif](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/mosaic_demo.gif)



它的实现方式，我们可以简单的这么理解：

1. 判断当前点是否在传入点的处理范围内。
2. 如果在，返回马赛克贴图中对应的像素点色值。
3. 如果不在，返回当前点色值。

很明显，它需要两张图片，一张我们的待处理图片，一张马赛克贴图。所以 CIWarpKernel 不适用。

另外，待处理图片与马赛克贴图之前不是一一对应关系，在第二步，返回马赛克贴图中对应的像素点色值中，需要一个映射计算，即当前点对应马赛克贴图中的某点。所以 CIColorKernel 也不适用。

这种情况下，就要使用通用的 CIKernel 了。

下面是对应的 kernel：

```objc
kernel vec4 mosaicKernel(sampler image, sampler maskImage, float radius, vec2 point, float maskWidth, float maskHeight)
{
    // 获取当前点坐标
    vec2 textureCoordinate = destCoord();
    // 计算当前点与传入点的距离
    float distance = distance(textureCoordinate, point);
    if (distance < radius) {
        // 在处理范围内, 计算对应马赛克贴图中的位置
        float resultX = mod(textureCoordinate.x, maskWidth);
        float resultY = mod(textureCoordinate.y, maskHeight);
        return sample(maskImage, samplerTransform(maskImage, vec2(resultX, resultY)));
    }
    else {
        // 返回原图对应像素点色值
        return sample(image, samplerTransform(image, textureCoordinate));
    }
}
```



这里参数比较多，分别对应：

- image：待处理图片
- maskImage：马赛克贴图
- radius：处理范围，半径
- point：传入点，即当前触摸的点
- maskWidth：马赛克贴图宽度
- maskHeight：马赛克贴图高度

上面的 kernel，使用了两个新的函数，sample 和 samplerTransform。

> `vec4 sample (uniform sampler src, vec2 point)` 
> Returns the pixel value produced from sampler src at the position point, where point is specified in sampler space.
>
> 返回图片 src 指定点 point 处的色值。point 是基于 sampler space。
>
> `vec2 samplerTransform (uniform sampler src, vec2 point)` 
> Returns the position in the coordinate space of the source (the first argument) that is associated with the position defined in working-space coordinates (the second argument). (Keep in mind that the working space coordinates reflect any transformations that you applied to the working space.) For example, if you are modifying a pixel in the working space, and you need to retrieve the pixels that surround this pixel in the original image, you would make calls similar to the following, where d is the location of the pixel you are modifying in the working space, and image is the image source for the pixels.
>
> 返回图片 src 指定点 point 处坐标对应的基于 sampler space 的坐标。point 是基于working space。
>
> sampler space 的取值是 0.0 - 1.0，左下角为原点，向右，向上递增。

了解了这两个函数的用法，想必这段代码就没什么需要特别说明的地方了，注释已经很清楚，不再累述。



## 注意点

### 1. premultiply

> `vec4 premultiply (vec4 color)` 
> Multiplies the red, green, and blue components of the color parameter by its alpha component.

将颜色变量的r、g、b元素值分别于 alpha 相乘，返回一个新的四维颜色向量。

> `vec4 unpremultiply (vec4 color)` 
> If the alpha component of the color parameter is greater than 0, divides the red, green and blue components by alpha. If alpha is 0, this function returns color.

将颜色变量的r、g、b元素值分别除以 alpha ，返回一个新的四维颜色向量。

pixel（R, G, B, A） —— (premultiply) ——> (R＊A, G＊A, B＊A, A)

—— (unpremultiply) ——> （R, G, B, A）。

在 Core Image 中，默认颜色空间是 sRGB，在 kernel 中得到的色值，都经过了 Premultiplied Alpha 处理。

至于为什么要执行 Premultiplied Alpha 操作，具体的可以参考这篇文章：[为什么要PREMULTIPLIED ALPHA呢？](https://boundary.cc/2015/07/why-premultiplied-alpha/)



所以如果 kernel 涉及 alpha 相关操作，则需要先执行 unpremultiply，返回正确的 rgba。处理完之后，再执行 premultiply 操作。

比如一个反相滤镜，

![2016101643860rever_1.gif](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/rever_1.gif)![20161016903rever_2.gif](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/rever_2.gif)



它对应的 kernel 应该是这样的：

```objc
kernel vec4 _invertColor(sampler source_image)
{
    vec4 pixValue;
    // samplerCoord 返回当前像素点在 sampler space 中的位置
    // kernel 无法知道该图片是否进行了某些变换操作，所以确保转换为 sampler space 中的位置 是有必要的
    pixValue = sample(source_image, samplerCoord(source_image));
    // 执行 unpremultiply 操作, 得到真正的 RGB 值
    // (R＊A, G＊A, B＊A, A) ——(unpremultiply)——> (R, G, B, A)
    // Core Image is always RGB based.
    unpremultiply(pixValue); 
    // invertColor
    pixValue.r = 1.0 - pixValue.r; 
    pixValue.g = 1.0 - pixValue.g;
    pixValue.b = 1.0 - pixValue.b;
    // premultiply. (R, G, B, A) —> (R＊A, G＊A, B＊A, A)
    return premultiply(pixValue); 
}


// 优化：
// 避免了 unpremultiply 和 premultiply 操作，能更高效执行。
// pixValue 是 (R＊A, G＊A, B＊A, A)， pixValue.a - pixValue.r = (1-r)*a. 和最终 premultiply 得到的结果一样.
kernel vec4 _invertColor(sampler source_image)
{
    vec4 pixValue;
    pixValue = sample(source_image, samplerCoord(source_image));
    pixValue.rgb = pixValue.aaa - pixValue.rgb;
    return pixValue;
}
```



### 2. 关键字

和 C 语言等一样，CIKL 中变量的命名不能和关键字相同。

下面是官方 Session 中翻转对应的 kernel 脚本，这里用到了 input 关键字，导致整个 kernel 错误。

![2016101638470session_error.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/session_error.png)



所以这点一定要牢记。

下面是在 Github 上引起的灾难..

![2016101685335error_1.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/error_1.png)

![2016101697866error_2.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/error_2.png)



### 3. GLSL

CIKL 是 GLSL 的子集，所以**不是 GLSL 中定义的任何东西在 CIKL 中都适用**。但是 glsl 中大多数关键字都是可以用的。另外，CIKL 还提供了 glsl 不支持的，额外的数据类型，关键字，方法，来完善 CIKernel。



### 4. Array, Mat

 In addition, the following are not implemented:

- Data types: `mat2`, `mat3`, `mat4`, `struct`, `arrays`

这些数据类型 Core Image 不支持。但是在 kernel 内部却可以使用 … 

如果当做参数传入，则会报错：

**invalid kernel parameter type; valid types are:  'float', 'vec2', 'vec3', 'vec4', 'sampler’, ‘sample’, ‘color’**

![](http://wanzao2.b0.upaiyun.com/system/pictures/229/original/%E6%82%B2%E4%BC%A41.png)



这也导致了一些依赖关键点的算法无法实现。



### 5. 坐标系

UIKit 坐标系，原点在屏幕左上，x轴向右，y轴向下。

Core Image 和 OpenGL 坐标系原点在屏幕的左下，x轴向右，y轴向上。

所以位置的处理上要注意。



### 6. 局限

kernel 的输入和输出像素可以相互映射。大多数像素处理都可以用这种方式表达，但是有的图像处理操作很困难，甚至不可能。

kernel 的使用上还是有一定的局限性。比如说通过输入图像映射计算直方图是很困难的。也不可以执行种子填充算法或者其他需要复杂条件语句的图像分析操作。



### 7. 性能优化

kernel 中的内容要尽可能简单，高效。

- 展开循环操作会更快。
- 外部能传入的变量，尽量不要在 kernel 中计算获取。



## 开发技巧

### 1. Log

**+(id)kernelsWithString:(id)arg1 messageLog:(id)arg2 ;**

这是  [CIKernel.h](https://github.com/CPDigitalDarkroom/iOS9-SpringBoard-Headers/blob/a11be523d5644a178614585ff57f9638300c2cc0/System/Library/Frameworks/CoreImage.framework/CIKernel.h) 里面的私有方法，在调试阶段可以利用它来打印 kernel 中的错误。

比如：

```objc
NSMutableArray *messageLog = [NSMutableArray array];
NSArray *kernels = [[CIKernel class] 		 performSelector:@selector(kernelsWithString:messageLog:) withObject:kernelCode withObject:messageLog];
if ( messageLog.count > 0) 
  	NSLog(@"Error: %@", messageLog.description);
customKernel = [kernels objectAtIndex:0];

// 错误 log
Error: (
        {
        CIKernelMessageLineNumber = 5;
        CIKernelMessageType = CIKernelMessageTypeError;
        kCIKernelMessageDescription = "unkown type or function name 'destCoordE'; did you mean 'destCoord'?";
        kCIKernelMessageOffset = 142;
    },
        {
        CIKernelMessageLineNumber = 7;
        CIKernelMessageType = CIKernelMessageTypeError;
        kCIKernelMessageDescription = "invalid operands to binary expression ('float' and 'int')";
        kCIKernelMessageOffset = 281;
    }
)
```



### 2. CI_PRINT_TREE

这里 Core Image 中非常实用的一个环境变量，通过设置它，可以很方便的查看 Core Image 工作过程中到底做了什么。比如：

- 工作在 GPU 还是 CPU 上？
- 各个 kernel 的参数值？
- Core Image 是如何链接 kernel？
- DOD，ROI 如何设置的？
- 对于大图如何拆分处理？
- ...

> PS ： 至于 CI_PRINT_TREE 具体应该如何使用，没有找到相关资料，只是在 Session 中提到过。
>
> 包括 ObjC 中国 上的翻译：你可以通过在 Xcode 中设置计划配置（scheme configuration）里的 CI_PRINT_TREE 环境变量为 1 来决定用 CPU 还是 GPU 来渲染，也是很不准确的。
>
> 这里的结论都是自己摸索后的总结，所以可能存在错误或者遗漏，欢迎补充交流～

CI_PRINT_TREE 的设置大致是这样的：分成 A B 两部分，它们可以结合使用。

其中 A 是主要分类，B 是辅助功能。

A 包括：

- 1  initial graph 
- 2  optimized graph 
- 4  tile graph 
- 8  programs graph 
- 16  timing graph 

B 包括：

- graphviz 
- dump-inputs 
- dump-intermediates 
- skip-cpu 
- skip-gpu  
- skip-small 
- frame-<number> 

使用上，比如简单的查看 initial graph 做了什么，即我们添加这个 Filter 的时候，初始化过程执行了什么，传入了哪些参数。当然，这个过程它并没有真正得到渲染，只是一个操作流程列表。设置 CI_PRINT_TREE ＝ 1，如下：

![2016101786999ci_print_tree.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/ci_print_tree.png)

它的结果如下：

```objc
initial graph render_to_display (opengles2 context 1 frame 1) format=RGBA8 roi=[0 156 750 748] = 
  clamptoalpha roi=[0 156 750 748] extent=[0 156 750 748] opaque
    colormatch workingspace-to-devicergb roi=[0 156 750 748] extent=[0 156 750 748] opaque
      affine [2 0 0 2 0 156] roi=[0 156 750 748] extent=[0 156 750 748] opaque
        colorkernel 
  roi=[0 0 375 374] extent=[0 0 375 374] opaque
          affine [1 0 0 -1 0 374] roi=[0 0 375 374] extent=[0 0 375 374] opaque
            colormatch "sRGB IEC61966-2.1"-to-workingspace roi=[0 0 375 374] extent=[0 0 375 374] opaque
              CGImageRef 0x1701c4380 RGBX8 375x374  alpha_one roi=[0 0 375 374] extent=[0 0 375 374] opaque
```

这里有很多关键信息，十分详细。它的阅读顺序是从下往上，我们简单分析下：

- **CGImageRef**： 指代我们传入的图片。
- 每个阶段的 **ROI，DOD**。
- **colormatch "sRGB IEC61966-2.1"-to-workingspace** ：传入的颜色空间
- **vignetteKernel(image,center=[187.5 187],radius=187.5,alpha=0.0537634)** ：kernel 的每个参数
- **colormatch workingspace-to-devicergb**：  输出的颜色空间
- **opengles2** ：工作在 GPU 上
- **context 1 frame 1** ：分别指代当前 context 以及第几帧。每次渲染 frame + 1

当然，这只是 CI_PRINT_TREE 的一部分功能，如果你设置 CI_PRINT_TREE = 8 (programs graph )，你又会得到这样的信息：

```objc
programs graph render_to_display (opengles2 context 1 frame 4 tile 1) format=RGBA8 roi=[0 111 640 640] = 
  program affine(clamp_to_alpha(linear_to_srgb(vignetteKernel(affine(srgb_to_linear(swizzle_bgr1())))))) rois=[0 111 640 640] extent=[0 111 640 640]
    IOSurface 0x60000019ddc0 RGBA8 375x374 alpha_one edge_clamp rois=[0 0 375 374] extent=[infinite][0 0 375 374] opaque
```

这里描述了程序图表，即真正涉及到的操作。

如果觉得这样看比较杂乱，可以试试添加 B 类辅助功能。 比如：**CI_PRINT_TREE = 8 graphviz** ，这样就可以导出 DOT 语言脚本。然后使用 [Graphviz](http://www.graphviz.org/) 工具，即可绘制这个 DOT 语言脚本描述的图形。

比如上面 Log 对应绘制得到的图形如下：

![201610186930programs_graph.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/programs_graph.png)

同样是从下往上看，各个操作的层级关系就很明显了。除了我们提供的 vignetteKernel，Core Image 内部还做了其他的操作，比如 **linear_to_srgb，clamp_to_alpha** 等。它们的具体实现如下：

```objc
Filter DAG:
Node: 0
  original source: vec4 _ci_clamp_to_alpha(vec4 s) { return clamp(s, 0.0, s.a); }
  printed AST: vec4 _ci_clamp_to_alpha(vec4 s) {
  return clamp(s, 0.000000e+00, s.a);
}
  children: 1
End Filter Node

Node: 1
  original source: vec4 _ci_premultiply(vec4 s) { return vec4(s.rgb*s.a, s.a); }
  printed AST: vec4 _ci_premultiply(vec4 s) {
  return vec4(s.rgb * s.a, s.a);
}
  children: 2
End Filter Node

Node: 2
  original source: vec4 _ci_linear_to_srgb(vec4 s)
{
  s.rgb = sign(s.rgb)*mix(s.rgb*12.92, pow(abs(s.rgb), vec3(0.4166667)) * 1.055 - 0.055, step(0.0031308, abs(s.rgb)));
  return s;
}
  printed AST: vec4 _ci_linear_to_srgb(vec4 s) {
  s.rgb = sign(s.rgb) * mix(s.rgb * 1.292000e+01, (pow(abs(s.rgb), vec3(4.166667e-01)) * 1.055000e+00) - 5.500000e-02, step(3.130800e-03, abs(s.rgb)));
  return s;
}
  children: 3
End Filter Node

Node: 3
  original source: vec4 _ci_unpremultiply(vec4 s) { return vec4(s.rgb/max(s.a,0.00001), s.a); }
  printed AST: vec4 _ci_unpremultiply(vec4 s) {
  return vec4(s.rgb / max(s.a, 1.000000e-05), s.a);
}
  children: 6
End Filter Node

Node: 6
  <sample with transform>
  original source: vec4 read_pixel(sampler2D image, vec2 c, mat3 m){ return texture2D(image, (vec3(c, 1.0) * m).xy);}
  printed AST: vec4 read_pixel_6(sampler2D image, vec2 c, mat3 m) {
  return texture2D(image, (vec3(c, 1.000000e+00) * m).xy);
}
  children: 4 7 5
End Filter Node

Node: 4
  image: 6
  printed: uniform lowp sampler2D image6_0
End Filter Node

Node: 7
  position use <_dc>
End Filter Node

Node: 5
  <transform>
  uniform: 6
End Filter Node
```

这个 DAG（有向无环图），具体描述了相关操作的实现过程，比较简单，可以自己看看，这里不累述。



## 工具介绍

Quartz Composer 是一款图形化的编程工具，专门用来生成各种动态视觉效果，包括可交互的界面原型。当然，它也支持 Core Image 滤镜图表的原型。

![2016092073920quartz_1.png](http://7xkc7a.com1.z0.glb.clouddn.com/2016092073920quartz_1.png)

另外，在 QC 上编写 Kernel，除了代码高亮，实时调整效果也很棒。

![2016101158579quartz_2.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/quartz_2.png)



> PS ：[Quartz Composer 下载地址](https://developer.apple.com/downloads/) 
>
> 有精力的话建议把 QC 内自带的所有 example 找出来仔细研究，苹果自己的例子是最好的。它们藏在 /Applications/Quartz Composer.app/Contents/Resources/Examples/Patches（找到 Quartz Composer.app 点右键，选择「Show Package Content」）
>
>  简单了解 Quartz Composer。QCDesigners 上有比较简要的介绍：[QC Designers](https://link.zhihu.com/?target=http%3A//qcdesigners.com/index.php/forums/topic/2/new-to-quartz-composer-start-he)



![2016092059430download_Graphic_Tools_for_XCode.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/download_Graphic_Tools_for_XCode.png)



QC 已经内置了适合 Core Image 的模板，并且实现了动态模糊滤镜效果。不过这里为了了解 QC 的使用方式，不使用内置的模板，从头开始。**File —> New Blank**，创建一个空白的 QC 工程。

> PS： QC 的功能很强大，这里只介绍 Core Image Filter 编辑过程中会用到的，以及我所掌握的...

### 0. 概念介绍

在讲解使用方式之前，介绍几个基本概念。

一次滤镜操作，可以简单理解成： **输入—>(Patch)—>输出**。

Patch 可以理解成 Kernel。

输入则与 Kernel 的参数相对应，可以是 image，color，float...

输入这里一般就是处理后的图像。

还有一个比较特殊的 Patch，Layer。相当于画布，可以把结果图显示在上面，它也有层的概念。



### 1.  工作区介绍

**编辑区：** 这是主面板，主要衔接各个 Patch，以及它们的输入，输出。

![2016101175676panel_1.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/panel_1.png)



**Library：** 这里陈列了 QC 内置的所有 Patch（也可以添加自定义的 Patch 进来），以及它们的详细使用介绍。(通过点击主面板左上角的 Patch Library 打开)

![2016101159731panel_2.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/panel_2.png)

**参数区：** 这里设置各个 Patch 需要的输入参数。(通过点击主面板工具栏上的 Parameters 打开)

![2016101163517panel_3.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/panel_3.png)

**Viewer：** 显示窗口，这里可以对 Layer 做处理，也可以响应用户操作。比如鼠标点击，移动，滑动等。

![2016101121147panel_4.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/panel_4.png)



### 2. Filter 编辑 & 放大眼睛实战

首先，点击 Patch Library，添加一个 Core Image Filter。

![2016101898471qc_demo_1.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/qc_demo_1.png)



选中这个 Filter，点击 Patch Inspector，选择 Settings，进入编辑页面。

改成如下放大眼睛核心代码：

```objc
kernel vec4 coreImageKernel(sampler image, vec2 centerPostion, float radius, float scaleRatio, float aspectRatio)
{
	vec2 currentPosition = destCoord();
	vec2 positionToUse = currentPosition;

     vec2 currentPositionToUse = vec2(currentPosition.x, currentPosition.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
     vec2 centerPostionToUse = vec2(centerPostion.x, centerPostion.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
     
     float r = distance(currentPositionToUse, centerPostionToUse);
     
     if(r < radius)
     {
         float alpha = 1.0 - scaleRatio * (r / radius - 1.0)*( r / radius - 1.0);
         positionToUse = centerPostion + alpha * (currentPosition - centerPostion);
         return sample(image, samplerTransform(image, positionToUse));
     }
     else
     {
     	return sample(image, samplerTransform(image, positionToUse));
     }
}
```

![201610185070qc_demo_2.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/qc_demo_2.png)

> PS：这里不再讲解这个眼睛放大 kernel 的实现原理。
>
> 我强烈建议你在了解了前面的内容后，自己试着解读这个 kernel。

另外，这里还有几个需要说明的地方。

- Define Outp Image Domain of Definition as Union of Input Sampler DODs：输入输出图片的 DOD 一致。
- Show Advanced Input Sampler Options：显示更多选项。
- Edit Filter Function：编辑 Filter 函数。

一般选中第一项就好。 如果有特殊需求，需要自定义 DOD，ROI，则选择 **Edit Filter Function**，进入编辑模式。

```objc
function __image main(__image image, __vec2 centerPostion, __number radius, __number scaleRatio, __number aspectRatio) {
      return coreImageKernel.apply(image.definition, null, image, centerPostion, radius, scaleRatio, aspectRatio);
}
```

这样就可以对默认的 function 进行编辑。在这个 Demo 里面我们不需要，感兴趣可以自己实践下，很简单。

这个时候，主面板应该长这样：

![201610184625qc_demo_3.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/qc_demo_3.png)

然后拖拽一张图片到主面板中，把图片的 Output Image 与 Filter 的 Input Image 想连接。

再从 Patch Library 中选择 Billboard。把 Filter 的 Output Image 与 Billboard 的 Input Image 相连接。

![2016101846779qc_demo_4.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/qc_demo_4.png)

然后选中 Filter，打开 Parameters 面板，输入参数值，即可。

当然，放大眼睛这里需要定位到眼睛的位置，是否可以通过鼠标操作来获取点呢？再或者，眼睛放大效果不够直观，有没有办法鼠标按下显示效果图，松开显示原图呢？在 QC 里头，这些都不是问题~不过工具类的使用，更多的还是得靠自己去摸索，这里不再累述。可以参考 EnlargeEyes.qtz 文件，了解更多的操作。

最终的效果应该是这样的：

![201610184575enlargeEyes_demo.gif](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/CoreImage/enlargeEyes_demo.gif)





## 总结

至此，关于 Core Image 自定义 Filter 相关的内容，就已经都讲完了。这篇近万字的文章，花了很多功夫总结出来，希望，对你有所帮助！

那么，打开脑洞，创造更有趣的 Filter 吧~

Have fun~   



**PS：源码下载地址：** [CoreImageDemo](https://github.com/colin1994/CoreImageDemo)



## 延伸阅读

[Core Image Kernel Language Reference](https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CIKernelLangRef/Introduction/Introduction.html#//apple_ref/doc/uid/TP40004397-CH1-SW1)

Core Image Kernel Language 官方概述。

[Writing Kernels](https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/ImageUnitTutorial/WritingKernels/WritingKernels.html)

官方教程。

[Kernel Routine Rules](http://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/ImageUnitTutorial/Overview/Overview.html#//apple_ref/doc/uid/TP40004531-CH6-SW4)

官方准则。

[Region-of-Interest Methods](https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/ImageUnitTutorial/Overview/Overview.html#//apple_ref/doc/uid/TP40004531-CH6-SW2) 

ROI 教程。

[Quartz Composer User Guide](https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/QuartzComposerUserGuide/qc_intro/qc_intro.html#//apple_ref/doc/uid/TP40005381-CH201-TPXREF101)

QC 官方指南。

