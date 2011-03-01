
	<table cellspacing="1" cellpadding="3">
	  <form action="/intranet-cvs-integration/action" method=POST>
	  <%= [export_form_vars return_url] %>
	  <tr class="rowtitle">
	    <th>&nbsp;</td>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_Project "Repository"] %></th>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_Filename "Filename"] %></th>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_Revision "Rev"] %></th>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_Author "Author"] %></th>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_Add_Del "Add/Del"] %></th>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_Note "Note"] %></th>
	    <th><%= [lang::message::lookup "" intranet-cvs_logs.Cvs_Logs_User "User"] %></th>
	  </tr>
	  <multiple name="cvs_logs">
	    <if @cvs_logs.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><input type=checkbox name=cvs_log.@cvs_line_id@></td>
		<td>@cvs_logs.cvs_repo@</td>
		<td>@cvs_logs.cvs_filename@</td>
		<td>@cvs_logs.cvs_revision@</td>
		<td>@cvs_logs.cvs_author@</td>
		<td>+@cvs_logs.cvs_lines_add@/-@cvs_logs.cvs_lines_del@</td>
		<td>@cvs_logs.cvs_note@</td>
		<td>@cvs_logs.cvs_user@</td>
	    </tr>
	  </multiple>

<if @cvs_logs:rowcount@ eq 0>
	<tr class="rowodd">
	    <td colspan=2>
		<%= [lang::message::lookup "" intranet-cvs_logs.No_Cvs_Logs_Available "No Cvs_Logs Available"] %>
	    </td>
	</tr>
</if>

	<tr class="rowodd">
	    <td colspan=2 align=right>
		<select name=action>
			<option value=del_cvs_logs><%= [lang::message::lookup "" intranet-cvs_logs.Delete_Cvs_Logs "Delete Cvs_Logs"] %></option>
		</select>	
		<input type=submit value=Apply>
	    </td>
	</tr>

	</form>
	</table>
	
