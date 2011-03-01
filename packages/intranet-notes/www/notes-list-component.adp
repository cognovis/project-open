
	<table cellspacing="1" cellpadding="3">
	  <form action=/intranet-notes/action method=POST>
	  <%= [export_form_vars return_url] %>
	  <tr class="rowtitle">
	    <th>&nbsp;</td>
	    <th><%= [lang::message::lookup "" intranet-notes.Note_Type "Type"] %></th>
	    <th><%= [lang::message::lookup "" intranet-notes.Notes_Note "Note"] %></th>
	  </tr>
	  <multiple name="notes">
	    <if @notes.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><input type=checkbox name=note.@notes.note_id@></td>
		<td><a href="@notes.notes_edit_url;noquote@">@notes.note_type@</a></td>
		<td>@notes.note_formatted;noquote@</td>
	    </tr>
	  </multiple>

<if @notes:rowcount@ eq 0>
	<tr class="rowodd">
	    <td colspan=2>
		<%= [lang::message::lookup "" intranet-notes.No_Notes_Available "No Notes Available"] %>
	    </td>
	</tr>
</if>

	<tr class="rowodd">
	    <td colspan=3 align=left>
		<select name=action>
			<option value=del_notes><%= [lang::message::lookup "" intranet-notes.Delete_Notes "Delete Notes"] %></option>
		</select>	
		<input type=submit value=Apply>
	    </td>
	</tr>

	</form>
	</table>
	
<if @object_write@>
	<ul>
	<li><a href="@new_note_url;noquote@"
	><%= [lang::message::lookup "" intranet-notes.Create_new_Note "Create a new Note"] %></a>
	</ul>
</if>

