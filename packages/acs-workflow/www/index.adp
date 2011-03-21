<master>
<property name="title">Work List</property>
<property name="context">@context;noquote@</property>

<if @admin_p@ eq 1>
  (<a href="admin/">Administer</a>)<p>
</if>


<h3>Tasks You Are Currently Working On</h3>

<include src="task-list" type="own">


<h3>Tasks To Be Done</h3>

<include src="task-list">

<if @admin_p@ eq 1>
  <h3>Unassigned Tasks</h3>
  <include src="task-list" type="unassigned">
</if>

</master>
