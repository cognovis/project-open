<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>

<h1>@page_title@</h1>

<if "user" eq @target_object_type@>
	<form action=associated-3 method=GET>
	<%= [export_form_vars tid return_url] %>
	<p>Please select a user to add to the selected tickets.
	</p>
	<table>
	<tr>
	<th>Field</th>
	<th>Value</th>
	<th>Comment</th>
	</tr>
	<tr>
	<td>Target Object</td>
	<td><%= [im_user_select user_id ""] %></td>
	<td>Please choose a user to associated with the tickets.</td>
	</tr>
	<tr>
	<td>Role</td>
	<td><%= [im_biz_object_roles_select role_id $first_ticket_id [im_biz_object_role_full_member]] %></td>
	<td>Please choose a user to associated with the tickets.</td>
	</tr>

	<tr>
	<td></td>
	<td><input type=submit name=submit value="Add User to Tickets"></td>
	<td></td>
	</tr>
	</table>
	</form>
</if>

<if "release_project" eq @target_object_type@>
	<form action=associated-3 method=GET>
	<%= [export_form_vars tid return_url] %>
	<p>Please select a user to add to the selected tickets.
	</p>
	<table>
	<tr>
	<th>Field</th>
	<th>Value</th>
	<th>Comment</th>
	</tr>
	<tr>
	<td>Target Object</td>
	<td><%= [im_project_select -project_type_id [im_project_type_software_release] release_project_id] %></td>
	<td>Please choose a user to associated with the tickets.</td>
	</tr>

	<tr>
	<td></td>
	<td><input type=submit name=submit value="Add User to Tickets"></td>
	<td></td>
	</tr>
	</table>
	</form>
</if>




