layout: 'Hexo折腾'

title: 为Hexo博客添加版权说明和打赏功能

date: 2016-06-02 20:06:06

tags:

- Hexo
- 教程

------

> 今天为博客配置了自动添加版权说明和打赏功能，加深了对Hexo框架的理解，做个小小的总结。当然，如果喜欢也可以试试为自己的博客添加上。

效果图：

![tailResult](https://raw.githubusercontent.com/colin1994/colin1994.github.io/feature/hexo/BlogResources/Other/tailResult.png)



<!--more-->



## 版权说明

具体实现步骤如下：

1. 在博客根目录下（和 source 同级），新建一个名为 `scripts` 的文件夹。
2. 在 `scripts` 文件夹内, 新建一个 `AddTail.js` 脚本文件，脚本具体内容详见下文。
3. 在博客根目录下，新建一个 `tail.md` 文件，里面写想要展示的版本说明内容。示例如下文所示。

 `AddTail.js` 脚本文件：

```javascript
// Filename: AddTail.js
// Author: Colin
// Date: 2016/06/02
// Based on the script by KUANG Qi: http://kuangqi.me/tricks/append-a-copyright-info-after-every-post/

// Add a tail to every post from tail.md
// Great for adding copyright info

var fs = require('fs');

hexo.extend.filter.register('before_post_render', function(data){
	if(data.copyright == false) return data;
	
	// Add seperate line
	data.content += '\n___\n';
	
	// Try to read tail.md
	try {
		var file_content = fs.readFileSync('tail.md');
		if(file_content && data.content.length > 50) 
		{
			data.content += file_content;
		}
	} catch (err) {
		if (err.code !== 'ENOENT') throw err;
		
		// No process for ENOENT error
	}

  	// 添加具体文章链接, 不需要去掉即可
	var permalink = '\n本文链接：' + data.permalink;
	data.content += permalink;
  
	return data;
});
```



`tail.md` 文件示例：

[![知识共享许可协议](http://i.creativecommons.org/l/by/2.5/cn/88x31.png)](http://creativecommons.org/licenses/by/2.5/cn/)本作品采用[知识共享署名 2.5 中国大陆许可协议](http://creativecommons.org/licenses/by/2.5/cn/)进行许可，欢迎转载，但转载请注明来自[Colin's Nest](http://colin1994.github.io/)，并保持转载后文章内容的完整。本人保留所有版权相关权利。



如此，`hero clean` 后重新 `hexo generate` 即可。



## 打赏功能

打赏功能的实现其实是直接嵌入到博客主题中的，所以修改了原先 `clone` 下来的源码。当然，你可以发个 `PR` ，或者直接选择支持打赏功能的主题。我这里选择的 [Yilia](https://github.com/litten/hexo-theme-yilia) 主题并不支持这个功能，所以只好自己实现一下。（虽然知道大概并没有什么用...）



### 目标

既然是嵌入到博客主题中，那么当然希望是可定制的。例如主题本身给我们提供的配置一样。大致目标如下：

我们只需要在 `_config.yml` 中加入如下语句, 即可完成打赏的配置

```xml
#打赏
donate:
  enable: true
  text: Enjoy it ? Donate me !  欣赏此文？求鼓励，求支持！
  wechat: http://7xkc7a.com1.z0.glb.clouddn.com/wechatImage.png
  alipay: http://7xkc7a.com1.z0.glb.clouddn.com/alipayImage.png
```

- `enable` 参数设置是否开启打赏功能。( `true` or ` false` )
- `text` 参数配置需要显示的内容
- `wechat` 参数设置微信支付二维码 URL
- `alipay` 参数设置支付宝支付二维码 URL

### 实现步骤

编辑主题内的 `article.ejs` 文件，比如我这里位于 `themes/yilia/layout/_partial/article.ejs` 。

在 `<div class="article-content">...</div>` 的下面，`<%- partial('footer') %>` 的上面插入如下HTML代码：

```html
<% if (theme.donate) { %>
  <!-- css -->
  <style type="text/css">
      .center {
          text-align: center;
      }
      .hidden {
          display: none;
      }
    .donate_bar a.btn_donate{
      display: inline-block;
      width: 82px;
      height: 82px;
      background: url("http://7xsl28.com1.z0.glb.clouddn.com/btn_reward.gif") no-repeat;
      _background: url("http://7xsl28.com1.z0.glb.clouddn.com/btn_reward.gif") no-repeat;

      <!-- http://img.t.sinajs.cn/t5/style/images/apps_PRF/e_media/btn_reward.gif
           因为本 hexo 生成的博客所用的 theme 的 a:hover 带动画效果，
         为了在让打赏按钮显示效果正常 而 添加了以下几行 css，
         嵌入其它博客时不一定要它们。 -->
      -webkit-transition: background 0s;
      -moz-transition: background 0s;
      -o-transition: background 0s;
      -ms-transition: background 0s;
      transition: background 0s;
      <!-- /让打赏按钮的效果显示正常 而 添加的几行 css 到此结束 -->
    }

    .donate_bar a.btn_donate:hover{ background-position: 0px -82px;}
    .donate_bar .donate_txt {
      display: block;
      color: #9d9d9d;
      font: 14px/2 "Microsoft Yahei";
    }
    .bold{ font-weight: bold; }
  </style>
  <!-- /css -->

    <!-- Donate Module -->
    <div id="donate_module">

  <!-- btn_donate & tips -->
  <div id="donate_board" class="donate_bar center">
      <br>
      ------------------------------------------------------------------------------------------------------------------------------
      <br>
    <a id="btn_donate" class="btn_donate" target="_self" href="javascript:;" title="Donate 打赏"></a>
    <span class="donate_txt">
      <%= theme.donate.text %>
    </span>
      
    
  </div>
  <!-- /btn_donate & tips -->

  <!-- donate guide -->
    
  <div id="donate_guide" class="donate_bar center hidden">
        <br>
      ------------------------------------------------------------------------------------------------------------------------------
      <br>

    <a href="<%= theme.donate.wechat %>" title="用微信扫一扫哦~" class="fancybox" rel="article0">
      <img src="<%= theme.donate.wechat %>" title="微信打赏 Colin" height="190px" width="auto"/>
    </a>
        
        &nbsp;&nbsp;

    <a href="<%= theme.donate.alipay %>" title="用支付宝扫一扫即可~" class="fancybox" rel="article0">
      <img src="<%= theme.donate.alipay %>" title="支付宝打赏 Colin" height="190px" width="auto"/>
    </a>

    <span class="donate_txt">
      <%= theme.donate.text %>
    </span>

  </div>
  <!-- /donate guide -->

  <!-- donate script -->
  <script type="text/javascript">
    document.getElementById('btn_donate').onclick = function() {
      $('#donate_board').addClass('hidden');
      $('#donate_guide').removeClass('hidden');
    }

    function donate_on_web(){
      $('#donate').submit();
        }

    var original_window_onload = window.onload;
        window.onload = function () {
            if (original_window_onload) {
                original_window_onload();
            }
            document.getElementById('donate_board_wdg').className = 'hidden';
    }
  </script>
  <!-- /donate script -->
</div>
<!-- /Donate Module -->
   <% } %>
```

这里通过判断是否显示打赏模块，执行相应的操作。点击打赏按钮，显示相应的二维码。

这里还有个问题，在文章列表中，有时候也会显示打赏功能，这显然不是我们想要的。需要做的就是判断当前的的页面是详情页面还是介绍页面，比如我这里，把上面的代码放在如下判断语句中：

```html
<% if (!post.excerpt || !index){ %>
  
  <!-- /上述代码 -->
<% }%>
```



如此，一个简单的打赏功能就实现了。



当然，你如果觉得麻烦，但是又想实现打赏功能，那么可以尝试下 [云打赏](http://www.dashangcloud.com)，据说一行代码集成打赏功能。

Have fun ~     ：）



## 参考链接

[￼为Hexo博客文章自动添加版权信息](https://tono.tk/2016/03/26/Add_copyright_for_hexo/)

[实现网站的支付宝打赏功能](http://icehe.me/web/donate/)

