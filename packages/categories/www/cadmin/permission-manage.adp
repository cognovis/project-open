<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="change_locale">f</property>

<p>
<if @sw_tree_p@ eq 1>
  This is a site wide category tree<p>
  <if @admin_p@ eq 1>
    <a href="site-wide-status-change?action=0&@url_vars@" class="button">Make it Local</a>
  </if>
</if>
<else>
  This tree is local<p>
  <if @admin_p@ eq 1>
    <a href="site-wide-status-change?action=1&@url_vars@" class="button">Make it Site-Wide</a>
  </if>
</else>  
