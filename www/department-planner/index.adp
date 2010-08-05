<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">projects</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>


<table width=100%><tr>
<td width=50%></td>
<td>
	<b>Department Planner</b>:<br>
	This planner identifies bottlenecks in the execution of projects.<br>
	It assumes that all project tasks are assigned to a specific department.<br>
	The planner then lists the department's capacity and subtracts the required
	capacity for every project, according to the priority of the project.<br>
	Negative remaining capacity is shown with red background, so the projects
	delivers clear visual clues which projects can be terminated in time, which
	projects don't, and which departments represents the limiting bottlenecks.
</td>
</table>

<listtemplate name="department_planner"></listtemplate>


<if "" ne @error_html@>
<br>
<h1>Errors</h1>
<ul>
@error_html;noquote@
</ul>
</if>

