<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">confdb</property>

<h1>@page_title@</h1>

<p>
<%= [lang::message::lookup "" intranet-confdb.Associate_Conf_Items_Msg "This page allows you to associated your configuration items with other objects."] %>
</p>
<br>

<form action="/intranet-confdb/associate-2" method=GET>
<%= [export_form_vars cid return_url] %>
<table>
	<tr>
	<th colspan=2><%= [lang::message::lookup "" intranet-confdb.Associate_With "Associate With"] %></th>
	<th>	<%= [lang::message::lookup "" intranet-confdb.Object Object] %></th>
	<th>	<%= [lang::message::lookup "" intranet-confdb.Comment Comment] %></th>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=user></td>
	<td>	<%= [lang::message::lookup "" intranet-confdb.Object_Type_User "User"] %></td>
	<td>	<%= [im_user_select -group_id [im_customer_group_id] user_id ""] %><br>
		<%= [lang::message::lookup "" intranet-confdb.Associate_As "as"] %>&nbsp;
		<%= [im_biz_object_roles_select role_id $first_conf_item_id [im_biz_object_role_full_member]] %>
	</td>
	<td>	<%= [lang::message::lookup "" intranet-confdb.Associate_Msg_User "
	    	Add a new user to the conf_items.<br>
	    	Users can be added either as 'members' or 'administrators'."] %>
	</td>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=project></td>
	<td>	<%= [lang::message::lookup "" intranet-confdb.Object_Type_Project "Project"] %></td>
	<td>	<%= [im_project_select -exclude_subprojects_p 0 project_id] %></td>
	<td>	<%= [lang::message::lookup "" intranet-confdb.Associate_Msg_Project "
		Associated your configuration items with a project that will affect the items."] %>
	</td>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=ticket></td>
	<td>	<%= [lang::message::lookup "" intranet-confdb.Object_Type_Ticket Ticket] %></td>
	<td>	<%= [im_select -translate_p 0 -ad_form_option_list_style_p 1 ticket_id [im_ticket_options]] %></td>
	<td>	<%= [lang::message::lookup "" intranet-confdb.Associate_Msg_Ticket "
	    	Associate your configuration items with a ticket that will affect the items."] %>
	</td>
	</tr>

	<tr>
	<td>&nbsp;</td>
	<td><input type=submit name=submit value="<%= [lang::message::lookup "" intranet-confdb.Associate_Assoc_Action Associate] %>"></td>
	<td>&nbsp;</td>
	</tr>

</table>
</form>