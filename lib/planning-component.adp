
<table>
@header;noquote@
@body;noquote@
<if @object_write@>
	<tr class="rowodd">
	    <td colspan=99 align=left>
		<nobr>
		<select name=action>
			<option value=del_items><%= [lang::message::lookup "" intranet-planning.Save "Save"] %></option>
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
