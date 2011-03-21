<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>

<h1>@page_title@</h1>

<p>
<%= [lang::message::lookup "" intranet-helpdesk.Associate_Tickets_Msg "This page allows you to associated your tickets with other objects."] %>
</p>
<br>

<form action=related-objects-associate-2 method=GET>
<%= [export_form_vars tid return_url] %>
<table>
	<tr>
	<th colspan=2><%= [lang::message::lookup "" intranet-helpdesk.Associate_With "Associate With"] %></th>
	<th>	<%= [lang::message::lookup "" intranet-helpdesk.Object Object] %></th>
	<th>	<%= [lang::message::lookup "" intranet-helpdesk.Comment Comment] %></th>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=user></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Object_Type_User "User"] %></td>
	<td>	<%= [im_user_select user_id ""] %><br>
		<%= [lang::message::lookup "" intranet-helpdesk.Associate_As "as"] %>&nbsp;
		<%= [im_biz_object_roles_select role_id $first_ticket_id [im_biz_object_role_full_member]] %>
	</td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Associate_Msg_User "
	    	Add a new user to the tickets.<br>
	    	Users can be added either as 'members' or 'administrators'."] %>
	</td>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=release_project></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Object_Type_Release_Project "Release Project"] %></td>
	<td>	<%= [im_project_select -project_type_id [im_project_type_software_release] release_project_id] %></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Associate_Msg_Release_Project "
	    	Make your tickets 'release items' of a software Release Project. <br>
	    	Release items are those changes to software that are included in a specific release."] %>
	</td>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=conf_item></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Object_Type_Configuration_Item "Configuration Item"] %></td>
	<td>	<%= [im_select -ad_form_option_list_style_p 1 -translate_p 0 conf_item_id [im_conf_item_options]] %></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Associate_Msg_Conf_Item "
	    	Associate your tickets with a configuration item.<br>
	    	A configuration item is a hardware or software item that is affected by your tickets."] %>
	</td>
	</tr>

	<tr>
	<td>	<input type=radio name=target_object_type value=ticket></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Object_Type_Ticket Ticket] %></td>
	<td>	<%= [im_select -ad_form_option_list_style_p 1 -translate_p 0 ticket_id [im_ticket_options -maxlen_name 30]] %></td>
	<td>	<%= [lang::message::lookup "" intranet-helpdesk.Associate_Msg_Ticket "
	    	Associate your tickets with another ticket.<br>
	    	This is used for escalating and for referencing another ticket."] %>
	</td>
	</tr>

	<tr>
	<td>&nbsp;</td>
	<td><input type=submit name=submit value="<%= [lang::message::lookup "" intranet-helpdesk.Associate_Assoc_Action Associate] %>"></td>
	<td>&nbsp;</td>
	</tr>

</table>
</form>