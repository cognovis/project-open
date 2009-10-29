<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<table cellspacing=2 cellpadding=2>
<form action=assoc-project-2 method=POST>
<%= [export_form_vars conf_item_id return_url] %>
<tr>
    <td><%= [lang::message::lookup "" intranet-confdb.Project "Project"] %></td>
    <td><%= [im_project_select -exclude_subprojects_p 0 project_id ""] %></td>
</tr>
<tr>
    <td>&nbsp;</td>
    <td><input type=submit value="@page_title@"></td>
</tr>
</form>
</table>

