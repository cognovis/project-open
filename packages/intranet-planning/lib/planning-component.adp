
<form action="/intranet-planning/action" method=POST>
<%= [export_form_vars object_id return_url] %>
<table>
@header;noquote@
@body;noquote@
<if @object_write@>
	<tr class="rowodd">
	    <td colspan=99 align=left>
		<nobr>
		<select name=action>
			<option value=save><%= [lang::message::lookup "" intranet-planning.Save "Save"] %></option>
			<option value=create_quote_from_planning_data><%= [lang::message::lookup "" intranet-planning.Create_quote_from_date "Create quote from planning data"] %></option>
		</select>	
		<input type=submit value="<%= [lang::message::lookup "" intranet-planning.Apply "Apply"] %>">
		</nobr>
	    </td>
	</tr>
</if>
	</form>
	</table>
</if>
</table>
</form>
