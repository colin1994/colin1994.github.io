{# Social Links #}
{% include "./_footer/social.swig" %}

<div class="copyright">
  <span class="power-by">
    {{ __('footer.powered', '<a class="hexo-link" href="https://hexo.io/">Hexo</a>') }}
  </span>
  
  <span class="theme-info">
    {{ __('footer.theme') }} - 
    <a class="theme-link" href="https://github.com/ahonn/hexo-theme-even">Even</a>
  </span>

  <span class="copyright-year">
    {% set current = date(Date.now(), "YYYY") %}
    &copy; 
    {% if theme.since and theme.since != current %} 
      {{ theme.since }} - 
    {% endif %}
    {{ current }}

    <span class="heart">
      <i class="iconfont icon-heart"></i>
    </span>
    <span class="author">{{ config.author }}</span>
  </span>
</div>

<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<!-- blog_footer -->
<ins class="adsbygoogle"
     style="display:block"
     data-ad-client="ca-pub-9798409996369414"
     data-ad-slot="3770470223"
     data-ad-format="auto"
     data-full-width-responsive="true"></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>

<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<!-- blog_footer_2 -->
<ins class="adsbygoogle"
     style="display:inline-block;width:728px;height:90px"
     data-ad-client="ca-pub-9798409996369414"
     data-ad-slot="2273324210"></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>