<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="dashboard">home</property>
<property name="focus">@page_focus;noquote@</property>

<h2>@page_title@</h2>

<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
  <td valign=top width='50%'>
<%= [im_component_bay left] %>
  </td>
  <td width=2>&nbsp;</td>
  <td valign=top width='50%'>
<%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0 width='100%'>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

