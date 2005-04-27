<master>
<property name="title">Add Place</property>
<property name="context">@context;noquote@</property>
<property name="focus">place.place_name</property>

<form action="place-add-2" name="place">
@export_vars;noquote@

<table>

<tr>
<th align="right">Place name</th>
<td><input type="text" size="80" name="place_name" /></td>
</tr>

<tr>
<th align="right">Sort order</th>
<td><input type="text" size="5" name="sort_order" /></td>
</tr>

<if @special_widget@ not nil>
    <tr>
    <th align="right">Special place</th>
    <td>@special_widget@</td>
    </tr>
</if>

<tr>
<td colspan="2" align="center">
<input type="submit" value="Add">
</td>
</tr>

</table>

</form>

</master>
k