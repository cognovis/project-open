<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title] %>

<form action='@return_url;noquote@' method=POST>
<%= [export_form_vars return_url ticket_id project_nr project_name ticket_status_id] %>

<table cellspacing=2 cellpadding=2>


<!-- ticket sla -->

<if "" eq @parent_id@>
	<tr class=roweven>
	    <td><%= [lang::message::lookup "" intranet-helpdesk.SLA_long "Service<br>Level<br>Agreement"] %></td>
	    <td>
		<%= [im_select -translate_p 0 parent_id $ticket_sla_options $parent_id] %>
	    </td>
	</tr>
</if>
<else>
	<%= [export_form_vars parent_id] %>
</else>


<!-- ticket type -->

<if "" eq @ticket_type_id@>
		<tr class=rowodd>
		<td><%= [lang::message::lookup "" intranet-helpdesk.Ticket_type "Ticket<br>Type"] %></td>
		<td>
			<table>
			@category_select_html;noquote@
			</table>
		</td>
		</tr>
</if>
<else>
	<%= [export_form_vars ticket_type_id] %>
</else>

<tr class=roweven>
    <td></td>
    <td><input type=submit value='<%= [lang::message::lookup "" intranet-core.Continue "Continue"] %>'></td>
</tr>

</table>
</form>
<%= [im_box_footer] %>

