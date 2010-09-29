<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>

<h1>@page_title@</h1>

<p>
This page allows you to associated your tickets with other objects:
</p>

<form action=associate-2 method=GET>
<%= [export_form_vars tid return_url] %>
<table>
	<tr>
	<th>&nbsp;</th>
	<th>Associate with</th>
	<th>Comment</th>
	</tr>

	<tr>
	<td><input type=radio name=target_object_type value=user></td>
	<td>User</td>
	<td>
	    Add a new user to the tickets.<br>
	    Users can be added either as "members" or "administrators".
	</td>
	</tr>

	<tr>
	<td><input type=radio name=target_object_type value=release_project></td>
	<td>Release Project</td>
	<td>Make your tickets "release items" of a software Release Project. <br>
	    Release items are those changes to software that are included in a specific release.
	</td>
	</tr>

	<tr>
	<td><input type=radio name=target_object_type value=conf_item></td>
	<td>Configuration Item</td>
	<td>Associate your tickets with a configuration item.<br>
	    A configuration item is a hardware or software item that is affected by your tickets.
	</td>
	</tr>

	<tr>
	<td><input type=radio name=target_object_type value=ticket></td>
	<td>Ticket</td>
	<td>Associate your tickets with another ticket.<br>
	    This is used for escalating and for referencing another ticket.
	</td>
	</tr>

	<tr>
	<td>&nbsp;</td>
	<td><input type=submit name=submit value="Associate"></td>
	<td>&nbsp;</td>
	</tr>

</table>
</form>