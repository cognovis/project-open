<master>
<property name="title">Simple Process Wizard Step 4: Assignments for @workflow_name;noquote@</property>
<property name="context">@context;noquote@</property>

<include src="progress-bar" num_completed="3">

<p>

<if @tasks:rowcount@ eq 0>
    You don't have any tasks setup. You probably want to <a href="tasks">go do that first</a>.
</if>

<if @tasks:rowcount@ eq 1>
    You only have <b>one task defined</b>. That's barely
    enough to call a <em>process</em>, so you probably want to <a
    href="tasks">go back and define more tasks</a>. 

    <p>

    If you insist that you only want one task, that's fine. But since the first task
    must always be statically assigned, there's nothing you can do
    here.
</if>

<if @tasks:rowcount@ ge 2>    
    <blockquote>
    
    Assignment can happen in one of two ways for each task:
    
    <dl> 
    
    <dt><b>Static assignment</b> 
    
    <dd>If you want the <b>same person</b> or group of people to always be
    assigned to a task, add the persons to the assignees for that
    task. You''ll <b>pick the actual assignees later</b>.
    
    <p>
    
    <dt><b>Manual assignment</b>
    
    <dd>If you want to do the assignment on a <b>case-by-case basis</b>, tell us
    what other task you want to do the assignment for this task.
    
    </dl>
    
    </blockquote>
</if>

<blockquote>
  <table cellspacing=0 cellpadding=0 border=0>
    <tr>
      <td bgcolor=#cccccc>
        <table width="100%" cellspacing=1 cellpadding=4 border=0>
          <tr bgcolor=#ffffe4>
            <th>Order</th>
            <th>Task</th>
            <th>Assignment</th>
            <th>Action</th>
          </tr>
          <multiple name="tasks_with_options">
            <tr valign=middle bgcolor=#eeeeee>
              <td align=right>@tasks_with_options.rownum@.</td>
              <td align=left>@tasks_with_options.task_name@</td>
              <td align=left>
                <if @tasks_with_options.assigning_task_name@ nil>
                  <em>static</em>
                </if>
                <else>
                  Manual: assigned during task '@tasks_with_options.assigning_task_name@'
                </else>
              </td>
              <if @tasks_with_options.rownum@ eq 1>
                <group column="transition_key"></group>
                <td><em>first task must be statically assigned</em></td>
              </if>
              <else>
                <if @tasks_with_options.assigning_task_name@ nil>
                  <form action=manual-assignment>
                  <input type=hidden name="assigned_transition_key" value="@tasks_with_options.transition_key@">
                  <td>
                    Assign during task 
                    <select name="assigning_transition_key">
                      <group column="transition_key">
                        <option value="@tasks_with_options.assigning_transition_key_option@">
                          @tasks_with_options.assigning_task_num_option@. 
                          @tasks_with_options.assigning_task_name_option@
                        </option>
                      </group>
                    </select>
                    <input type=submit value="Update">
                  </td>
                  </form>
                </if>
                <else>
                  <group column="transition_key"></group>
                  <td>
                    (<a href="static-assignment?transition_key=@tasks_with_options.transition_key@"
                     >make static</a>)
                  </td>
                </else>
              </else>
            </tr>
          </multiple>
        </table>
      </td>
    </tr>
  </table>
</blockquote>

<p>


<p>&nbsp;<p>
<form action="create" method=post>
<center>
<input type=submit value="Finish">
<br>Hit Finish when you're <b>done setting up assignments</b>, and we'll <b>create the process</b>.
<br>(You'll pick the actual persons to assign later)
</center>
</form>

</master>


