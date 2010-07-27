
	<table cellspacing="1" cellpadding="3">
	  <form action=/intranet-baseline/action method=POST>
	  <%= [export_form_vars return_url] %>
	  <tr class="rowtitle">
	    <th>&nbsp;</td>
	    <th><%= [lang::message::lookup "" intranet-baseline.Baseline_Type "Type"] %></th>
	    <th><%= [lang::message::lookup "" intranet-baseline.Baselines_Baseline "Baseline"] %></th>
	  </tr>
	  <multiple name="baselines">
	    <if @baselines.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><input type=checkbox name=baseline.@baselines.baseline_id@></td>
		<td><a href="@baselines.baselines_edit_url;noquote@">@baselines.baseline_type@</a></td>
		<td><a href="@baselines.baselines_edit_url;noquote@">@baselines.baseline_name@</a></td>
	    </tr>
	  </multiple>

<if @baselines:rowcount@ eq 0>
	<tr class="rowodd">
	    <td colspan=2>
		<%= [lang::message::lookup "" intranet-baseline.No_Baselines_Available "No Baselines Available"] %>
	    </td>
	</tr>
</if>

	<tr class="rowodd">
	    <td colspan=3 align=left>
		<select name=action>
			<option value=del_baselines><%= [lang::message::lookup "" intranet-baseline.Delete_Baselines "Delete Baselines"] %></option>
		</select>	
		<input type=submit value=Apply>
	    </td>
	</tr>

	</form>
	</table>
	
<if @object_write@>
	<ul>
	<li><a href="@new_baseline_url;noquote@"
	><%= [lang::message::lookup "" intranet-baseline.Create_new_Baseline "Create a new Baseline"] %></a>
	</ul>
</if>

