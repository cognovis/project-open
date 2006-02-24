<master src="../../intranet-core/www/master">
<property name="title">#intranet-timesheet2.Timesheet#</property>
<property name="context">#intranet-timesheet2.context#</property>
<property name="main_navbar_label">finance</property>



<form method=POST action=new-2>
@export_form_vars;noquote@

<select name=task_id>
@results;noquote@
</select>

<input type=submit value="OK">

</form>
