<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>

<h1>@page_title@</h1>

<form action="select-test-2" method=POST>
<%= [export_form_vars url token timestamp user_id] %>
<table cellpadding=2 cellspacing=0 border=0>
<tr class=roweven>
  <td valign=top>URL:</td>
  <td>@url@</td>
</tr>
<tr class=rowodd>
  <td valign=top>User ID:</td>
  <td>@user_id@</td>
</tr>
<tr class=roweven>
  <td valign=top>Timestamp:</td>
  <td>@timestamp@</td>
</tr>
<tr class=rowodd>
  <td valign=top>Token:</td>
  <td>@token@</td>
</tr>

<tr class=roweven>
  <td valign=top>Object Type:</td>
  <td><input type=text name=object_type value="im_project" size=20></td>
</tr>
<tr class=rowodd>
  <td valign=top>Object ID:</td>
  <td><input type=text name=object_id value="9718" size=20></td>
</tr>
<tr>
  <td></td>
  <td><input type=submit></td>
</tr>
</table>
</form>

