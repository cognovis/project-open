<master>
<property name="title">#acs-workflow.lt_Place_place_namenoquo#</property>
<property name="context">@context;noquote@</property>
<property name="focus">place.place_name</property>

<form action="place-edit-2" name="place">
@export_vars;noquote@

<table>

<tr>
<th align="right">#acs-workflow.Place_name#</th>
<td><input type="text" name="place_name" size="80" value="@place_name@" /></td>
</tr>

<tr>
<th align="right">#acs-workflow.Sort_order#</th>
<td><input type="text" name="sort_order" size="5" value="@sort_order@" /></td>
</tr>

<tr>
<td colspan="2" align="center">
<input type="submit" value="Update" />
</td>
</tr>

</table>

</master>

