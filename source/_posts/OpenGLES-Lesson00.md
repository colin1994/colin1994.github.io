title: OpenGL ES 开篇

date: 2017-04-01 19:30:10

tags:

- iOS开发
- OpenGLES
- 图像处理

------

在学习 OpenGL ES 之前，总结下我自己接触 OpenGL ES 时的一些疑惑，我相信这也是初学者都会遇到的一些困惑。

## Q & A

**Q：OpenGL 是什么 ?**

> A：**OpenGL**（Open Graphics Library）是 Khronos Group （一个图形软硬件行业协会，该协会主要关注图形和多媒体方面的开放标准）开发维护的一个规范，它是硬件无关的。它主要为我们定义了用来操作图形和图片的一系列函数的 API，需要注意的是 **OpenGL 本身并非 API**。
>
> 而 GPU 的硬件开发商则需要提供满足 OpenGL 规范的实现，这些实现通常被称为”驱动“，它们负责将 OpenGL 定义的 API 命令翻译为 GPU 指令。**所以你可以用同样的 OpenGL 代码在不同的显卡上跑**，因为它们实现了同一套规范，尽管内部实现可能存在差异。

<!--more-->



**Q：OpenGL ES 和 OpenGL 有什么关系 ?**

> A：OpenGL ES（OpenGL for Embedded Systems）是 OpenGL 的子集，针对手机、PDA和游戏主机等嵌入式设备而设计。该规范也是由 Khronos Group 开发维护。
>
> OpenGL ES 是从 OpenGL 裁剪定制而来的，去除了 glBegin/glEnd，四边形（GL_QUADS）、多边形（GL_POLYGONS）等复杂图元等许多非绝对必要的特性，剩下最核心有用的部分。
>
> 可以理解成是一个**在移动平台上能够支持 OpenGL 最基本功能的精简规范**。
>
> ![20170111148411873373682.jpg](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/OpenGLES/image_1_1.jpg)
>
> OpenGL ES 横跨在两个处理器之间，**协调两个内存区域之间的数据交换**。



**Q：为什么要使用 OpenGL ES ?**

> A：通常来说，计算机系统中 CPU、GPU 是协同工作的。CPU 计算好显示内容提交到 GPU，GPU 渲染完成后将渲染结果放入帧缓冲区，随后视频控制器会按照 VSync 信号逐行读取帧缓冲区的数据，经过可能的数模转换传递给显示器显示。所以，尽可能让 CPU 和 GPU 各司其职发挥作用是提高渲染效率的关键。
>
> 正如我们之前提到过，OpenGL 正是给我们提供了访问 GPU 的能力，不仅如此，它还引入了**缓存**（Buffer）这个概念，大大提高了处理效率。
>
> ![20170111148411700373589.jpg](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/OpenGLES/image_1_2.jpg)
>
> 图中的剪头，代表着数据交换，也是主要的性能瓶颈。
>
> **从一个内存区域复制到另一个内存区域的速度是相对较慢的**，并且在内存复制的过程中，CPU 和 GPU 都不能处理这区域内存，避免引起错误。此外，CPU / GPU 执行计算的速度是很快的，而内存的访问是相对较慢的，这也导致**处理器的性能处于次优状态**，这种状态叫做“**数据饥饿**”，简单来说就是**空有一身本事却无用武之地**。
>
> 针对此，OpenGL 为了提升渲染的性能，为两个内存区域间的数据交换定义了**缓存**。缓存是指 **GPU 能够控制和管理的连续 RAM**。程序从 CPU 的内存复制数据到 OpenGL ES 的缓存。通过独占缓存，GPU 能够尽可能以有效的方式读写内存。 GPU 把它处理数据的能力异步地应用在缓存上，意味着 GPU 使用缓存中的数据工作的同时，运行在 CPU 中的程序可以继续执行。
>
> 另外，在 iOS 平台上，[SpriteKit](https://developer.apple.com/library/content/documentation/GraphicsAnimation/Conceptual/SpriteKit_PG/Introduction/Introduction.html#//apple_ref/doc/uid/TP40013043)，[Core Image](https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html#//apple_ref/doc/uid/TP30001185)，[Core Animation](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40004514) 也都是基于 OpenGL ES 实现的，所以在它们各自的领域，也都有不错的表现。
>
> 在图像处理方面，Core Image 提供了便捷的使用以及高效的性能，但是使用原生的 OpenGL ES 会更灵活，可定制性更高，同时支持跨平台。



**Q：学习 OpenGL ES 需要关注哪些内容，本系列会如何介绍 OpenGL ES ?**

> A：当然，如果你想全面系统的了解 OpenGL ES，那么每个接口，每种数据类型，OpenGL 工作原理，图形渲染管线每个阶段做了什么，如何编写着色器脚本等等都是需要了解的。这样的话，对着红蓝宝书学习是没有错的。
>
> 毋庸置疑，这样的学习必定是漫长枯燥的。
>
> - 你可能看了半天，学会渲染一个旋转的立方体，然后被一堆矩阵变换公式折腾的死去活来...
> - 又或者看了半天，了解了一大堆概念，混合，深度测试，模版测试，面剔除等等，但是却不知道什么时候该用...
>
> 无可厚非，OpenGL 需要学习的东西太多太多（至少我个人还只是学了点皮毛），但是它们也有轻重之分，也有更好的学习方式。
>
> 本系列要做的，就是先详述必备的概念，便于之后的学习。然后用最直接的方式，**针对图像处理，逐步实现各种效果**，来慢慢深入学习 OpenGL。毕竟真正做出了东西，才会有学习的动力。



**Q：该系列会使用哪个版本的 OpenGL ES ?**

> A：OpenGL ES 2.0
>
> 目前 iOS 平台支持的有 OpenGL ES 1.0，2.0，3.0。
>
> OpenGL ES 1.0 是**固定管线**，就是只可配置的管线，实现不同效果就好像在电路中打开不同的开关一样，可定制程度低，当然不选择它。
>
> OpenGL ES 2.0，3.0 都是**可编程管线**，各种效果及他们的组合可以通过一般编程的方式实现，自由度高得多。虽然 OpenGL ES 3.0 加入了一些新的特性，但是它除了需要 **iOS 7.0** 以上之外，还对硬件有要求。**需要 iPhone 5S 之后的设备才支持**，这意味着包括 iPhone 5C 上使用的 PowerVR Series6 的 GPU 也是不支持。
>
> 出于现有主流设备的考虑，选择了 OpenGL ES 2.0。



至此，如果觉得本系列文章还值得期待，那么，让我们一起努力吧～