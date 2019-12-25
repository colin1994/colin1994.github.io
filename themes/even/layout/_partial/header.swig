<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<!-- blog_header -->
<ins class="adsbygoogle"
     style="display:inline-block;width:728px;height:90px"
     data-ad-client="ca-pub-9798409996369414"
     data-ad-slot="2942821325"></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>

<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
<!-- blog_header_2 -->
<ins class="adsbygoogle"
     style="display:inline-block;width:728px;height:90px"
     data-ad-client="ca-pub-9798409996369414"
     data-ad-slot="2863177695"></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>

<div class="logo-wrapper">
  <a href="{{ url_for('.') }}" class="logo">{{ config.title }}</a>
</div>

<nav class="site-navbar">
  {% if theme.menu %}
    <ul id="menu" class="menu">
      {% for name, path in theme.menu %}
        <li class="menu-item">
          <a class="menu-item-link" href="{{ url_for(path) }}">
            {% set itemName = __('menu.' + name.toLowerCase()) %}
            {% if itemName.startsWith('menu') %}
              {{ name }}
            {% else %}
              {{ itemName }}
            {% endif %}
          </a>
        </li>
      {% endfor %}
      {% if theme.theme.search %}
        <li class="menu-search">
          <form>
            <i class="iconfont icon-search" id="open-search"></i>
            <input type="text" class="search-input" id="search-input" />
            <i class="iconfont icon-close" id="close-search"></i>
          </form>
        </li>
      {% endif %}
    </ul>
  {% endif %}
</nav>
