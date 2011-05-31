<master>
<property name="title">#acs-workflow.Add_Context#</property>
<property name="context">@context;noquote@</property>
<property name="focus">#acs-workflow.contextcontext_key#</property>

<form method="post" action="context-add-2" name="context">
@export_vars;noquote@
<table>

<tr><th align=right>#acs-workflow.Key#</th><td><input type=text name=context_key></td><tr>

<tr><th align=right>#acs-workflow.Name#</th><td><input type=text name=context_name></td></tr>

<tr><td colspan=2 align=center><input type=submit value="Create"></td></tr>

</table>
</form>

</master>
