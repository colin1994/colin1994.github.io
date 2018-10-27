title: OpenGL ES 环境搭建

date: 2017-04-09 14:10:10

tags:

- iOS开发
- OpenGLES
- 图像处理

------

在[上篇文章](http://colin1994.github.io/2017/04/01/OpenGLES-Lesson01/)中，已经介绍了 OpenGL ES 的一些基础概念以及大致工作流程。

在本文中，我们将会介绍在 iOS 平台上如何接入 OpenGL ES，并搭建好基础环境，实现设置背景色功能。它是之后任何实战的基础模版。在搭建过程中，会针对之前介绍的一些概念，再结合代码讲解。

> PS：这一节是 OpenGL ES 的入门，也是最重要的一部分。再绚丽的特性，都是在此基础上完成的。所以理解它是很有必要的～

设置蓝色背景后，效果如下：

![2017012639178QQ20170126-231448@2x.png](http://7xkc7a.com1.z0.glb.clouddn.com/2017012639178QQ20170126-231448@2x.png)

<!--more-->



## 0. 初始工程

你可以从[这里](https://github.com/colin1994/OpenGLES/blob/master/Lesson02/OpenGLESDemo_1.zip)下载到初始工程，避免重复实现一些和本节内容不相干的事情。

在这个初始工程里面，已经实现了新建一个继承自 **UIView** 的 **GLView**，这个自定义的视图将用来显示 OpenGL ES 的渲染内容。然后在 Main.storyboard 中，将 ViewController 的 view 改成 **GLView** 类型，即可。

![2017012663829D0A3C5CE-818A-4C93-8D3E-1C302E29220F.png](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/OpenGLES/image_3_1.png)

至此，我们的工作都将在 **GLView** 中展开。

在 **GLView.h** 中，先声明一些将要用到的成员变量：

```objc
@interface GLView : UIView
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    GLuint       _framebuffer;
    GLuint       _renderbuffer;
}
```

另外，在 **GLView.m** 中，需要导入对应的 OpenGLES 框架（framework），如下：

```objc
@import OpenGLES;
```

> PS：
>
> `@import `是 iOS 7 之后的新特性语法，这种方式叫 Modules（模块导入） 或者 Semantic import（语义导入）。用这种方式，不用手动添加 framework，系统会自动帮我们 link，是一种更好的头部预处理的执行方式（相比之前的 #import）。
>
> - Imports complete semantic description of a framework
> - Doesn't need to parse the headers
> - Better way to import a framework’s interface
> - Loads binary representation
> - More flexible than precompiled headers
> - Immune to effects of local macro definitions (e.g. `#define readonly 0x01`)
> - Enabled for new projects by default



## 1. CAEAGLLayer

CAEAGLLayer 实现了 **EAGLDrawable** 协议，它是 Apple 专门为 OpenGL ES 准备的一个图层类。

所以想要显示 OpenGL ES 的内容，需要把它默认的 layer 设置为一个特殊的 layer（**CAEAGLLayer**），我们简单的重写 `layerClass` 即可：

```objc
+ (Class)layerClass {
    return [CAEAGLLayer class];
}
```

另外，为了方便起见，我们使 **_eaglLayer** 这个成员变量指代 **self.layer**，这样除了调用上方便外，可读性也更好。

```objc
- (void)setupLayer {
    // 用于显示的layer
    _eaglLayer = (CAEAGLLayer *)self.layer;
    
    // CALayer 默认是透明的（opaque = NO），而透明的层对性能负荷很大。所以将其关闭。
    _eaglLayer.opaque = YES;
}
```

> PS：
>
> By default, CALayers are set to non-opaque (i.e. transparent). However, this is bad for performance reasons (especially with OpenGL), so it’s best to set this as opaque when possible.
>
> CAEAGLLayer: the default value of the `opaque' property in this class is true, not false as in CALayer.
>
> 透明对性能影响较大，CAEAGLLayer 中的 **opaque** 默认值已经是 YES 了。



至此 layer 的配置已经就绪，下面创建并设置与 OpenGL ES 相关的东西。



## 2. EAGLContext

上篇已经提到了**上下文**概念，即 **EAGLContext** 对象，这个 context 管理所有使用 OpenGL ES 进行渲染的状态，命令以及资源信息。

通过 `initWithAPI` 创建完 context，然后需要使用 `setCurrentContext` 将它设置为当前 context，因为我们之前提过，context 可以同时存在多个，需要指定当前环境对应的 context。

```objc
- (void)setupContext {
    if (!_context) {
        // 创建GL环境上下文
        // EAGLContext 管理所有通过 OpenGL ES 进行渲染的信息.
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
}
```

这里的 **kEAGLRenderingAPIOpenGLES2** 即对应的 OpenGL ES 版本，它的定义如下：

```objc
/* EAGL rendering API */
typedef NS_ENUM(NSUInteger, EAGLRenderingAPI)
{
	kEAGLRenderingAPIOpenGLES1 = 1,
	kEAGLRenderingAPIOpenGLES2 = 2,
	kEAGLRenderingAPIOpenGLES3 = 3,
};
```



## 3. Renderbuffer

有了上下文，OpenGL ES 还需要在一块 buffer 上进行渲染，这块 buffer 就是 **Renderbuffer**（OpenGL ES 总共有三大不同用途的 buffer，分别是 **color buffer，depth buffer 和 stencil buffer**，这里是最基本的 color buffer）。可以简单的把 renderbuffer 理解成用于展示的窗口。

它的创建过程如下：

```objc
- (void)setupRenderBuffer {
    // 生成 renderbuffer ( renderbuffer = 用于展示的窗口 )
    glGenRenderbuffers(1, &_renderbuffer);
    // 绑定 renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    // GL_RENDERBUFFER 的内容存储到实现 EAGLDrawable 协议的 CAEAGLLayer
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}
```

`glGenRenderbuffers` 用于生成 renderbuffer，并分配 id。它的原型为：

```c
void glGenRenderbuffers (GLsizei n, GLuint* renderbuffers)
```

- n：表示申请生成 renderbuffer 的个数。
- renderbuffers：返回分配给 renderbuffer 的 id。

> PS：返回的 id 不会为 0，0 是OpenGL ES 保留的，0 则表示这个 buffer 这个不存在或者创建失败。

所以，一般会通过 id 来判断某个 buffer 是否存在，执行对应的操作。比如在 gen 之前，释放旧的 renderbuffer，确保之后的操作无误。

```objc
// 释放旧的 renderbuffer
if (_renderbuffer) {
    glDeleteRenderbuffers(1, &_renderbuffer);
    _renderbuffer = 0;
}
```

`glBindRenderbuffer` 用于绑定 renderbuffer，将指定 id 的 renderbuffer 设置为当前 renderbuffer。它的原型为：

```c
void glBindRenderbuffer (GLenum target, GLuint renderbuffer) 
```

- target：表示当前 renderbuffer，必须是 **GL_RENDERBUFFER**。
- renderbuffer：某个 renderbuffer 对应的 id（比如使用 glGenRenderbuffers 生成的 id）。

`renderbufferStorage` 用于将 GL_RENDERBUFFER 的内容存储到实现 **EAGLDrawable** 协议的 CAEAGLLayer。它的原型为：

```objc
/* Attaches an EAGLDrawable as storage for the OpenGL ES renderbuffer object bound to <target> */
- (BOOL)renderbufferStorage:(NSUInteger)target fromDrawable:(id<EAGLDrawable>)drawable;
```

> PS：
>
> 这个函数内部，会使用 drawable（_eaglLayer）的相关信息（设置存储在 drawableProperties 属性中）作为参数，调用 glRenderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
>
>  `glRenderbufferStorage` 指定存储在 renderbuffer 中图像的宽高以及颜色格式，并按照此规格为之分配存储空间。

至此，我们的第一个 buffer 创建完毕了。注意理解 **gen** 和 **bind** 这两个概念，它将会贯穿我们 OpenGL ES 的整个学习过程。



## 4. Framebuffer

接下去我们将会创建 framebuffer object，它通常也被称之为 **FBO**。

我们之前提到过了，它相当于 buffer（color, depth, stencil）的管理者，三大 buffer 可以附加到一个  FBO 上。

它的创建过程如下：

```objc
- (void)setupFrameBuffer {
    // 释放旧的 framebuffer
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    // 生成 framebuffer ( framebuffer = 画布 )
    glGenFramebuffers(1, &_framebuffer);
    // 绑定 fraembuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    // framebuffer 不对渲染的内容做存储, 所以这一步是将 framebuffer 绑定到 renderbuffer ( 渲染的结果就存在 renderbuffer )
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _renderbuffer);
}
```

之前的 gen，bin 操作和 renderbuffer 中对应的都是一致的，只是做相应的替换，比如 renderbuffer 改成 framebuffer 即可，这里就不细说，重点看一下 `glFramebufferRenderbuffer`。

之前说过，framebuffer 不对渲染的内容做存储，而 `glFramebufferRenderbuffer` 的作用正是将相关的 buffer（三大 buffer 之一）装配到 framebuffer 上，使得 framebuffer 能索引到对应的渲染内容。它的原型为：

```c
void glFramebufferRenderbuffer (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer)
```

- target：表示当前 framebuffer，必须是 GL_FRAMEBUFFER。
- attachment：指定 renderbuffer 被装配到那个装配点上，其值是 GL_COLOR_ATTACHMENT0，GL_DEPTH_ATTACHMENT，GL_STENCIL_ATTACHMENT 中的一个，分别对应 color，depth 和  stencil 三大 buffer。
- renderbuffertarget：表示当前 renderbuffer，必须是 **GL_RENDERBUFFER**。
- renderbuffer：某个 renderbuffer 对应的 id，表示需要装配的 renderbuffer。

> PS：
>
> 为了安全起见，可以通过 `glCheckFramebufferStatus` 来检查 framebuffer 的创建情况，并根据对应的 log，来排查错误。

```objc
- (BOOL)checkFramebuffer:(NSError *__autoreleasing *)error {
    // 检查 framebuffer 是否创建成功
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSString *errorMessage = nil;
    BOOL result = NO;
    
    switch (status)
    {
        case GL_FRAMEBUFFER_UNSUPPORTED:
            errorMessage = @"framebuffer不支持该格式";
            result = NO;
            break;
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"framebuffer 创建成功");
            result = YES;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            errorMessage = @"Framebuffer不完整 缺失组件";
            result = NO;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            errorMessage = @"Framebuffer 不完整, 附加图片必须要指定大小";
            result = NO;
            break;
        default:
            // 一般是超出GL纹理的最大限制
            errorMessage = @"未知错误 error !!!!";
            result = NO;
            break;
    }
    
    NSLog(@"%@",errorMessage ? errorMessage : @"");
    *error = errorMessage ? [NSError errorWithDomain:@"com.colin.error"
                                                code:status
                                            userInfo:@{@"ErrorMessage" : errorMessage}] : nil;
    
    return result;
}
```



至此，我们需要的环境配置以及相关 buffer 资源都已经准备好了，接下去就是渲染部分了。



## 5. 最简单的渲染，设置背景色

```objc
- (void)render {
    glClearColor(0, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 做完所有绘制操作后，最终呈现到屏幕上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}
```

`glClearColor` 用来设置清屏颜色，它的原型为：

```c
void glClearColor (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
```

`glClear (GLbitfield mask)` 用来指定要用清屏颜色来清除由 mask 指定的 buffer，mask 可以是 GL_COLOR_BUFFER_BIT，GL_DEPTH_BUFFER_BIT 和 GL_STENCIL_BUFFER_BIT 的自由组合。

在这里我们只使用到 color buffer，所以清除的就是 clolor buffer。

`presentRenderbuffer` 是将指定 renderbuffer 呈现在屏幕上。

> PS：
>
> 在此之前，建议使用 `glBindFramebuffer`，`glBindRenderbuffer` 来重新绑定当前 buffer 对象。因为 GL 的所有 API 都是基于最后一次绑定的对象作为作用对象。所以每次在修改 GL 对象时，先绑定一次要修改的对象。有很多错误是因为没有绑定或者绑定了错误的对象导致得到了错误的结果。



## 6. 收工，检验

至此，关于 OpenGL ES 环境搭建的相关准备东西都已就绪，接下去只要按需调用相关方法，即可。

```objc
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setup];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self render];
}

#pragma mark - Setup
- (void)setup {
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    NSError *error;
    NSAssert1([self checkFramebuffer:&error], @"%@",error.userInfo[@"ErrorMessage"]);
}
```



这里不出意外的话，你将会看到开头的那个纯色背景。

你可能注意到了，这个过程我们并没有涉及到所谓的图形渲染管线，如果你试着使用 kEAGLRenderingAPIOpenGLES1 来创建 context，会发现这是完成可以的。



最终的工程可以从[这里](https://github.com/colin1994/OpenGLES/blob/master/Lesson02/OpenGLESDemo_1.zip)下载。有了这个基础，模版，接下去，我们将会围绕渲染管线，实现一系列的炫酷效果，一起期待吧～