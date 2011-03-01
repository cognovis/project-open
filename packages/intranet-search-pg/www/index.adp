<master>
<property name="title">#intranet-search-pg.Search#</property>
<property name="context">#intranet-search-pg.Search#</property>

<center>
<form method=GET action=search>

<table>
<tr>
  <td colspan=1 align=center>
    <%= [im_logo] %>
  </td>
</tr>
<tr>
  <td>
    <input type=text name=q size=40 maxlength=256 value="">
  </td>
  <td>
    <small>
      <a href=advanced_search>#intranet-search-pg.Advanced_Search#</a><br>
    </small>
  </td>
</tr>
<tr>
  <td colspan=1 align=center>
    <input type=submit value="Search" name=t>
  </td>
</tr>
</table>

</form>
</center>
