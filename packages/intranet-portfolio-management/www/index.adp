<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">project_programs</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<table class="table_list_page">
       <%= $table_header_html %>
       <%= $table_body_html %>
       <%= $table_continuation_html %>
</table>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width='50%'>
    <%= [im_component_bay left] %>
  </td>

  <td width=2>&nbsp;</td>
  <td valign=top>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>
