<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<h1>@page_title@</h1>

<p>
Importing data...
</p>

<if @tasks_to_delete_p@>

	<h2>@reassign_title@</h2>
	
	<%= [lang::message::lookup "" intranet-ganttproject.Delete_Tasks_Msg "
	<p>The following tasks are not contained in the specified GanttProject '.gan' <br>
	   file anymore, so we are going to delete them.</p>
	<p>However, we could not delete these tasks yet, because they are associated<br>
	   with resources such as timesheet hours, expenses, forum discussions, files <br>etc.</p>
	<p><b>Reassign Resources</b>: Please select the tasks to be deleted and choose<br>
	   where to reassign its resources.</p>
	<p><b>Or</b>: Just <a href='%return_url%'>Return to the previous page</a> 
	   in order to keep these task and their <br>resources.</p>
	"] %>

	<br>
	<listtemplate name="delete_tasks"></listtemplate>
</if>


<if @resources_to_assign_p@>

	<h2>@missing_resources_title@</h2>
	<p>@missing_resources_msg@</p>
	<ul>
	@resource_html;noquote@
	</ul>
</if>


<p>
<%= [lang::message::lookup "" intranet-ganttproject.Successfully_Imported_Project "Successfully imported project."] %>
</p>
<p>
<%= [lang::message::lookup "" intranet-ganttproject.Click_here_to_go_to_your_project "Please click here to go to your project."] %>:
<a href='/intranet/projects/view?project_id=@org_project_id@'>@org_project_name@</a><br>
</p>




