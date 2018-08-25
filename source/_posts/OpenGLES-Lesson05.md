title: GLSL 详解（高级篇）

date: 2017-11-12 18:25:12

tags:

- iOS开发
- OpenGLES
- 图像处理

------



> PS：
> 无特殊说明，文中的 GLSL 均指 OpenGL ES 2.0 的着色语言。

<!--more-->

### 7. 预处理

GLSL 中预处理指令的使用也跟 C 语言的预处理指令相似。以下代码是宏及宏的条件判断：

```c
#define
#undef
#if
#ifdef
#ifndef
#else
#elif
#endif
```

注意与 C 语言中不同，**宏不能带参数定义**。使用 `#if`，`#else` 和 `#elif` 可以用来判断宏是否被定义过。以下是一些预先定义好的宏及它们的描述：

```c
__LINE__ 	// 当前源码中的行号.
__FILE__ 	// OpenGL ES 2.0 中始终为 0.
__VERSION__ // 一个整数,指示当前的 glsl版本. 比如 100 ps: 100 = v1.00
GL_ES 		// 如果当前是在 OPGL ES 环境中运行则 GL_ES 被设置成1,一般用来检查当前环境是不是 OPENGL ES.
```

在着色器编译过程中，**`#error` 指令会触发编译错误并向日志中写入内容。使用 `#pragma` 指令可以向编译器明确与实现相关的指令**。还有一种与 C 语言中不同的预处理指令是 **`#version`**，**它指定了编译着色器的 GLSL 对应版本**，可以在未来更新的版本中据此判断着色器的语言版本，以使用对应的版本来完成编译。这一标记需要写在代码的最开始位置，对于OpenGL ES 2.0 的着色器应将此值设置为 100。如下：

```c
#version 100 // OpenGL ES Shading Language v1.00
```

**实例:**

**Q：1，如何通过判断系统环境，来选择合适的精度：**

```c
#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#endif
```

**Q：2，如何自定义宏：**

```c
#define NUM 100
#if NUM==100
#endif
```

预处理指令中另一个非常重要的是 `#extension`，**用来控制是否启用某些扩展的功能。**当供应商扩展 GLSL 时，会增加新的语言扩展明细，如 `GL_OES_texture_3D` 等。着色器必须告知编译器是否允许使用扩展或以怎样的行为方式出现，这就需要使用 `#extension` 指令来完成，如下：

```c
// Set behavior for an extension
#extension extension_name : behavior
// Set behavior for ALL extensions
#extension all : behavior
```

第一个参数应为扩展的名称或者 “all”，“all” 表示该行为方式适用于所有的扩展。

| 扩展的行为方式 | 描述                                       |
| ------- | ---------------------------------------- |
| require | 指明扩展是必须的，如果该扩展不被支持，预处理器会抛出错误。如果扩展参数为 “all” 则一定会抛出错误。 |
| enable  | 指明扩展是启用的，如果该扩展不被支持，预处理器会发出警告。代码会按照扩展被启用的状态执行，如果扩展参数为“all”则一定会抛出错误。 |
| warn    | 除非是因为该扩展被其它处于启用状态的扩展所需要，否则在使用该扩展时会发出警告。如果扩展参数为 “all” 则无论何时使用扩展都会抛出警告。除此之外，如果扩展不被支持，也会发出警告。 |
| disable | 指明扩展被禁用，如果使用该扩展会抛出错误。如果扩展参数为 “all”（即默认设置），则不允许使用任何扩展。 |

例如，实现不支持 3D 纹理扩展，如果你希望处理器发出警告（此时着色器也会同样被执行，如同实现支持 3D 纹理扩展一样），应当在着色器顶部加入以下代码：

```c
#extension GL_OES_texture_3D : enable
```



### 8. 内置变量

#### 顶点着色器内置变量

顶点着色器中有变量 `gl_Position`，此变量用于写入齐次顶点位置坐标。一个完整的顶点着色器的所有执行命令都应该向此变量写入值。写入的时机可以是着色器执行过程中的任意时间。当被写入之后也同样可以读取此变量的值。在处理顶点之后的图元装配、剪切（clipping）、剔除（culling）等对于图元的固定功能操作中将会使用此值。如果编译器发现 `gl_Position` 未写入或在写入之前有读取行为将会产生一条诊断信息，但并非所有的情况都能发现。如果执行顶点着色器而未写入 `gl_Position`，则 `gl_Position` 的值将是未定义。
顶点着色器中有变量 `gl_PointSize`，此变量用于为顶点着色器写入将要栅格化的点的大小，以像素为单位。
顶点着色器中的这些内置变量固有的声明类型如下：

```c
highp vec4 gl_Position; // should be written to
mediump float gl_PointSize; // may be written to
```

- 这些变量如果未写入或在在写入之前读取，则取到的值是未定义值。
- 如果被写入多次，则在后续步骤中使用的是最后一次写入的值。
- 这些内置变量拥有全局作用域。
- OpenGL ES 中没有内置的 attribute 名称。



#### 片段着色器内置变量

OpenGL ES 渲染管线最后的步骤会对片段着色器的输出进行处理。
如果没有使用过 `discard` 关键字，则片段着色器使用内置变量 `gl_FragColor` 和 `gl_FragData` 来向渲染管线输出数据。

同样，

- 在片段着色器中，并非必须要对 `gl_FragColor` 和 `gl_FragData` 的值进行写入。
- 这些变量可以多次写入值，这样管线中后续步骤使用的是最后一次赋的值。
- 写入的值可以再次读取出，如果在写入之前读取则会得到未定义值。
- 写入的 `gl_FragColor` 值定义了后续固定功能管线中使用的片段的颜色。而变量 `gl_FragData` 是一个数组，写入的数值 `gl_FragData[n]` 指定了后续固定功能管线中对应于数据 `n` 的片段数据。
- 如果着色器为 `gl_FragColor` 静态赋值，则可不必为 `gl_FragData` 赋值，同样如果着色器为 `gl_FragData` 中任意元素静态赋值，则可不必为 `gl_FragColor` 赋值。每个着色器应为二者之一赋值，而非二者同时。（在着色器中，如果某个变量在该着色器完成预处理之后，不受运行时的流程控制语句影响，一定会被写入值，则称之为对该变量的静态赋值）。
- 如果着色器执行了`discard` 关键字，则该片段被丢弃，且 `gl_FragColor` 和 `gl_FragData` 不再相关。
- 片段着色器中有一个只读变量 `gl_FragCoord`，存储了片段的窗口相对坐标 `x`、`y`、`z` 及 `1/w`。该值是在顶点处理阶段之后对图元插值生成片段计算所得。`z` 分量是深度值用来表示片段的深度。
- 片段着色器可以访问内置的只读变量 `gl_FrontFacing` ，如果片段属于正面向前（front-facing）的图元，则该变量的值为 `true`。该变量可以选取顶点着色器计算出的两个颜色之一以模拟两面光照。
- 片段着色器有只读变量 `gl_PointCoord`。`gl_PointCoord` 存储的是当前片段所在点图元的二维坐标。点的范围是 0.0 到 1.0。如果当前的图元不是一个点，那么从 `gl_PointCoord` 读出的值是未定义的。

片段着色器中这些内置变量固有声明类型如下：

```c
mediump vec4 gl_FragCoord;
bool gl_FrontFacing;
mediump vec4 gl_FragColor;
mediump vec4 gl_FragData[gl_MaxDrawBuffers];
mediump vec2 gl_PointCoord;
```

但是它们实际的行为并不像是无存储限定符，而是像上边描述的样子。
这些内置变量拥有全局作用域。



#### uniform 状态变量

GLSL 中还有一种内置的 uniform 状态变量,  `gl_DepthRange` 它用来表明全局深度范围。

结构如下:

```c
struct gl_DepthRangeParameters {
 highp float near; // n
 highp float far; // f
 highp float diff; // f - n
 };
 uniform gl_DepthRangeParameters gl_DepthRange;
```

除了  gl_DepthRange 外的所有 uniform 状态常量都已在 GLSL 1.30 中废弃。



### 9. 内置常量

以下是提供给顶点着色器或片段着色器的内置常量：

```c
//
// Implementation dependent constants. The example values below
// are the minimum values allowed for these maximums.
//

// gl_MaxVertexAttribs 表示在vertex shader(顶点着色器)中可用的最大attributes数.这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 不过最低不能小于 8 个.
const mediump int gl_MaxVertexAttribs = 8;

// gl_MaxVertexUniformVectors 表示在vertex shader(顶点着色器)中可用的最大uniform vectors数. 这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 不过最低不能小于 128 个.
const mediump int gl_MaxVertexUniformVectors = 128;

// gl_MaxVaryingVectors 表示在vertex shader(顶点着色器)中可用的最大varying vectors数. 这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 不过最低不能小于 8 个.
const mediump int gl_MaxVaryingVectors = 8;

// gl_MaxCombinedTextureImageUnits 表示在vertex shader(顶点着色器)中可用的最大纹理单元数(贴图). 这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 甚至可以一个都没有(无法获取顶点纹理)
const mediump int gl_MaxVertexTextureImageUnits = 0;

// gl_MaxCombinedTextureImageUnits 表示在 vertex Shader和fragment Shader总共最多支持多少个纹理单元. 这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 不过最低不能小于 8 个.
const mediump int gl_MaxCombinedTextureImageUnits = 8;

// gl_MaxTextureImageUnits 表示在 fragment Shader(片元着色器)中能访问的最大纹理单元数,这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 不过最低不能小于 8 个.
const mediump int gl_MaxTextureImageUnits = 8;

// gl_MaxFragmentUniformVectors 表示在 fragment Shader(片元着色器)中可用的最大uniform vectors数,这个值的大小取决于 OpenGL ES 在某设备上的具体实现, 不过最低不能小于 16 个.
const mediump int gl_MaxFragmentUniformVectors = 16;

// gl_MaxDrawBuffers 表示可用的drawBuffers数,在OpenGL ES 2.0中这个值为1, 在将来的版本可能会有所变化.
const mediump int gl_MaxDrawBuffers = 1;
```



### 10. 内置函数

在 GLSL 中还有很多内置的函数，如下边的例子是片段着色器中用来计算镜面光的代码。

```c
float nDotL = dot(normal , light);
float rDotV = dot(viewDir, (2.0 * normal) * nDotL – light);
float specular = specularColor * pow(rDotV, specularPower);
```

在上边的代码中，使用内置函数 `dot` 来计算两个矢量的点乘积，使用内置函数 `pow` 来完成标量的幂计算。
在编写着色程序时，GLSL 中有大量的内置函数供使用。绝大多数的内置函数可用于多种着色器，也有一些只适用于一种特定的着色器。这些内置函数大致可分为以下三类：

- 将一些必要的硬件功能显露成方便调用的函数，如访问纹理图。着色器无法用语言模拟这些函数。

- 代表一系列琐碎的操作，虽然这些操作可以由用户直接编写完成，但是这些操作都很常用并且可能会有一些硬件支持。编译器处理表达式于汇编指令的映射是非常困难的事情。

- 代表可获得图形硬件加速的操作，如三角函数属于这一分类。

  ​

很多函数与一些常见的 C 语言库里的同名函数相似，但这些内置函数不仅支持标量输入，还可以支持矢量输入。应用程序中应当尽量使用这些内置函数而不是有相同计算的自定义代码，因为内置函数很可能是最优化的（如可能是硬件直接支持的）。用户函数可以重载内置函数，但不能将其重定义。

在下边的内置函数中，函数的输入参数（及相对应的输出）可以是 float、vec2、vec3 或 vec4，则使用 genType 来作为参数。在实际使用一个函数时，所有的参数类型及返回类型必须是一致的。对于 mat 也相似，其具体类型可以是 mat2、mat3 或 mat4。

参数和返回值的精度限定符不显示。对于纹理函数，返回类型的精度与采样器的类型相匹配。

```c
uniform lowp sampler2D sampler;
highp vec2 coord;
...
lowp vec4 col = texture2D (sampler, coord); // texture2D returns lowp
```

其它内置函数的形式参数的精度限定符则无关。调用这些内置函数将会返回一个匹配输入参数的最高精度级的精度限定符。

按功能大致可以分成 7 类：

#### 角度和三角函数

函数参数是以弧度为单位的角度值。以下内置函数是按逐个分量进行操作，但按单个分量操作进行描述。

| Syntax                              | Description                              |
| ----------------------------------- | ---------------------------------------- |
| genType radians (genType degrees)   | Converts degrees to radians              |
| genType degrees (genType radians)   | Converts radians to degrees              |
| genType sin (genType angle)         | The standard trigonometric sine function. |
| genType cos (genType angle)         | The standard trigonometric cosine function. |
| genType tan (genType angle)         | The standard trigonometric tangent.      |
| genType asin (genType x)            | Arc sine. Returns an angle whose sine is x. The range of values returned by this function is[-π/2,π/2] .Results are undefined if ∣x∣ > 1. |
| genType acos (genType x)            | Arc cosine. Returns an angle whose cosine is x. The range of values returned by this function is [0, π]. Results are undefined if ∣x∣ > 1. |
| genType atan (genType y, genType x) | Arc tangent. Returns an angle whose tangent is y/x. The signs of x and y are used to determine what quadrant the angle is in . The range of values returned by this function is [−π,π]. Results are undefined if x and y are both 0. |
| genType atan (genType y_over_x)     | Arc tangent. Returns an angle whose tangent is y_over_x. The range of values returned by this function is [−π/2,π/2] |



#### 指数函数

以下内置函数是按逐个分量进行操作，但按单个分量操作进行描述。

| Syntax                             | Description                              |
| ---------------------------------- | ---------------------------------------- |
| genType pow (genType x, genType y) | Returns x raised to the y power. Results are undefined if x < 0 .Results are undefined if x = 0 and y <= 0. |
| genType exp (genType x)            | Returns the natural exponentiation of x. |
| genType log (genType x)            | Returns the natural logarithm of x. Results are undefined if x <= 0. |
| genType exp2 (genType x)           | Returns 2 raised to the x power.         |
| genType log2 (genType x)           | Returns the base 2 logarithm of x. Results are undefined if x <= 0. |
| genType sqrt (genType x)           | Returns square root of x. Results are undefined if x < 0. |
| genType inversesqrt (genType x)    | Returns 1/sqrt(x) . Results are undefined if x <= 0. |



#### 通用函数

以下内置函数是按逐个分量进行操作，但按单个分量操作进行描述。

| Syntax                                   | Description                              |
| ---------------------------------------- | ---------------------------------------- |
| genType abs (genType x)                  | Returns x if x >= 0, otherwise it returns –x. |
| genType sign (genType x)                 | Returns 1.0 if x > 0, 0.0 if x = 0, or –1.0 if x < 0 |
| genType floor (genType x)                | Returns a value equal to the nearest integer that is less than or equal to x |
| genType ceil (genType x)                 | Returns a value equal to the nearest integer that is greater than or equal to x |
| genType fract (genType x)                | Returns x – floor (x)                    |
| genType mod (genType x, float y)         | Modulus (modulo). Returns x – y ∗ floor (x/y) |
| genType mod (genType x, genType y)       | Modulus. Returns x – y ∗ floor (x/y)     |
| genType min (genType x, genType y)genType min (genType x, float y) | Returns y if y < x, otherwise it returns x |
| genType max (genType x, genType y) genType max (genType x, float y) | Returns y if x < y, otherwise it returns x. |
| genType clamp (genType x,genType minVal, genType maxVal)genType clamp (genType x, float minVal,float maxVal) | Returns min (max (x, minVal), maxVal) Results are undefined if minVal > maxVal. |
| genType mix (genType x,genType y,genType a)genType mix (genType x,genType y, float a) | Returns the linear blend of x and y: x*(1-a)+y*a |
| genType step (genType edge, genType x)genType step (float edge, genType x) | Returns 0.0 if x < edge, otherwise it returns 1.0 |
| genType smoothstep (genType edge0,genType edge1,genType x)genType smoothstep (float edge0,float edge1,genType x) | Returns 0.0 if x <= edge0 and 1.0 if x >= edge1 and performs smooth Hermite interpolation between 0 and 1 when edge0 < x < edge1. This is useful in cases where you would want a threshold function with a smooth transition. This is equivalent to: `genType t; t = clamp ((x – edge0) / (edge1 – edge0), 0, 1); return t * t * (3 – 2 * t);` Results are undefined if edge0 >= edge1. |



#### 几何函数

以下内置函数是按逐个分量进行操作，但按单个分量操作进行描述。

| Syntax                                   | Description                              |
| ---------------------------------------- | ---------------------------------------- |
| float length (genType x)                 | Returns the length of vector x.          |
| float distance (genType p0, genType p1)  | Returns the distance between p0 and p1.  |
| float dot (genType x, genType y)         | Returns the dot product of x and y.      |
| vec3 cross (vec3 x, vec3 y)              | Returns the cross product of x and y.    |
| genType normalize (genType x)            | Returns a vector in the same direction as x but with a length of 1. |
| genType faceforward(genType N,genType I,genType Nref) | If dot(Nref, I) < 0 return N, otherwise return –N. |
| genType reflect (genType I, genType N)   | For the incident vector I and surface orientation N,returns the reflection direction: I – 2 ∗ dot(N, I) ∗ N. N must already be normalized in order to achieve the desired result. |
| genType refract(genType I, genType N,float eta) | For the incident vector I and surface normal N, and the ratio of indices of refraction eta, return the refraction vector. The result is computed by `k = 1.0 - eta * eta * (1.0 - dot(N, I) * dot(N, I)); if (k < 0.0) return genType(0.0) else return eta * I - (eta * dot(N, I) + sqrt(k)) * N`. The input parameters for the incident vector I and thesurface normal N must already be normalized to get the desired results. |



#### 矩阵函数

| Syntax                            | Description                              |
| --------------------------------- | ---------------------------------------- |
| mat matrixCompMult (mat x, mat y) | Multiply matrix x by matrix y component-wise, i.e.,result[i][j] is the scalar product of x[i][j] and y[i][j]. Note: to get linear algebraic matrix multiplication, usethe multiply operator (*). |



#### 矢量关系函数

矢量之间的比较关系符号（<, <=, >, >=, ==, !=）被定义（或保留）比较产生一个标量的布尔型结果。使用下边的函数可以得到矢量结果。

以下的 ”bvec” 指代 ”bvec2”、”bvec3” 或 ”bvec4” 之一，”ivec” 指代 ”ivec2”、”ivec3” 或 ”ivec4” 之一，”vec” 指代 ”vec2”、”vec3” 或 ”vec4”之一。输入参数和返回值各矢量的大小必须一致。

| Syntax                                   | Description                              |
| ---------------------------------------- | ---------------------------------------- |
| bvec lessThan(vec x, vec y)bvec lessThan(ivec x, ivec y) | Returns the component-wise compare of x < y. |
| bvec lessThanEqual(vec x, vec y)bvec lessThanEqual(ivec x, ivec y) | Returns the component-wise compare of x <= y. |
| bvec greaterThan(vec x, vec y)bvec greaterThan(ivec x, ivec y) | Returns the component-wise compare of x > y. |
| bvec greaterThanEqual(vec x, vec y)bvec greaterThanEqual(ivec x, ivec y) | Returns the component-wise compare of x >= y. |
| bvec equal(vec x, vec y)bvec equal(ivec x, ivec y)bvec equal(bvec x, bvec y)bvec notEqual(vec x, vec y)bvec notEqual(ivec x, ivec y)bvec notEqual(bvec x, bvec y) | Returns the component-wise compare of x == y; Returns the component-wise compare of x != y. |
| bool any(bvec x)                         | Returns true if any component of x is true. |
| bool all(bvec x)                         | Returns true only if all components of x are true. |
| bvec not(bvec x)                         | Returns the component-wise logical complement of x. |

#### 纹理查找函数

纹理查询的最终目的是从 sampler 中提取指定坐标的颜色信息。

顶点着色器和片段着色器中都可以使用纹理查找函数。但是在顶点着色器中不会计算细节层次（level of detail），所以二者的纹理查找函数略有不同。

图像纹理有两种：一种是平面2d纹理，另一种是盒纹理。针对不同的纹理类型有不同访问方法。

- 函数中带有 Cube 字样的是指需要传入盒状纹理。
- 带有 Proj 字样的是指带投影的版本。

以下函数只在顶点着色器中可用：

```c
vec4 texture2DLod(sampler2D sampler, vec2 coord, float lod);
vec4 texture2DProjLod(sampler2D sampler, vec3 coord, float lod);
vec4 texture2DProjLod(sampler2D sampler, vec4 coord, float lod);
vec4 textureCubeLod(samplerCube sampler, vec3 coord, float lod);
```

以下函数只在片段着色器中可用:

```c
vec4 texture2D(sampler2D sampler, vec2 coord, float bias);
vec4 texture2DProj(sampler2D sampler, vec3 coord, float bias);
vec4 texture2DProj(sampler2D sampler, vec4 coord, float bias);
vec4 textureCube(samplerCube sampler, vec3 coord, float bias);
```

在定点着色器和片段着色器中都可用:

```c
vec4 texture2D(sampler2D sampler, vec2 coord);
vec4 texture2DProj(sampler2D sampler, vec3 coord);
vec4 texture2DProj(sampler2D sampler, vec4 coord);
vec4 textureCube(samplerCube sampler, vec3 coord);
```



### 11. 自测

下面是官方的一段实例着色器。如果你可以一眼看懂，说明你已经对 GLSL 语言基本掌握了，那么这篇文章就没有白写了~



**Vertex Shader:**

```c
uniform mat4 mvp_matrix; 	// 透视矩阵 * 视图矩阵 * 模型变换矩阵
uniform mat3 normal_matrix; // 法线变换矩阵(用于物体变换后法线跟着变换)
uniform vec3 ec_light_dir; 	// 光照方向
attribute vec4 a_vertex; 	// 顶点坐标
attribute vec3 a_normal; 	// 顶点法线
attribute vec2 a_texcoord; 	// 纹理坐标
varying float v_diffuse; 	// 法线与入射光的夹角
varying vec2 v_texcoord; 	// 2d纹理坐标

void main(void) {
  // 归一化法线
  vec3 ec_normal = normalize(normal_matrix * a_normal);
  // v_diffuse 是法线与光照的夹角.根据向量点乘法则,当两向量长度为1是 乘积即cosθ值
  v_diffuse = max(dot(ec_light_dir, ec_normal), 0.0);
  v_texcoord = a_texcoord;
  gl_Position = mvp_matrix * a_vertex;
}
```

**Fragment Shader:**

```c
precision mediump float;
uniform sampler2D t_reflectance;
uniform vec4 i_ambient;
varying float v_diffuse;
varying vec2 v_texcoord;

void main (void) {
  vec4 color = texture2D(t_reflectance, v_texcoord);
  // 这里分解开来是 color*vec3(1,1,1)*v_diffuse + color*i_ambient
  // 色*光*夹角cos + 色*环境光
  gl_FragColor = color*(vec4(v_diffuse) + i_ambient);
}
```