<master>
<property name="title">#acs-workflow.Edit_Arc#</property>
<property name="context">@context;noquote@</property>
<property name="focus">#acs-workflow.arcguard_description#</property>

<blockquote>
    <em>
        #acs-workflow.lt_A_guard_is_some_condi#
    </em>
</blockquote>

<form action="arc-edit-2" name="arc">
@export_vars;noquote@

<table>

<tr>
<th align=right>#acs-workflow.lt_Plaintext_description#</th>
<td><input type=text name=guard_description size=80 value="@guard_description@"></td>
</tr>

<tr>
<th align=right>#acs-workflow.Guard_condition#</th>
<td>
    <select name="guard_callback">
        <multiple name="guard_options">
      	    <option value="@guard_options.value@" @guard_options.selected@>@guard_options.name@</option>
	</multiple>
    </select>
</td>
</tr>

<tr>
<th align=right>#acs-workflow.Optional_argument#</th>
<td><input type=text name=guard_custom_arg size=80 value="@guard_custom_arg@">
<br><em>#acs-workflow.lt_Depends_on_the_condit#</em></td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=submit value="Update">
</td>
</tr>

</table>
</form>
</master>
