<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="change_locale">f</property>

<p>
<if @sw_tree_p@ eq 1>
  #categories.lt_This_is_a_site_wide_c#<p>
  <if @admin_p@ eq 1>
    <a href="site-wide-status-change?action=0&@url_vars@" class="button">#categories.Make_it_Local#</a>
  </if>
</if>
<else>
  #categories.This_tree_is_local#<p>
  <if @admin_p@ eq 1>
    <a href="site-wide-status-change?action=1&@url_vars@" class="button">#categories.Make_it_Site-Wide#</a>
  </if>
</else>  

