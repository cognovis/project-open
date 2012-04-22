<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">
</property>
<div class="component">
     <table width="100%">
     <tr>
     <td>
       <div class="component_header_rounded" >
           <div class="component_header">
	         <div class="component_title">#intranet-pmo.Department_Planner#</div>
		       <div class="component_icons"></div>
		           </div>
			     </div>
			     </td>
			     </tr>
			     <tr>
			     <td colspan=2>
<div class = "component_body">
<table width=100%><tr>
<td>      <formtemplate id="department_planner_filter"></formtemplate></td>
<td align="left">
	This planner identifies bottlenecks in the execution of projects.<br>
	It assumes that all project tasks are assigned to a specific department.<br>
	The planner lists the department's capacity (available project days per 
	time interval) and subtracts the required capacity for every project, 
	according to the priority of the project.<br>
	Negative remaining capacity is shown with red background, so the projects
	delivers clear visual clues which projects can be terminated in time, which
	projects don't, and which departments represents the limiting bottlenecks.
</td>
<td>&nbsp;</td>
</table>

<if @ajax_p@ eq 1>
	<include src="../../lib/department-planner-ajax" filter_year="@filter_year@" include_remaining_p="@include_remaining_p@" view_name="@view_name;noquote@" project_status_id="@project_status_id@">
</if><else>
	<include src="../../lib/department-planner" filter_year="@filter_year@" include_remaining_p="@include_remaining_p@" view_name="@view_name;noquote@">
</else>
</div>
</div>