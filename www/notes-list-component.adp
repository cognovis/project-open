	<table cellspacing="1" cellpadding="3">
	  <tr class="rowtitle">
	    <th><%= [lang::message::lookup "" intranet-notes.Notes_Type "Type"] %></th>
	    <th><%= [lang::message::lookup "" intranet-notes.Notes_Note "Note"] %></th>
	  </tr>
	  <multiple name="notes">
	    <if @notes.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td>@notes.note_type@</td>
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


	</table>
	
<if @object_write@>
	<li><a href="@new_note_url;noquote@">
	<%= [lang::message::lookup "" intranet-notes.Create_new_Note "Create a new Note"] %></a>
</if>

