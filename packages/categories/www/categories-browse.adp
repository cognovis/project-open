<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context_bar;noquote@</property>

<form action="categories-browse">
  @form_vars;noquote@
  Combine by
  [ <input type=radio name=join value="and"<if @join@ eq "and"> checked</if>>AND
  | <input type=radio name=join value="or"<if @join@ eq "or"> checked</if>>OR ]
  <br>
  <multiple name=trees>
    @trees.tree_name@:
    <select name=category_ids multiple size=5>
    <group column=tree_id>
      <option value="@trees.category_id@"<if @trees.selected_p@ eq 1> selected</if>>@trees.indent;noquote@@trees.category_name@
    </group>
    </select>
  </multiple>
  <input type=submit name=button value="Show">
</form>

To deselect or select multiple categories use the Control-Key on your keyboard.
<p>

<!-- pagination context bar -->
<table cellpadding=4 cellspacing=0 border=0 width="95%">
<tr><td></td><td align=center>@object_count@ objects on @page_count@ pages</td><td></td></tr>
<tr>
  <td align=left width="5%">
    <if @info.previous_group@ not nil>
      <a href="categories-browse?page=@info.previous_group@&@url_vars;noquote@&orderby=@orderby@">&lt;&lt;</a>&nbsp;
    </if>
    <if @info.previous_page@ gt 0>
      <a href="categories-browse?page=@info.previous_page@&@url_vars;noquote@&orderby=@orderby@">&lt;</a>&nbsp;
    </if>
  </td>
  <td align=center>
    <multiple name=pages>
      <if @page@ ne @pages.page@>
        <a href="categories-browse?page=@pages.page@&@url_vars;noquote@&orderby=@orderby@">@pages.page@</a>
      </if>
      <else>
        @page@
      </else>
    </multiple>
  </td>
  <td align=right width="5%">
    <if @info.next_page@ not nil>
      &nbsp;<a href="categories-browse?page=@info.next_page@&@url_vars;noquote@&orderby=@orderby@">&gt;</a>
    </if>
    <if @info.next_group@ not nil>
      &nbsp;<a href="categories-browse?page=@info.next_group@&@url_vars;noquote@&orderby=@orderby@">&gt;&gt;</a>
    </if>
  </td>
</tr>
</table>
@dimension_bar;noquote@
<p>
@items;noquote@
