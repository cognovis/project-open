<master>
<property name="title">Edit Arc</property>
<property name="context">@context;noquote@</property>
<property name="focus">arc.guard_description</property>

<blockquote>
    <em>
        A guard is some condition that must be satisfied for a token to travel over that arc.
    </em>
</blockquote>

<form action="arc-edit-2" name="arc">
@export_vars;noquote@

<table>

<tr>
<th align=right>Plaintext description</th>
<td><input type=text name=guard_description size=80 value="@guard_description@"></td>
</tr>

<tr>
<th align=right>Guard condition</th>
<td>
    <select name="guard_callback">
        <multiple name="guard_options">
      	    <option value="@guard_options.value@" @guard_options.selected@>@guard_options.name@</option>
	</multiple>
    </select>
</td>
</tr>

<tr>
<th align=right>Optional argument</th>
<td><input type=text name=guard_custom_arg size=80 value="@guard_custom_arg@">
<br><em>(Depends on the condition chosen above)</em></td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=submit value="Update">
</td>
</tr>

</table>
</form>
</master>