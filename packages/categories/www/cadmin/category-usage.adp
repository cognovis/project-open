<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="locale">@locale;noquote@</property>

<!-- pagination context bar -->
<table cellpadding=4 cellspacing=0 border=0 width="95%">
<tr><td></td><td align=center>@object_count@ objects on @page_count@ pages</td><td></td></tr>
<tr>
  <td align=left width="5%">
    <if @info.previous_group@ not nil>
      <a href="category-usage?page=@info.previous_group@&@url_vars;noquote@&orderby=@orderby@">&lt;&lt;</a>&nbsp;
    </if>
    <if @info.previous_page@ gt 0>
      <a href="category-usage?page=@info.previous_page@&@url_vars;noquote@&orderby=@orderby@">&lt;</a>&nbsp;
    </if>
  </td>
  <td align=center>
    <multiple name=pages>
      <if @page@ ne @pages.page@>
        <a href="category-usage?page=@pages.page@&@url_vars;noquote@&orderby=@orderby@">@pages.page@</a>
      </if>
      <else>
        @page@
      </else>
    </multiple>
  </td>
  <td align=right width="5%">
    <if @info.next_page@ not nil>
      &nbsp;<a href="category-usage?page=@info.next_page@&@url_vars;noquote@&orderby=@orderby@">&gt;</a>
    </if>
    <if @info.next_group@ not nil>
      &nbsp;<a href="category-usage?page=@info.next_group@&@url_vars;noquote@&orderby=@orderby@">&gt;&gt;</a>
    </if>
  </td>
</tr>
</table>
<p>
@items;noquote@
