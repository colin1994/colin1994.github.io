title: 渲染基本图元

date: 2017-04-18 18:25:12

tags:

- iOS开发
- OpenGLES
- 图像处理

------

在[上篇文章](http://colin1994.github.io/2017/04/09/OpenGLES-Lesson02/)中，已经介绍了 OpenGL ES 的基础环境搭建，并且实现了设置背景色功能。

在本文中，我们将会在上文的基础上，渲染基本图元，三角形。在这个过程中，将会详细介绍可编程图形渲染管线是如何工作的。

最终的效果如下：

![2017013028167QQ20170130-174258@2x.png](http://7xkc7a.com1.z0.glb.clouddn.com/2017013028167QQ20170130-174258@2x.png)

<!--more-->

## 0. 初始工程

你可以从[这里](https://github.com/colin1994/OpenGLES/blob/master/Lesson02/OpenGLESDemo_1.zip)下载到初始工程，避免重复实现一些和本节内容不相干的事情。

这是上一节的最终工程，包含了 OpenGL ES 的基础环境搭建。

> PS：
>
> 在之后的步骤里，如果你细心观察对比，你会发现其实它就是围绕图形渲染管线展开的，把之前介绍的内容，用代码的方式实现出来，具体流程可以参照下图回顾：![20170112148420103614414.jpg](http://7xkc7a.com1.z0.glb.clouddn.com/20170112148420103614414.jpg?imageView2/0/format/jpg)



## 1. 顶点数据

开始渲染图形之前，我们必须先给 OpenGL ES 输入一些顶点数据。

为了渲染一个如图所示的三角形，我们需要以数组的形式传递3个 3D 坐标（之前提到过，在 OpenGL 中，任何事物都在 **3D** 空间中）作为图形渲染管线的输入，用来表示一个三角形，这个数组叫做顶点数据（Vertex Data），**顶点数据是一系列顶点的集合**。

在这个简单的例子里，我们一共要指定三个顶点，每个顶点只由一个 3D 位置和一个颜色值组成。

自定义顶点结构体如下：

```objc
typedef struct
{
    float position[4]; // 3D 位置
    float color[4];    // 颜色值
} CustomVertex;
```

> PS：
>
> **Q：**这里的颜色值，用四维向量表示可以理解（RGBA），那么 3D 位置为什么也是四维向量（XYZW）呢（包含4个元素的数组表示的向量）？
>
> **A：** 3D 图形渲染过程中用到了 4x4 的矩阵（4行4列），矩阵乘法要求 nxm * mxp（n行m列 乘 m行p列）才能相乘，注意 m 是相同的，所以 1x4 * 4x4 才能相乘。
>
> The w in vec4(x, y, z, w) is used for clipping, and plays its part while linear algebra transformations are applied to the position.
>
> By default, this should be set to 1.0.
>
> **See here for some more info：**
>
> [http://web.archive.org/web/20160408103910/http://iphonedevelopment.blogspot.com/2010/11/opengl-es-20-for-iOS-chapter-4.html](http://web.archive.org/web/20160408103910/http://iphonedevelopment.blogspot.com/2010/11/opengl-es-20-for-iOS-chapter-4.html)



针对此三角形，我们可以填充对应的数据如下：

```objc
static const CustomVertex vertices[] =
{
    { .position = { -1.0,  1.0, 0, 1 }, .color = { 1, 0, 0, 1 } },
    { .position = { -1.0, -1.0, 0, 1 }, .color = { 0, 1, 0, 1 } },
    { .position = {  1.0, -1.0, 0, 1 }, .color = { 0, 0, 1, 1 } }
};
```

虽然 OpenGL 是在 3D 空间中工作的，但是我们渲染的是一个 2D 三角形，所以我们可以将它顶点的 z 坐标设置为 0.0。这样子的话三角形每一点的**深度**都是一样的，从而使它看上去像是 2D 的。

> PS：
>
> 深度通常可以理解为 z 坐标，它代表一个像素在空间中和你的距离，如果离你远就可能被别的像素遮挡，你就看不到它了，它会被丢弃，以节省资源。

另外，没有特殊操作的情况下，W 轴默认都设置为 1.0。



## 2. 顶点缓存对象（VBO）

定义了上述顶点数据后，我们会把它作为输入发送给图形渲染管线的第一个处理阶段：**顶点着色器**。它会在 GPU 上创建内存用于储存我们的顶点数据。

我们通过顶点缓存对象（Vertex Buffer Objects，**VBO**）管理这个内存，它会在 GPU 内存（通常被称为显存）中储存大量顶点。使用这些缓存对象的好处是我们可以一次性的发送一大批数据到显卡上，而不是每个顶点发送一次。从 CPU 把数据发送到显卡相对较慢，所以只要可能我们都要尝试尽量一次性发送尽可能多的数据。当数据发送至显卡的内存中后，顶点着色器几乎能立即访问顶点，这是个非常快的过程。

创建 VBO 的过程如下：

```objc
GLuint vertexBuffer;
glGenBuffers(1, &vertexBuffer);
glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
```

和之前的其它对象一样，OpenGL ES 对象的创建离不开 Gen，Bin 操作。这里记住 VBO 的缓存类型是 **GL_ARRAY_BUFFER** 即可。

这里着重介绍下 `glBufferData` 函数，它会把之前定义的顶点数据复制到缓存的内存中：

它的原型如下：

```c
void GL_APIENTRY glBufferData (GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage);
```

- target：缓存类型，这里指定 GL_ARRAY_BUFFER。

- size：传输数据的大小（以字节为单位）。直接通过 `sizeof(vertices)` 计算出顶点数据大小即可。

- data：指向实际传输数据。

- usage：指定我们希望显卡如何管理给定的数据。它有三种形式：

  - GL_STATIC_DRAW ：数据不会或几乎不会改变。
  - GL_DYNAMIC_DRAW：数据会被改变很多。
  - GL_STREAM_DRAW ：数据每次绘制时都会改变。

  三角形的位置数据不会改变，每次渲染调用时都保持原样，所以它的使用类型最好是GL_STATIC_DRAW。如果，比如说一个缓存中的数据将频繁被改变，那么使用的类型就是GL_DYNAMIC_DRAW 或 GL_STREAM_DRAW，这样就能确保显卡把数据放在能够高速写入的内存部分。



## 3. 着色器编写

准备好顶点数据后，接下去需要做的就是着色器的编写。关于着色器相关的内容，这节不做过多的解释，下节会针对着色器做详细的介绍。

顶点着色器：

```c
attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

void main(void) {
    colorVarying = color;
    gl_Position = position;
}
```

片段着色器：

```c
varying lowp vec4 colorVarying;

void main(void) {
    gl_FragColor = colorVarying;
}
```

着色器是用着色器语言 GLSL（OpenGL Shading Language）编写的，它看起来很像C语言。

在本节中，我们需要简单的知道这几个概念就好了：

- 顶点着色器每个顶点执行一次，片段着色器每个片段执行一次。
- color，position 是变量，和我们自定义的顶点数据对应。
- colorVarying，顶点着色器和片段着色器中相同的变量，它们是相对应的。
- vec4 是参数类型，GLSL 内置的向量数据类型，这里我们用到的都是四元向量。
- attribute，存储类型限定符，表示链接，链接 OpenGL ES 的每一个顶点数据到顶点着色器（一个一个地）。可以简单理解成输入顶点属性。这里我们将 color，position 传入顶点着色器。
- varying，存储类型限定符，表示链接顶点着色器和片元着色器的内部数据。
- 着色器由 main 函数开始执行，也可以自定义函数，和 C 都是一样的。
- lowp，精度限定符。
- gl_Position，内建变量，顶点着色器的输出值，而且是**必须要赋值**的变量。对 gl_Position 设置的值会成为该顶点着色器的输出。
- gl_FragColor，和 gl_Position 一样，也是内建变量，对应片段的色值。

理解完这几个概念，再看这两个着色器，就是设置对应顶点的位置和色值，再简单不过了。

至此，你可能会有一些疑惑：

**Q：着色器代码以什么形式存在？**

**A：**创建的时候，是通过传入字符串来实现的。所以着色器代码可以通过任何形式存在，最后加载成 NSString 来使用。这里我们在 Xcode 里头，一般是 **New File —> Empty —> xx.vsh / xx.fsh**。然后在对应的文件里面添加代码。这样有个好处就是编辑起来有高亮，更直观。



**Q：为什么传入的三个顶点色值是固定的，但是最终的效果却是渐变色？**

**A：**这是因为 **varying** 变量存在**内插（interpolate）**的过程。

之前提到过，varying 变量的作用是从顶点着色器向片段着色器传值，**但是值不是直接传递，会先进行内插**。

所谓内插，就像补间动画一样。比如想要把一系列散点连成平滑曲线，相邻已知点之间缺少很多点，此时就需要通过内插填补缺少的数据，最终平滑曲线上除已知点之外的所有点都是插值得到的。

同样的，三角形的三个角色值给定后，其它的片段则根据插值计算出来，也就呈现来渐变的效果。



## 4. 编译着色器

我们已经有了着色器源码，但是为了能够让 OpenGL ES 使用它，我们必须在运行时动态编译它的源码。具体代码如下：

```objc
- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        exit(1);
    }
    
    const char* shaderStringUFT8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
  
    GLuint shaderHandle = glCreateShader(shaderType);
    
    glShaderSource(shaderHandle, 1, &shaderStringUFT8, &shaderStringLength);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"glGetShaderiv ShaderIngoLog: %@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}
```



获取 **shaderStringUFT8** 的方式就不说明了，下面主要分析 OpenGL ES 相关 API 的调用情况：

我们首先要做的是创建一个着色器对象，还是用 ID 来引用。所以我们储存这个顶点着色器为 `GLuint`，然后用 `glCreateShader` 创建这个着色器，它的原型如下：

```c
GLuint GL_APIENTRY glCreateShader (GLenum type);
```

- type：着色器类型，可选值有 **GL_VERTEX_SHADER** 和 **GL_FRAGMENT_SHADER**。

下一步我们需要通过 `glShaderSource` 把着色器源码附加到着色器对象上，它的原型如下：

```c
void GL_APIENTRY glShaderSource (GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length);
```

- shader：要编译的着色器对象。
- count：传递的源码字符串数量，这里只有一个。
- string：着色器真正的源码。
- length：着色器源码的长度。

最后，通过 `glCompileShader` 来编译着色器，它的原型如下：

```c
void GL_APIENTRY glCompileShader (GLuint shader);
```

- shader：待编译的着色器对象。

至此，着色器的编译就完成了。

但是，你可能希望知道在调用 `glCompileShader` 后编译是否成功了，如果没成功的话，你还会希望知道错误是什么，这样你才能修正它们。剩余的一部分代码，则是检测编译时是否发生了错误。

首先定义一个变量 **compileSuccess** 来表示是否成功编译。然后用 `glGetShaderiv` 检查是否编译成功。如果编译失败，会用 `glGetShaderInfoLog` 获取错误消息，然后打印它。



最后，在使用上，我们只需调用 `compileShader`，即可获得对应的着色器对象。

```objc
GLuint vertexShader = [self compileShader:@"OpenGLESDemo.vsh" withType:GL_VERTEX_SHADER];
GLuint fragmentShader = [self compileShader:@"OpenGLESDemo.fsh" withType:GL_FRAGMENT_SHADER];
```



## 5. 着色器程序

着色器程序对象（Shader Program Object）是多个着色器合并之后并最终链接完成的版本。如果要使用刚才编译的着色器，我们必须把它们链接为一个着色器程序对象，然后在渲染对象的时候激活这个着色器程序（已激活着色器程序的着色器将在我们发送渲染调用的时候被使用）。

> PS：
>
> 当链接着色器至一个程序的时候，它会把每个着色器的输出链接到下个着色器的输入。当输出和输入不匹配的时候，会得到一个链接错误。

对应的具体代码如下：

```objc
GLuint programHandle = glCreateProgram();
glAttachShader(programHandle, vertexShader);
glAttachShader(programHandle, fragmentShader);
glLinkProgram(programHandle);

GLint linkSuccess;
glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetShaderInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"glGetProgramiv ShaderIngoLog: %@", messageString);
    exit(1);
}

glUseProgram(programHandle);
```

创建一个着色器程序对象很简单，直接通过调用 `glCreateProgram` 函数即可，它会返回新创建着色器程序对象的 ID 引用。然后需要通过 `glAttachShader`，把之前编译好的着色器附加到着色器程序对象上。它的原型如下：

```c
void glAttachShader (GLuint program, GLuint shader);
```

- program：着色器程序对象。
- shader：需要附加的着色器。

然后用 `glLinkProgram` 链接它们，它的原型如下：

```c
void glLinkProgram (GLuint program);
```

- program：着色器程序对象。

就像着色器的编译一样，我们也可以检测链接着色器程序是否失败，并获取相应的日志。与之前不同，我们不会调用 `glGetShaderiv` 和 `glGetShaderInfoLog`，现在使用 `glGetProgramiv` 和 `glGetProgramInfoLog`，不再赘述。

得到着色器程序对象后，我们可以调用 `glUseProgram` 函数，用刚创建的程序对象作为它的参数，以激活这个程序对象。



另外，在把着色器对象链接到着色器程序对象以后，不再需要它们，记得删除着色器对象，如下：

```objc
glDeleteShader(vertexShader);
glDeleteShader(fragmentShader);
```

> PS：
>
> glDeleteShader 删除不再使用的着色器。如果当前着色器链接到一个程序对象上，那么这个着色器将不会被真正的删除，直到此着色器不再链接到任何程序对象。





## 6. 链接顶点属性

现在，我们已经把输入顶点数据发送给了 GPU，并指示了 GPU 如何在顶点和片段着色器中处理它。但是，OpenGL ES 还不知道它该如何解析内存中的顶点数据，以及它该如何将顶点数据链接到顶点着色器的属性上。我们需要告诉 OpenGL ES 怎么做。

我们传入的顶点数据 **vertices**，是这样排布的：

![2017020171966DA004F9B-C0A7-44FE-B747-AA5BEC0ABCF5.png](http://7xkc7a.com1.z0.glb.clouddn.com/2017020171966DA004F9B-C0A7-44FE-B747-AA5BEC0ABCF5.png)



从这个图上，我们可以很清晰知道我们的顶点数据是如何排布，每个字节对应哪些内容，但是 OpenGL ES 本身并不知道，我们应该告诉它如何解析这些顶点数据。

首先，我们需要定义与着色器脚本相对应的变量，为了方便，可以直接使用枚举。

```objc
enum
{
    ATTRIBUTE_POSITION = 0,
    ATTRIBUTE_COLOR,
    NUM_ATTRIBUTES
};
GLint glViewAttributes[NUM_ATTRIBUTES];

...
  
glViewAttributes[ATTRIBUTE_POSITION] = glGetAttribLocation(programHandle, "position");
glViewAttributes[ATTRIBUTE_COLOR]  = glGetAttribLocation(programHandle, "color");

glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]);
glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_COLOR]);
```



> PS：
>
> 通过 NUM_ATTRIBUTES，可以很方便拿到变量的个数。



然后使用 `glGetAttribLocation`，来获得着色器变量的入口，使之绑定起来。它的原型如下：

```c
int GL_APIENTRY glGetAttribLocation (GLuint program, const GLchar* name);
```

- program：着色器程序对象
- name：着色器中对应的变量名

然后，使用 `glEnableVertexAttribArray` ，以顶点属性值作为参数，启用顶点属性（顶点属性默认是禁用的）。



至此，顶点属性的绑定已经完成了，之后只需要在渲染的时候，为对应的顶点属性赋值即可。

下面是对应的渲染代码，其中 **/////////** 包围的是本节新增的：

```objc
- (void)render {
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    glClearColor(0, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //////////////////
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_COLOR], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(sizeof(float) * 4));
    glDrawArrays(GL_TRIANGLES, 0, 3);
    //////////////////
  
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}
```



为了渲染图形，我们需要给定渲染区域（视见区域），即告诉 OpenGL ES 应把渲染之后的图形绘制在窗体的哪个部位。当视见区域是整个窗体时，OpenGL ES 将把渲染结果绘制到整个窗口。

调用 `glViewPort` 函数来决定视见区域，它的原型如下：

```c
void glViewport (GLint x, GLint y, GLsizei width, GLsizei height);
```

- x，y：指定了视见区域的左下角在窗口中的位置。
- width，height：指定了视见区域的宽度和高度。

这里我们直接设置成窗口的大小即可。

准备工作都完成后，有了这些信息我们就可以使用 glVertexAttribPointer 函数告诉 OpenGL ES 该如何解析顶点数据（应用到逐个顶点属性上）了，它的原型如下：

```c
void GL_APIENTRY glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr);
```

- indx：指定要配置的顶点属性。
- size：指定顶点属性的大小（这里不管是位置还是色值，都是四元向量，所以是4）。
- type：指定属性的类型，这里是 **GL_FLOAT** （GLSL中 `vec*` 都是由浮点数值组成的）。
- normalized：指定是否希望数据被标准化（Normalize）。如果设置为 GL_TRUE，所有数据都会被映射到0（对于有符号型 signed 数据是 -1）到 1 之间。我们把它设置为GL_FALSE。
- stride：步长（Stride），它告诉 OpenGL ES 连续的顶点数据组之间的间隔。如上图所示，每个顶点数据大小都是 32 字节（`sizeof(CustomVertex)`），即下组顶点数据数据在一个 `CustomVertex` 之后，所以我们把步长设置为 `sizeof(CustomVertex)`。
- ptr：表示该属性在缓存中起始位置的偏移量（Offset）。如图，位置属性的偏移量是 0，而对于色值属性，它是紧挨着位置属性之后，所以它相对起始位置的偏移量，应该是一个位置属性的大小，即 16（sizeof(float) * 4）。另外，参数类型是 `GLvoid*`，所以需要进行这个奇怪的强制类型转换。

至此，所有东西都已经设置好了：我们使用一个顶点缓存对象将顶点数据初始化至缓存中，建立了一个顶点和一个片段着色器，并告诉了 OpenGL ES 如何把顶点数据链接到顶点着色器的顶点属性上。



最后，要想渲染我们想要的图形，OpenGL ES 提供了 `glDrawArrays` 函数，它使用当前激活的着色器，之前定义的顶点属性配置，以及VBO的顶点数据来渲染图元。它的原型如下：

```c
void GL_APIENTRY glDrawArrays (GLenum mode, GLint first, GLsizei count);
```

- mode：指定渲染的 OpenGL ES 图元的类型。这里渲染的是一个三角形，所以传递 GL_TRIANGLES 给它。
- first：指定了顶点数据的起始索引，这里为 0。
- count：指定顶点个数，这里为 3。

> PS：
>
> mode 的类型还有其他几种，应用于不同的场景，感兴趣的可以了解下～



## 7. 测试，运行

最后，在 setup 中添加如下代码：

```objc
[self compileShaders];
[self setupVBOs];
```



运行，不出意外的话，你将会看到之前的三角形。



最终的工程可以从[这里](https://github.com/colin1994/OpenGLES/blob/master/Lesson03/OpenGLESDemo.zip)下载。下一节，将详细介绍 GLSL，一起期待吧～