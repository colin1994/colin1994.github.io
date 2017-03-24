layout: "iOS开发小记"

title: 正则表达式

date: 2015-07-11 10:14:52

tags:

- iOS开发
- 正则

---

> 正则表达式，又称正规表示法、常规表示法（英语：Regular Expression，在代码中常简写为regex、regexp或RE），计算机科学的一个概念。正则表达式使用单个字符串来描述、匹配一系列符合某个句法规则的字符串。在很多文本编辑器里，正则表达式通常被用来检索、替换那些符合某个模式的文本。



1. 系统自带的, 如: NSPredicate, rangeOfString：option, NSRegularExpression
2. [RegexKitLite](http://regexkit.sourceforge.net/RegexKitLite/) RegexKitLite 是一个轻量级的 Objective-C 的正则表达式库,支持 Mac OS X 和 iOS,使用 ICU 库开发。

至于`RegexKitLite`, 这里不做介绍。着重介绍系统自带的那几个办法。

> PS: 阅读本文前提是您已经掌握了正则基本语法, 如果对正则还不太了解, 可以参考以下几个链接:

正则表达式学习链接：

1. [55分钟学会正则表达式](http://doslin.com/regular%20expressions/2014/03/11/learn-regular-expressions-in-about-55-minutes.html)
2. [揭开正则表达式的神秘面纱](http://www.regexlab.com/zh/regref.htm)
3. [RegExLib.com(正则表达式库查询)](http://www.regexplib.com/DisplayPatterns.aspx?cattabindex=4&categoryId=5)

*****

<!--more-->



## 1. NSPredicate

> 简述：Cocoa框架中的NSPredicate用于查询，原理和用法都类似于SQL中的where，作用相当于数据库的过滤取。

``` objc
NSPredicate *predicate = [NSPredicate predicateWithFormat:(NSString *), ...];
```

其中, 常见的`Format `有:

(1) 比较运算符: >, <, ==, >=, <=, !=

``` 
例：@"number > 100"
```

(2) 范围运算符: IN, BETWEEN

​	

``` 
例：@"number BETWEEN {1,5}"
   @"address IN {'shanghai','beijing'}"
```

(3) 字符串本身: SELF 

``` 
例：@“SELF == ‘APPLE’"
```

(4) 字符串相关: BEGINSWITH, ENDSWITH, CONTAINS

``` 
例：@"name CONTAINS[cd] 'ang'"  //包含某个字符串
   @"name BEGINSWITH[c] 'sh'"  //以某个字符串开头
   @"name ENDSWITH[d] 'ang'"   //以某个字符串结束

注:[c]不区分大小写
   [d]不区分发音符号即没有重音符号
   [cd]既不区分大小写，也不区分发音符号。
```

(5) 通配符: LIKE

``` 
例：@"name LIKE[cd] '*er*'"    //*代表通配符,Like也接受[cd].
   @"name LIKE[cd] '???er*'"
```

(6) 正则表达式: MATCHES

``` 
例：NSString *regex = @"^A.+e$";   //以A开头，e结尾
  @"name MATCHES %@",regex
```

至于如何使用呢? 下面举几个例子:

(a) 对NSArray进行过滤, 帅选出包含"ang"的项

``` objc
    NSArray *array = [[NSArray alloc]initWithObjects:@"beijing", @"shanghai", @"guangzou", @"wuhan", nil];
    NSString *string = @"ang";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", string];
    NSLog(@"%@", [array filteredArrayUsingPredicate:pred]);

//    打印结果:
//    (
//     shanghai,
//     guangzou
//    )

```

(b) 对NSDate进行筛选

``` objc
    //日期在十天之内:
    NSDate *endDate = [NSDate date];
    NSTimeInterval timeInterval= [endDate timeIntervalSinceReferenceDate];
    timeInterval -=3600*24*10;
    NSDate *beginDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
    //对coredata进行筛选(假设有fetchRequest)
    NSPredicate *predicate_date = [NSPredicate predicateWithFormat:@"date >= %@ AND date <= %@", beginDate,endDate];
    [fetchRequest setPredicate:predicate_date];
```



OK, `NSPredicate `的功能很多, 也很强大。这里暂时就点到此, 感兴趣的可以自己一一试验。 下面举两个例子说明一下如何使用正则。



``` objc
// 判断是否是有效邮箱
- (BOOL)isValidateEmail:(NSString *)email{

    NSString *regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:email];
}

// 判断字符串首字母是否为字母
- (BOOL)isStartedWithWord:(NSString *)aString{

    NSString *regex = @"[A-Za-z]+";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:aString];
}

```

******

## 2. 利用rangeOfString：option：直接查找

``` objc
    NSString *searchText = @"// Do any additional setup after loading the view, typically from a nib.";
    NSRange range = [searchText rangeOfString:@"(?:[^,])*\\." options:NSRegularExpressionSearch];
    if (range.location != NSNotFound) {
        NSLog(@"%@", [searchText substringWithRange:range]);
    }

//    打印结果:
//      typically from a nib.

```

> options中设定NSRegularExpressionSearch就是表示利用正则表达式匹配，会返回第一个匹配结果的位置。



*****

# 3. 使用正则表达式类

详细了解:  [iOS 正则表达式 NSRegularExpression](http://blog.csdn.net/crayondeng/article/details/16991579)

上面那篇文章总结的很不错. 这里简单再举个例子:

``` objc
    NSString *searchText = @"// Do any additional setup after loading the view, typically from a nib.";    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?:[^,])*\\." options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:searchText options:0 range:NSMakeRange(0, [searchText length])];
    if (result) {
        NSLog(@"%@\n", [searchText substringWithRange:result.range]);
    }

//    打印结果:
//      typically from a nib.
```

> 使用系统的正则表达式类（NSRegularExpression）会返回匹配的多个结果。
> 
> 

******

针对以上3种方式, 做一个小小总结

> 第一种匹配需要学习NSPredicate的写法，需要查阅苹果相关技术文档；

>

> 如果只关心第一个匹配的结果，第二种匹配较为简洁；

>

> 如果需要匹配多个结果，同时匹配多次，第三种方式效率会更高。

>



## 常用正则表达式

参考:  [IOS常用正则表达式](http://blog.csdn.net/chaoyuan899/article/details/38583759)





| 表达式                                      | 作用              |
| ---------------------------------------- | --------------- |
| [\u4e00-\u9fa5]                          | 匹配中文字符          |
| [^\x00-\xff]                             | 匹配双字节字符(包括汉字在内) |
| \n\s\*\r                                 | 匹配空白行           |
| <(\S\*?)[^>]\*>.\*?</\1>\                | <.\*? />        |
| ^\s\*\                                   | \s\*$           |
| \w+([-+.]\w+)\*@\w+([-.]\w+)\*\.\w+([-.]\w+)\* | 匹配Email地        |
| [a-zA-z]+://[^\s]*                       | 匹配网址URL         |
| \d{3}-\d{8}\                             | \d{4}-\d{7}     |
| [1-9]\d{5}(?!\d)                         | 匹配中国邮政编码        |
| \d+\.\d+\.\d+\.\d+                       | 匹配ip地址          |