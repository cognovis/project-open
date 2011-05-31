<master>
<property name="title">#acs-workflow.Work_List#</property>
<property name="context">@context;noquote@</property>

<if @admin_p@ eq 1>
  (<a href="admin/">#acs-workflow.Administer#</a>)<p>
</if>


<h3>#acs-workflow.lt_Tasks_You_Are_Current#</h3>

<include src="task-list" type="own">


<h3>#acs-workflow.Tasks_To_Be_Done#</h3>

<include src="task-list">

<if @admin_p@ eq 1>
  <h3>#acs-workflow.Unassigned_Tasks#</h3>
  <include src="task-list" type="unassigned">
</if>

</master>

