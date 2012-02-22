<master>
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_sysconfig</property>


<form action="config-2" method=POST>
<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr class=rowtitle valign=top>
  <td class=rowtitle colspan=2>@page_title@</td>
</tr>
<tr valign=top>
  <td><%= [lang::message::lookup "" intranet-sysconfig.Config Config] %></td>
  <td><textarea name=content cols=80 rows=40></textarea></td>
</tr>
<tr class=rowtitle valign=top>
  <td></td>
  <td><input type=submit></td>
</tr>
</table>
</form>
