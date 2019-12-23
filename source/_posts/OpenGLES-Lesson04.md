title: GLSL 详解（基础篇）

date: 2017-11-11 18:25:12

tags:

- iOS开发
- OpenGLES
- 图像处理

------

上节在绘制三角形的时候，简单讲解了一些着色器，GLSL 的相关概念，可能看的云里雾里的。不要担心，在本节中，我将详细讲解着色语言 GL Shader Language（GLSL）的一些基本的概念。

> PS：
> 无特殊说明，文中的 GLSL 均指 OpenGL ES 2.0 的着色语言。

<!--more-->

## 概览

OpenGL ES 的渲染管线包含有一个可编程的顶点阶段的一个可编程的片段阶段。其余的阶段则有固定的功能，应用程序对其行为的控制非常有限。每个可编程阶段中编译单元的集合组成了一个着色器。在OpenGL ES 2.0 中，每个着色器只支持一个编译单元。着色程序则是一整套编译好并链接在一起的着色器的集合。着色器 shader 的编写需要使用着色语言 GL Shader Language（GLSL），GLSL 的语法与 C 语言很类似。

在上一节中，我们看到了一个非常简单的着色器，如下：

```c
// 顶点着色器 .vsh
attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

void main(void) {
    colorVarying = color;
    gl_Position = position;
}

// 片段着色器 .fsh
varying lowp vec4 colorVarying;

void main(void) {
    gl_FragColor = colorVarying;
}
```

习惯上，我们一般把顶点着色器命名为 **xx.vsh**，片段着色器命名为 **xx.fsh**。当然，你喜欢怎么样就怎么样~

和 C 语言程序对应，用 GLSL 写出的着色器，它同样包括：

- 变量 position
- 变量类型 vec4
- 限定符 attribute
- main 函数
- 基本赋值语句 colorVarying = color
- 内置变量 gl_Position
- ...

这一切，都是那么像...所以，**在掌握 C 语言的基础上，GLSL 的学习成本是很低的**。

学习一门语言，我们无非是从**变量类型，结构体，数组，语句，函数，限定符等**方面展开。下面，我们就照着这个顺序，学习 GLSL。



## 使用 GLSL 构建着色器

### 1. 变量

#### 变量及变量类型

| 变量类别  | 变量类型                      | 描述                   |
| ----- | ------------------------- | -------------------- |
| 空     | void                      | 用于无返回值的函数或空的参数列表     |
| 标量    | float, int, bool          | 浮点型，整型，布尔型的标量数据类型    |
| 浮点型向量 | float, vec2, vec3, vec4   | 包含1，2，3，4个元素的浮点型向量   |
| 整数型向量 | int, ivec2, ivec3, ivec4  | 包含1，2，3，4个元素的整型向量    |
| 布尔型向量 | bool, bvec2, bvec3, bvec4 | 包含1，2，3，4个元素的布尔型向量   |
| 矩阵    | mat2, mat3, mat4          | 尺寸为2x2，3x3，4x4的浮点型矩阵 |
| 纹理句柄  | sampler2D, samplerCube    | 表示2D，立方体纹理的句柄        |

除上述之外，着色器中还可以将它们构成数组或结构体，以实现更复杂的数据类型。

> PS：
>
> GLSL 中没有指针类型。



#### 变量构造器和类型转换

对于变量运算，GLSL 中有非常严格的规则，即**只有类型一致时，变量才能完成赋值或其它对应的操作。**可以通过对应的构造器来实现类型转换。

##### 标量

标量对应 C 语言的基础数据类型，它的构造和 C 语言一致，如下：

```c
float myFloat = 1.0;
bool myBool = true;

myFloat = float(myBool); 	// bool -> float
myBool = bool(myFloat);     // float -> bool
```

##### 向量

当构造向量时，向量构造器中的各参数将会被转换成相同的类型（浮点型、整型或布尔型）。往向量构造器中传递参数有两种形式：

- 如果向量构造器中只提供了一个标量参数，则向量中所有值都会设定为该标量值。
- 如果提供了多个标量值或提供了向量参数，则会从左至右使用提供的参数来给向量赋值，如果使用多个标量来赋值，则需要确保标量的个数要多于向量构造器中的个数。

向量构造器用法如下：

```c
vec4 myVec4 = vec4(1.0); 			// myVec4 = {1.0, 1.0, 1.0, 1.0}
vec3 myVec3 = vec3(1.0, 0.0, 0.5);  // myVec3 = {1.0, 0.0, 0.5}

vec3 temp = vec3(myVec3); 			// temp = myVec3
vec2 myVec2 = vec2(myVec3);         // myVec2 = {myVec3.x, myVec3.y}

myVec4 = vec4(myVec2, temp, 0.0);   // myVec4 = {myVec2.x, myVec2.y , temp, 0.0 }
```

##### 矩阵

矩阵的构造方法则更加灵活，有以下规则：

- 如果对矩阵构造器只提供了一个标量参数，该值会作为矩阵的对角线上的值。例如 `mat4(1.0)` 可以构造一个 4 × 4 的单位矩阵
- 矩阵可以通过多个向量作为参数来构造，例如一个 mat2 可以通过两个 vec2 来构造
- 矩阵可以通过多个标量作为参数来构造，矩阵中每个值对应一个标量，按照从左到右的顺序

除此之外，矩阵的构造方法还可以更灵活，只要有足够的组件来初始化矩阵，其构造器参数可以是标量和向量的组合。在 OpenGL ES 中，矩阵的值会以**列**的顺序来存储。在构造矩阵时，构造器参数会按照列的顺序来填充矩阵，如下：

```c
mat3 myMat3 = mat3(1.0, 0.0, 0.0,  // 第一列
                   0.0, 1.0, 0.0,  // 第二列
                   0.0, 1.0, 1.0); // 第三列
```



#### 向量和矩阵的分量

单独获得向量中的组件有两种方法：即使用 `"."` 符号或使用数组下标方法。依据构成向量的组件个数，向量的组件可以通过 `{x, y, z, w}` ， `{r, g, b, a}` 或 `{s, t, r, q}` 等 swizzle 操作来获取。之所以采用这三种不同的命名方法，是因为向量常常会用来表示数学向量、颜色、纹理坐标等。其中的`x`、`r`、`s` 组件总是表示向量中的第一个元素，如下表：

| 分量访问符     | 符号描述       |
| --------- | ---------- |
| (x,y,z,w) | 与位置相关的分量   |
| (r,g,b,a) | 与颜色相关的分量   |
| (s,t,p,q) | 与纹理坐标相关的分量 |

不同的命名约定是为了方便使用，所以哪怕是描述位置的向量，也是可以通过 `{r, g, b, a}`  来获取。但是在使用向量时不能混用不同的命名约定，即不能使用 `.xgr` 这样的方式，每次只能使用同一种命名约定。当使用 `"."` 操作符时，还可以对向量中的元素重新排序，如下：

```c
vec3 myVec3 = vec3(0.0, 1.0, 2.0); // myVec3 = {0.0, 1.0, 2.0}
vec3 temp;
temp = myVec3.xyz; // temp = {0.0, 1.0, 2.0}
temp = myVec3.xxx; // temp = {0.0, 0.0, 0.0}
temp = myVec3.zyx; // temp = {2.0, 1.0, 0.0}
```

除了使用 `"."` 操作符之外，还可以使用数组下标操作。在使用数组下标操作时，元素 `[0]` 对应的是 `x`，元素 `[1]` 对应 `y`，以此类推。值得注意的是，在 OpenGL ES 2.0 中的某些情况下，数组下标不支持使用非常数的整型表达式（如使用整型变量索引），这是因为对于向量的动态索引操作，某些硬件设备处理起来很困难。在 OpenGL ES 2.0 中仅对 uniform 类型的变量支持这种动态索引。

矩阵可以认为是向量的组合。例如一个 mat2 可以认为是两个 vec2，一个 mat3 可以认为是三个 vec3 等等。对于矩阵来说，可以通过数组下标 `“[]”` 来获取某一列的值，然后获取到的向量又可以继续使用向量的操作方法，如下：

```c
mat4 myMat4 = mat4(1.0); 	// Initialize diagonal to 1.0 (identity)
vec4 col0 = myMat4[0];	    // Get col0 vector out of the matrix 
float m1_1 = myMat4[1][1];  // Get element at [1][1] in matrix 
float m2_2 = myMat4[2].z;   // Get element at [2][2] in matrix
```



#### 向量和矩阵的操作

绝大多数情况下，向量和矩阵的计算是逐分量进行的（component-wise）。当运算符作用于向量或矩阵时，该运算独立地作用于向量或矩阵的每个分量。
以下是一些示例：

```c
vec3 v, u;
float f;
v = u + f;
```

等价于：

```c
v.x = u.x + f;
v.y = u.y + f;
v.z = u.z + f;
```

再如：

```c
vec3 v, u, w;
w = v + u;
```

等价于：

```c
w.x = v.x + u.x;
w.y = v.y + u.y;
w.z = v.z + u.z;
```

对于整型和浮点型的向量和矩阵，绝大多数的计算都同上，但是对于向量乘以矩阵、矩阵乘以向量、矩阵乘以矩阵则是不同的计算规则。这三种计算使用线性代数的乘法规则，并且要求参与计算的运算数值有相匹配的尺寸或阶数。
例如：

```c
vec3 v, u;
mat3 m;
u = v * m;
```

等价于：

```c
u.x = dot(v, m[0]); // m[0] is the left column of m
u.y = dot(v, m[1]); // dot(a,b) is the inner (dot) product of a and b
u.z = dot(v, m[2]);
```

再如：

```c
u = m * v;
```

等价于：

```c
u.x = m[0].x * v.x + m[1].x * v.y + m[2].x * v.z;
u.y = m[0].y * v.x + m[1].y * v.y + m[2].y * v.z;
u.z = m[0].z * v.x + m[1].z * v.y + m[2].z * v.z;
```

再如：

```c
mat m, n, r;
r = m * n;
```

等价于：

```c
r[0].x = m[0].x * n[0].x + m[1].x * n[0].y + m[2].x * n[0].z;
r[1].x = m[0].x * n[1].x + m[1].x * n[1].y + m[2].x * n[1].z;
r[2].x = m[0].x * n[2].x + m[1].x * n[2].y + m[2].x * n[2].z;
r[0].y = m[0].y * n[0].x + m[1].y * n[0].y + m[2].y * n[0].z;
r[1].y = m[0].y * n[1].x + m[1].y * n[1].y + m[2].y * n[1].z;
r[2].y = m[0].y * n[2].x + m[1].y * n[2].y + m[2].y * n[2].z;
r[0].z = m[0].z * n[0].x + m[1].z * n[0].y + m[2].z * n[0].z;
r[1].z = m[0].z * n[1].x + m[1].z * n[1].y + m[2].z * n[1].z;
r[2].z = m[0].z * n[2].x + m[1].z * n[2].y + m[2].z * n[2].z;
```

对于2阶和4阶的向量或矩阵也是相似的规则。



### 2. 结构体

与 C 语言相似，除了基本的数据类型之外，还可以将多个变量聚合到一个结构体中，下边的示例代码演示了在GLSL中如何声明结构体：

```c
struct customStruct
{
	vec4 color;
	vec2 position;
} customVertex;
```

首先，定义会产生一个新的类型叫做 `customStruct` ，及一个名为 `customVertex` 的变量。结构体可以用构造器来初始化，在定义了新的结构体之后，还会定义一个与结构体类型名称相同的构造器。构造器与结构体中的数据类型必须一一对应，如下：

```c
customVertex = customStruct(vec4(0.0, 1.0, 0.0, 0.0), // color
							vec2(0.5, 0.5)); 		  // position
```

结构体的构造器是基于类型的名称，以参数的形式来赋值。获取结构体内元素的方法和C语言中一致：

```c
vec4 color = customVertex.color;
vec4 position = customVertex.position;
```



### 3. 数组

除了结构体外，GLSL 中还支持数组。 语法与 C 语言相似，创建数组的方式如下代码所示：

```c
float floatArray[4];
vec4 vecArray[2];
```

与C语言不同，在GLSL中，关于数组有两点需要注意：

- 除了 uniform 变量之外，数组的索引只允许使用常数整型表达式。
- 在 GLSL 中不能在创建的同时给数组初始化，即数组中的元素需要在定义数组之后逐个初始化，且数组不能使用 const 限定符。



### 4. 语句

#### 运算符

下表展示了 GLSL 中支持的运算符：

| 优先级    | 运算符类别                              | 运算符           | 结合方向   |
| ------ | ---------------------------------- | ------------- | ------ |
| 1 (最高) | 成组操作                               | ()            | 从左向右   |
|        | 数组下标，函数调用与构造函数，访问分量或结构体的字段，后置自增和自减 | [] () . ++ –  | 从左向右   |
| 3      | 前置自增和自减，一元正/负数，一元逻辑非               | ++ – + - !    | 从右向左   |
| 4      | 乘法，除法                              | * /           | 从左向右   |
| 5      | 加法，减法                              | + -           | 从左向右   |
| 6      | 关系比较操作                             | < > <= >=     | 从左向右   |
| 7      | 相等操作                               | == !=         | 从左向右   |
| 8      | 逻辑与                                | &&            | 从左向右   |
| 9      | 逻辑异或                               | ^^            | 从左向右   |
| 10     | 逻辑或                                | \ \|\|        | \ 从左向右 |
| 11     | 三元选择操作（问号表达式）                      | ?:            | 从右向左   |
| 12     | 赋值与算数赋值                            | = += -= *= /= | 从右向左   |
| 13(最低) | 操作符序列                              | ,             | 从左向右   |

绝大多数的运算符与 C 语言中一致。与 C 语言不同的是：GLSL 中对于参与运算的数据类型要求比较严格，即运算符两侧的变量必须有相同的数据类型。对于二目运算符（*，/，+，-），操作数必须为浮点型或整型，除此之外，乘法操作可以放在不同的数据类型之间如浮点型、向量和矩阵等。



**前面矩阵的行数就是结果矩阵的行数，后面矩阵的列数就是结果矩阵的列数。**

比较运算符仅能作用于标量，对于向量的比较，GLSL 中有内置的函数，稍后会介绍。



#### 流程控制语句

流程控制语句与 C 语言非常相似，以下示例代码是 `if-else` 的使用：

```c
if (color.a < 0.25) {
	color *= color.a;
} else {
	color = vec4(0.0);
}
```

判断的内容必须是布尔值或布尔表达式，除了基本的 `if-else` 语句，还可以使用 `for` 循环，在使用 `for` 循环时也有一些约束，如**循环变量的值必须是编译时已知**。如下：

```c
for (int i = 0; i < 3; i++) {
	sum += i;
}
```

在 GLSL 中使用循环时一定要注意：只有一个循环变量，循环变量必须使用简单的语句来增减（如 i++, i–, i+=constant, i-=constant等），循环终止条件也必须是循环变量和常量的简单比较，在循环内部不能改变循环变量的值。

以下代码是 GLSL 中不支持的循环用法的示例：

```c
float myArr[4];
for (int i = 0; i < 3; i++) {
  	// 错误, [ ]中只能为常量或 uniform 变量，不能为整数量变量（如：i，j，k）
	sum += myArr[i]; 
}
...
uniform int loopIter;
// 错误, 循环变量 loopIter 的值必须是编译时已知
for (int i = 0; i < loopIter; i++) {
	sum += i;
}
```





### 5. 函数

GLSL 函数的声明与 C 语言中很相似，无非就是返回值，函数名，参数列表。

GLSL 着色器同样是从 main 函数开始执行。另外， GLSL 也支持自定义函数。当然，如果一个函数在定以前被调用，则需要先声明其原型。

值得注意的一点是，GLSL 中函数不能够递归调用，且必须声明返回值类型（无返回值时声明为void）。如下：

```c
vec4 getPosition(){ 
    vec4 v4 = vec4(0.,0.,0.,1.);
    return v4;
}

void doubleSize(inout float size){
    size= size*2.0  ;
}
void main() {
    float psize= 10.0;
    doubleSize(psize);
    gl_Position = getPosition();
    gl_PointSize = psize;
}
```





### 6. 限定符

#### 存储限定符

在声明变量时，应根据需要使用存储限定符来修饰，类似 C 语言中的说明符。GLSL 中支持的存储限定符见下表：

| 限定符               | 描述                         |
| ----------------- | -------------------------- |
| < none: default > | 局部可读写变量，或者函数的参数            |
| const             | 编译时常量，或只读的函数参数             |
| attribute         | 由应用程序传输给顶点着色器的逐顶点的数据       |
| uniform           | 在图元处理过程中其值保持不变，由应用程序传输给着色器 |
| varying           | 由顶点着色器传输给片段着色器中的插值数据       |



- 本地变量和函数参数只能使用 const 限定符，函数返回值和结构体成员不能使用限定符。
- 数据不能从一个着色器程序传递给下一个阶段的着色器程序，这样会阻止同一个着色器程序在多个顶点或者片段中进行并行计算。
- 不包含任何限定符或者包含 const 限定符的全局变量可以包含初始化器，这种情况下这些变量会在 main() 函数开始之后第一行代码之前被初始化，这些初始化值必须是常量表达式。
- 没有任何限定符的全局变量如果没有在定义时初始化或者在程序中被初始化，则其值在进入 main() 函数之后是未定义的。
- uniform、attribute 和 varying 限定符修饰的变量不能在初始化时被赋值，这些变量的值由 OpenGL ES 计算提供。

##### 默认限定符

如果一个全局变量没有指定限定符，则该变量与应用程序或者其他正在运行的处理单元没有任何联系。不管是全局变量还是本地变量，它们总是在自己的处理单元被分配内存，因此可以对它们执行读和写操作。



##### const 限定符

任意基础类型的变量都可以声明为常量。常量表示这些变量中的值在着色器中不会发生变化，声明常量只需要在声明时加上限定符 const 即可，声明时必须赋初值。

```c
const float zero = 0.0;
const float pi = 3.14159;
const vec4 red = vec4(1.0, 0.0, 0.0, 1.0);
const mat4 identity = mat4(1.0);
```

- 常量声明过的值在代码中不能再改变，这一点和 C 语言或 C++ 一样。
- 结构体成员不能被声明为常量，但是结构体变量可以被声明为常量，并且需要在初始化时使用构造器初始化其值。
- 常量必须被初始化为一个常量表达式。数组或者包含数组的结构体不能被声明为常量（因为数组不能在定义时被初始化）。

##### attribute 限定符

GLSL 中另一种特殊的变量类型是 attribute 变量。attribute 变量只用于顶点着色器中，用来存储顶点着色器中每个顶点的输入（per-vertex inputs）。attribute 通常用来存储位置坐标、法向量、纹理坐标和颜色等。注意 attribute 是用来存储单个顶点的信息。如下是包含位置，色值 attribute 的顶点着色器示例：

```c
// 顶点着色器 .vsh
attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

void main(void) {
    colorVarying = color;
    gl_Position = position;
}
```

着色器中的两个 attribute 变量 `position` 和 `color` 由应用程序加载数值。应用程序会创建一个顶点数组，其中包含了每个顶点的位置坐标和色值信息。可使用的最大 attribute 数量也是有上限的，可以使用  `gl_MaxVertexAttribs` 来获取，也可以使用内置函数 `glGetIntegerv` 来询问 `GL_MAX_VERTEX_ATTRIBS`。OpenGL ES 2.0 实现支持的最少 attribute 个数是8个。

##### uniform 限定符

uniform 是 GLSL 中的一种变量类型限定符，用于存储应用程序通过 GLSL 传递给着色器的只读值。uniform 可以用来存储着色器需要的各种数据，如变换矩阵、光参数和颜色等。传递给着色器的在所有的顶点着色器和片段着色器中保持不变的的任何参数，基本上都应该通过 uniform 来存储。uniform 变量在全局区声明，以下是 uniform 的一些示例：

```c
uniform mat4 viewProjMatrix;
uniform mat4 viewMatrix;
uniform vec3 lightPosition;
```

需要注意的一点是，顶点着色器和片段着色器共享了 uniform 变量的命名空间。对于连接于同一个着色程序对象的顶点和片段着色器，它们共用同一组 uniform 变量，因此，如果在顶点着色器和片段着色器中都声明了 uniform 变量，二者的声明必须一致。当应用程序通过 API 加载了 uniform 变量时，该变量的值在顶点和片段着色器中都能够获取到。

另一点需要注意的是，uniform 变量通常是存储在硬件中的”常量区”，这一区域是专门分配用来存储常量的，但是由于这一区域尺寸非常有限，因此着色程序中可以使用的 uniform 的个数也是有限的。可以通过读取内置变量 `gl_MaxVertexUniformVectors` 和 `gl_MaxFragmentUniformVectors` 来获得，也可以使用 `glGetIntegerv` 查询 `GL_MAX_VERTEX_UNIFORM_VECTORS` 或者 `GL_MAX_FRAGMENT_UNIFORM_VECTORS` 。OpenGL ES 2.0 的实现必须提供至少 128 个顶点 uniform 向量及 16 片段 uniform 向量。

##### varying 限定符

GLSL 中最后一个要说的存储限定符是 varying。varying 存储的是顶点着色器的输出，同时作为片段着色器的输入，通常顶点着色器都会把需要传递给片段着色器的数据存储在一个或多个 varying 变量中。这些变量在片段着色器中需要有相对应的声明且数据类型一致，然后在光栅化过程中进行插值计算。以下是一些 varying 变量的声明：

```c
varying vec2 texCoord;
varying vec4 color;
```

顶点着色器和片段着色器中都会有 varying 变量的声明，由于 varying 是顶点着色器的输出且是片段着色器的输入，所以两处声明必须一致。与 uniform 和 attribute 相同，varying 也有数量的限制，可以使用 `gl_MaxVaryingVectors` 获取或使用 `glGetIntegerv` 查询  `GL_MAX_VARYING_VECTORS` 来获取。OpenGL ES 2.0 实现中的 varying 变量最小支持数为 8。

回顾下最初那个着色器对应的 varying 声明：

```c
// 顶点着色器 .vsh
attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

void main(void) {
    colorVarying = color;
    gl_Position = position;
}

// 片段着色器 .fsh
varying lowp vec4 colorVarying;

void main(void) {
    gl_FragColor = colorVarying;
}
```

#### invariant 限定符

invariant 可以作用于顶点着色器输出的任何一个 varying 变量。

当着色器被编译时，编译器会对其进行优化，这种优化操作可能引起指令重排序（instruction reordering），指令重排序可能引起的结果是当两个着色器进行相同的计算时无法保证得到相同的结果。
例如，在两个顶点着色器中，变量 `gl_Position` 使用相同的表达式赋值，并且当着色程序运行时，在表达式中传入相等的变量值，则两个着色器中 `gl_Position` 的值无法保证相等，这是因为两个着色器是分别单独编译的。这将会引起 multi-pass 算法的几何不一致问题。
通常情况下，不同着色器之间的这种值的差异是允许存在的。如果要避免这种差异，则可以将变量声明为invariant，可以单独指定某个变量或进行全局设置。

使用 invariant 限定符可以使输出的变量保持不变。invariant 限定符可以作用于之前已声明的变量使其具有不变性，也可以在声明变量时直接作为声明的一部分，可参考以下两段示例代码：

```c
varying mediump vec3 Color;
// 使已存在的 color 变量不可变
invariant Color; 
```

或

```c
invariant varying mediump vec3 Color;
```

以上是仅有的使用 invariant 限定符情境。如果在声明时使用 invariant 限定符，则必须保证其放在存储限定符（varying）之前。
只有以下变量可以声明为 invariant：

- 由顶点着色器输出的内置的特殊变量
- 由顶点着色器输出的 varying 变量
- 向片段着色器输入的内置的特殊变量
- 向片段着色器输入的 varying 变量
- 由片段着色器输出的内置的特殊变量

为保证由两个着色器输出的特定变量的不变性，必须遵循以下几点：

- 该输出变量在两个着色器中都被声明为 invariant
- 影响输出变量的所有表达式、流程控制语句的输入值必须相同
- 对于影响输出值的所有纹理函数，纹理格式、纹理元素值和纹理过滤必须一致
- 对输入值的所有操作都必须一致。表达式及插值计算的所有操作必须一致，相同的运算数顺序，相同的结合性，并且按相同顺序计算。插值变量和插值函数的声明，必须有相同类型，相同的显式或隐式的精度precision限定符。影响输出值的所有控制流程必须相同，影响决定控制流程的表达式也必须遵循不变性的规则。

最基本的一点是：所有的 invariant 输出量的上游数据流或控制流必须一致。

初始的默认状态下，所有的输出变量不具备不变性，可以在所有的声明之前使用以下 `pragma` 语句强制所有输出变量 invariant：

```c
#pragma STDGL invariant(all)
```

输出变量的不变性通常会以优化过程的灵活性为代价，所以使用 invariant 会牺牲整体性能。因此慎用以上的全局设置方法，可以将其用作协助 Debug 的一种方法。
另一点需要说明的是，这里的不变性指的是对于同一 GPU 的不变性，并不保证不同 OpenGL ES 实现之间的不变性。



#### 参数限定符

GLSL 提供了一种特殊的限定符用来定义某个变量的值是否可以被函数修改，详见下表：

| 限定符   | 描述                                       |
| ----- | ---------------------------------------- |
| in    | 默认使用的缺省限定符，指明参数传递的是值，并且函数不会修改传入的值（C 语言中值传递） |
| inout | 指明参数传入的是引用，如果在函数中对参数的值进行了修改，当函数结束后参数的值也会修改（C 语言中引用传递） |
| out   | 参数的值不会传入函数，但是在函数内部修改其值，函数结束后其值会被修改       |

使用的方式如下边的代码：

```c
vec4 myFunc(inout float myFloat, // inout parameter
            out vec4 myVec4, 	 // out parameter
            mat4 myMat4); 		 // in parameter (default)
```

以下是一个示例函数，函数定义用来计算基础的漫反射光照：

```c
vec4 diffuse(vec3 normal, vec3 light, vec4 baseColor) {
	return baseColor * dot(normal, light);
}
```



#### 精度限定符

OpenGL ES 与 OpenGL 之间的一个区别就是在 GLSL 中引入了精度限定符。精度限定符可使着色器的编写者明确定义着色器变量计算时使用的精度，变量可以选择被声明为低、中或高精度。精度限定符可告知编译器使其在计算时缩小变量潜在的精度变化范围，当使用低精度时，OpenGL ES 的实现可以更快速和低功耗地运行着色器，效率的提高来自于精度的舍弃，如果精度选择不合理，着色器运行的结果会很失真。

OpenGL ES 对各硬件并未强制要求多种精度的支持。其实现可以使用高精度完成所有的计算并且忽略掉精度限定符，然而某些情况下使用低精度的实现会更有优势，精度限定符可以指定整型或浮点型变量的精度，如 `lowp`，`mediump`，及 `highp`，如下：

| 限定符     | 描述                                       |
| ------- | ---------------------------------------- |
| highp   | 满足顶点着色语言的最低要求。对片段着色语言是可选项                |
| mediump | 满足片段着色语言的最低要求，其对于范围和精度的要求必须不低于lowp并且不高于highp |
| lowp    | 范围和精度可低于mediump，但仍可以表示所有颜色通道的所有颜色值       |

具体用法参考以下示例：

```c
highp vec4 position;
varying lowp vec4 color;
mediump float specularExp;
```

除了精度限定符，还可以指定默认使用的精度。如果某个变量没有使用精度限定符指定使用何种精度，则会使用该变量类型的默认精度。默认精度限定符放在着色器代码起始位置，以下是一些用例：

```c
precision highp float;
precision mediump int;
```

当为 `float` 指定默认精度时，所有基于浮点型的变量都会以此作为默认精度，与此类似，为 `int` 指定默认精度时，所有的基于整型的变量都会以此作为默认精度。在顶点着色器中，如果没有指定默认精度，则 `int` 和 `float` 都使用 `highp`，即顶点着色器中，未使用精度限定符指明精度的变量都默认使用最高精度。在片段着色器中，`float` 并没有默认的精度设置，即片段着色器中必须为 `float` 默认精度或者为每一个 `float` 变量指明精度。OpenGL ES 2.0 并未要求其实现在片段着色器中支持高精度，可用是否定义了宏 `GL_FRAGMENT_PRECISION_HIGH` 来判断是否支持在片段着色器中使用高精度。

在片段着色器中可以使用以下代码：

```c
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
```

这么做可以确保无论实现支持中精度还是高精度都可以完成着色器的编译。注意不同实现中精度的定义及精度的范围都不统一，而是因实现而异的。

精度修饰符声明了底层实现存储这些变量时，必须要使用的最小范围和精度。实现可能会使用比要求更大的范围和精度，但绝对不会比要求少。以下是精度修饰符要求的最低范围和精度：

|         | 浮点数范围          | 浮点数大小范围       | 浮点数精度范围  | 整数范围           |
| ------- | -------------- | ------------- | -------- | -------------- |
| highp   | (-2^62 , 2^62) | (2^-62 ,2^62) | 相对：2^-16 | (-2^16 , 2^16) |
| mediump | (-2^14 , 2^14) | (2^-14 ,2^14) | 相对：2^-10 | (-2^10 , 2^10) |
| lowp    | (-2, 2)        | (2^-8 ,2)     | 绝对：2^-8  | (-2^8 , 2^8)   |

在具体实现中，着色器编译器支持的不同着色器类型和数值形式的实际的范围及精度可用以下函数获取：

```c
void GetShaderPrecisionFormat( enum shadertype, enum precisiontype, int *range, int *precision );
```

其中， `shadertype` 必须是 `VERTEX_SHADER` 或 `FRAGMENT_SHADER`；`precisiontype` 必须是 `LOW_FLOAT`、`MEDIUM_FLOAT`、`HIGH_FLOAT`、`LOW_INT`、`MEDIUM_INT` 或 `HIGH_INT`。

`range ` 是指向含有两个整数的数组的指针，这两个整数将会返回数值的范围。如果用 `min` 和 `max` 来代表对应格式的最小和最大值，则 `range` 中返回的整数值可以定义为：

```c
range[0] = log2(|min|)
range[1] = log2(|max|)
```

`precision ` 是指向一个整数的指针，返回的该整数是对应格式的精度的位数（number of bits）用 `log2` 取对数的值。



**Q：如何确定精度:**

**A：**变量的精度首先是由精度限定符决定的，如果没有精度限定符，则要寻找其右侧表达式中，已经确定精度的变量，一旦找到，那么整个表达式都将在该精度下运行。

如果找到多个，则选择精度较高的那种，如果一个都找不到，则使用默认或更大的精度类型。

```c
uniform highp float h1;
highp float h2 = 2.3 * 4.7; // 运算过程和结果都是 highp
mediump float m;
m = 3.7 * h1 * h2; 			// 运算过程是 highp
h2 = m * h1; 				// 运算过程是 highp
m = h2 – h1; 				// 运算过程是 highp
h2 = m + m; 				// 运算过程和结果都是 mediump
void f(highp float p); 		// 形参 p 是 highp
f(3.3);					    // 传入的 3.3 是 highp
```



**Q：限定符的顺序**

**A：**当需要用到多个限定符的时候要遵循以下顺序: 

- 在一般变量中：invariant > storage > precision （storage：存储，precision：精度）
- 在函数参数中：storage > parameter > precision （parameter：参数）

我们来举例说明:

```c
invariant varying lowp float color; // invariant > storage > precision

void doubleSize(const in lowp float s){ //storage > parameter > precision
    float s1=s;
}
```

