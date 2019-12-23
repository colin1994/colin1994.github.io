layout: 'iOS开发小记'

title: Jazzhands, 交互动画就是这么简单

date: 2016-03-16 17:11:00

tags:

- iOS开发
- 教程

------

>  [Jazz Hands](https://github.com/IFTTT/JazzHands)是IFTTT发布的一个基于关键帧的动画框架, 可以用于手势，滚动视图，KVO或者ReactiveCocoa, 十分方便。

but, 到底有多方便呢 ?

看看官方给出的一个demo效果:

![Jazzhandsjazzhands-demo](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Jazzhands/Jazzhandsjazzhands-demo.gif)

<!--more-->

如果 `设计` 要你做出这样一个效果的引导页, 有没有觉得头大 ?

![emoji](http://wanzao2.b0.upaiyun.com/system/pictures/54/original/8.png)

然而, 在 `Jazzhands` 里, 我们需要做的, 就是规划好各个组件需要展示的时机以及对应的位置。中间的衔接动画, 完全交给 `Jazzhands` 去处理。 这样的感觉很爽有没有~ 

![](http://wanzao2.b0.upaiyun.com/system/pictures/789/original/%E9%87%91%E5%A4%A7%E7%88%B79.jpg)



然而, `Jazzhands` 具体为我们做了什么, 它是怎么做的 ?  它适用于哪些场景 ? 下文我们一一分析~



## Jazzhands原理分析

先看一下源工程目录: 

![](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Jazzhands/Jazzhands_1.png)



这一大串看下来, 貌似很复杂, 实则不然。

我们可以简单的归为 三大类 文件来看。

1. `IFTTTAnimation, IFTTTAnimatable, IFTTTBackgroundColorAnimation, IFTTTAlphaAnimation …`  之类的动画类型。
2. `IFTTTAnimator` 动画执行者
3. `IFTTTAnimatedPagingScrollViewController, IFTTTAnimatedScrollViewController` 封装好的控制器类型。



### 动画类型

动画类型, 我们拿最简单的  `alpha` 变化动画来分析。 

`IFTTTAlphaAnimation.m`

``` objc
//
//  IFTTTAlphaAnimation.m
//  JazzHands
//
//  Created by Devin Foley on 9/27/13.
//  Copyright (c) 2013 IFTTT Inc. All rights reserved.
//

#import "IFTTTAlphaAnimation.h"

@implementation IFTTTAlphaAnimation

- (void)addKeyframeForTime:(CGFloat)time alpha:(CGFloat)alpha
{
    if (![self validAlpha:alpha]) return;
    [self addKeyframeForTime:time value:@(alpha)];
}

- (void)addKeyframeForTime:(CGFloat)time alpha:(CGFloat)alpha withEasingFunction:(IFTTTEasingFunction)easingFunction
{
    if (![self validAlpha:alpha]) return;
    [self addKeyframeForTime:time value:@(alpha) withEasingFunction:easingFunction];
}

- (BOOL)validAlpha:(CGFloat)alpha
{
    NSAssert((alpha >= 0.f) && (alpha <= 1.f), @"Alpha values must be between zero and one.");
    if ((alpha < 0.f) || (alpha > 1.f)) return NO;
    return YES;
}

- (void)animate:(CGFloat)time
{
    if (!self.hasKeyframes) return;
    self.view.alpha = (CGFloat)[(NSNumber *)[self valueAtTime:time] floatValue];
}

@end
```

`IFTTTAlphaAnimation` 基础自基类 `IFTTTAnimation` , 重写了对应的 

``` objc
- (void)addKeyframeForTime:(CGFloat)time value:(id<IFTTTInterpolatable>)value;
- (void)addKeyframeForTime:(CGFloat)time value:(id<IFTTTInterpolatable>)value withEasingFunction:(IFTTTEasingFunction)easingFunction;
- (id<IFTTTInterpolatable>)valueAtTime:(CGFloat)time;
```

这里所有的动画, 强调一个 `time - value` 键值对。 这也是关键帧动画的重点。

我们需要做的, 就是维护这样一个 `keyframes (NSMutableArray)` , 里面的元素代表一个个存储了位置的时刻。

以 `alpha` 动画为例, 这里的 `time` 就是对应的关键帧, `value` 就是对应的alpha值。

比如: 

``` objc
    IFTTTAlphaAnimation *alphaAnimation = [IFTTTAlphaAnimation animationWithView:aView];
    [alphaAnimation addKeyframeForTime:100 alpha:0.5];
	.....	
```

这里表示了在 100 帧处, 他对应的 alpha 值是 0.5。

所以, 对于动画的设定, 我们需要做的就是:

1. 选择动画类型。 `IFTTTBackgroundColorAnimation, IFTTTAlphaAnimation …`
2. 添加关键帧。 `    [alphaAnimation addKeyframeForTime:100 alpha:0.5];`
3. 把动画添加到执行者上面。 `[self.animator addAnimation:alphaAnimation];  (这个后面再介绍, 放心, so eazy~)`
4. 抱歉, 没有了~



没错, 就是这么简单。 但是这里有个疑惑, 所谓的关键帧动画, 就是我们提供足够多的关键帧, 然后去逐帧执行。 这是否意味着, 我们需要提供足够多的帧数, 来保证动画的流畅性 ?

如果是这样, 那我们写出来的代码岂不是:

``` objc
    [alphaAnimation addKeyframeForTime:1 alpha:0.1];
    [alphaAnimation addKeyframeForTime:2 alpha:0.15];
    [alphaAnimation addKeyframeForTime:3 alpha:0.2];
    [alphaAnimation addKeyframeForTime:4 alpha:0.25];
........
```

![EMOJI](http://wanzao2.b0.upaiyun.com/system/pictures/599/original/%E6%82%B2%E5%82%AC8.png)



**NO, NO, NO**, 前面我们已经说过了, 这很简单~ 简单意味着, 你只需要提供几个关键点的位置 (起始点, 转折点, 终点), 再设置下它们之间的过渡类型 (Linear, EaseInQuad, EaseInOutQuad…) ，然后, 动画就做完了~ 至于中间各个关键帧的值, 是怎么确定的呢 ？ 放心, `Jazzhands` 已经帮我们做好咯~

``` objc
- (id<IFTTTInterpolatable>)valueAtTime:(CGFloat)time
{
    NSAssert(!self.isEmpty, @"At least one KeyFrame must be set before animation begins.");
    id value;
    NSUInteger indexAfter = [self indexOfKeyframeAfterTime:time];
    if (indexAfter == 0) {
        value = ((IFTTTKeyframe *)self.keyframes[0]).value;
    } else if (indexAfter < self.keyframes.count) {
        IFTTTKeyframe *keyframeBefore = (IFTTTKeyframe *)self.keyframes[indexAfter - 1];
        IFTTTKeyframe *keyframeAfter = (IFTTTKeyframe *)self.keyframes[indexAfter];
        CGFloat progress = [self progressFromTime:keyframeBefore.time toTime:keyframeAfter.time atTime:time withEasingFunction:keyframeBefore.easingFunction];
        value = [keyframeBefore.value interpolateTo:keyframeAfter.value withProgress:progress];
    } else {
        value = ((IFTTTKeyframe *)self.keyframes.lastObject).value;
    }
    return value;
}
```



### 动画执行者

动画执行者, 看着就很牛x, 然而它的实现实际上非常简单， 就几行代码。 它负责 `管理动画对象` 和 `在对应位置执行动画` 。

简单来说, 就这两个方法:

``` objc
- (void)addAnimation:(id<IFTTTAnimatable>)animation
{
    [self.animations addObject:animation];
}

- (void)animate:(CGFloat)time
{
    for (id<IFTTTAnimatable> animation in self.animations) {
        [animation animate:time];
    }
}
```

很简洁有没有。

上文提到了 把动画添加到执行者上面。 `[self.animator addAnimation:alphaAnimation];`

这也就是 `IFTTTAnimator` 的第一个作用, 管理动画对象。animations(NSMutableArray) 里面存储着所有设定的动画。



然后 `[self.animator animate:0];` 就是执行对应的动画了。 这个方法就是在交互的时候, 调用。比如:

``` objc
// 滚动视图
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  [super scrollViewDidScroll:scrollView];
  [self.animator animate:scrollView.contentOffset.x];
}

// 手势
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    [self.animator animate:[recognizer locationOfTouch:0 inView:self.view].x];
}
```



### 控制器类型

`Jazzhands` 帮我们封装好了两种控制器类型 (IFTTTAnimatedPagingScrollViewController, IFTTTAnimatedScrollViewController)。 我们可以直接基于此, 做相应的动画。 这是十分方便的。比如官方的demo就是基于 `IFTTTAnimatedPagingScrollViewController` 来实现的。

它实现了 `scrollViewDidScroll` 等方法。

``` objc
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updatePageOffset];
    [self animateCurrentFrame];
}
```

 并且把 `time` 关键帧的概念, 进一步转化为 `page` 的概念。 也就是说, 你只要指定某个动画, 它在第几个page, 第几个page存在, 各自存在什么位置即可。十分方便~

``` objc
- (void)keepView:(UIView *)view onPage:(CGFloat)page withAttribute:(IFTTTHorizontalPositionAttribute)attribute
{
    [self keepView:view onPage:page withAttribute:attribute offset:0.f];
}
```



## 使用场景 (Demo)

说了这么多, 想必大家对 `Jazzhands` 的实现原理都有一定了解。 那什么时候该用到它呢 ?

我觉得 `引导页` 是不二选择 ~ 毕竟类似的视差动画, 在引导页的应用是最广的。

至于是否需要基于封装好的控制器来实现, 这就要根据具体的需求来定了。

比如官方Demo这样, 所有动画, 在相同的关键帧位置, 有重叠部分。(两个page 可以同时存在), 那基于 `IFTTTAnimatedPagingScrollViewController` 再合适不过了。



不过如果动画有阻尼效果, 也就是当前界面只能存在一个page, 那就建议直接用 `UIViewController` 撸, 然后借助 `手势` , 来实现对应的效果。

比如可以仿照下美图秀秀的引导页, 写个简单demo, 效果如下:

![MTXX_DEMO](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/iOS/Jazzhands/JazzhandsunityResult2.gif)



具体 源码 就不上传了。 相信大家利用 Jazzhands 不难做出类似的效果。(有需要的可以私下交流~)



## 总结

总体来说, 这个开源库还是非常精简，而且思路非常清晰，依然基于Core Animation之上，因为它只是针对于UIKit上去做帧的配置，对帧的封装上更加灵活，但是缺点是实现复杂的动画时，代码量比较大。另外布局约束呢, 都得手撸,,

还是很赞的~ 

![](http://wanzao2.b0.upaiyun.com/system/pictures/801/original/%E9%87%91%E5%A4%A7%E7%88%B721.jpg)

