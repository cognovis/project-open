<master>
<property name="title">Close Project</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">projects</property>

Schliessen des Projekts nicht m&ouml;glich. Folgende Unterprojekte sind noch nicht geschlossen:<br>
<br>
@projects_not_closed_html;noquote@
<br>
<br>

<form action="workflow-close-project.tcl" method="POST">
<input type='hidden' name='project_id' value='@project_id_bak@'>
Projekte jetzt automatisch schliessen:
<br> 
	<input type="radio" name="close_projects_p" value="1" checked> Yes  
	<input type="radio" name="close_projects_p" value="0"> No  
<br><br><input type="submit" value="Senden">
</form>


