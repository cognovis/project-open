<if @object_read@>

	<table cellspacing="1" cellpadding="3">
	  <form action=/intranet-planning/action method=POST>
	  <%= [export_form_vars object_id return_url] %>
	  <tr class="rowtitle">
	    <td class=rowtitle><%= [lang::message::lookup "" intranet-planning.Item_Type "Object"] %></td>
<% foreach month $months { %>
	    <td class=rowtitle align=center>@month;noquote@</td>
<% } %>
	    <td class=rowtitle><%= [lang::message::lookup "" intranet-planning.Items_Note "Note"] %></td>
	  </tr>
	  <multiple name="items">
	    <if @items.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><a href="@items.item_object_url;noquote@">@items.project_name@</a></td>
<% for {set m 0} {$m < 12} {incr m} { %>
		<td><input type=textbox size=1 name="item_value.$project_id-$m"></td>
<% } %>
		<td><input type=textbox size=10 name="item_note.$project_id"></td>
	    </tr>
	  </multiple>

<if @items:rowcount@ eq 0>
	<tr class="rowodd">
	    <td colspan=2>
		<%= [lang::message::lookup "" intranet-planning.No_Planning_Items_Available "No Planning Items Available"] %>
	    </td>
	</tr>
</if>
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
