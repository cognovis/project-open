<master>
<property name="title">#acs-workflow.Initialize_Case#</property>
<property name="context">@context;noquote@</property>

<blockquote><em> 

#acs-workflow.lt_Note_This_page_is_not#

<p>

#acs-workflow.lt_In_real_life_what_wil#

<p>

#acs-workflow.lt_Until_we_make_that_ha#

</em></blockquote>

<form action=init-2 method=get name="init">
@export_vars;noquote@
<table border=0>

<!--
<tr><th>#acs-workflow.Context#</th><td>
    <select name="context_key">
        <multiple name="contexts">
	    <option value="@contexts.context_key@" @contexts.selected@>@contexts.context_name@</option>
	</multiple>
    </select>
</td></tr>
-->

<tr><th>#acs-workflow.Object#</th><td>
    <select name="object_id">
        <multiple name="objects">
	    <option value="@objects.object_id@">@objects.name@</option>
	</multiple>
    </select>
</td></tr>

<tr><td colspan=2 align=center><input type=submit value="Initialize"></td></tr>

</table>

</form>

</master>
