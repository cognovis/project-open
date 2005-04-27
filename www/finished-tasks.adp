<if @finished_tasks:rowcount@ eq 0>
  <blockquote>
    <em>No tasks have finished yet.</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
        <table width="100%" cellspacing="1" cellpadding="4" border="0">
          <tr valign="middle" bgcolor="#ffffe4">
            <th>Task Name</th>
            <th>State</th>
            <th>Activated Date</th>
            <th>Done Date</th>
            <th>Done By</th>
          </tr>
          <multiple name="finished_tasks">
            <tr bgcolor="#eeeeee">
              <td><a href="task?task_id=@finished_tasks.task_id@">@finished_tasks.transition_name@</a></td>
              <td>@finished_tasks.state@</td>
              <td>@finished_tasks.enabled_date_pretty@</td>
              <td>
                <if @finished_tasks.done_date_pretty@ not nil>@finished_tasks.done_date_pretty@</if>
                <else>&nbsp;</else>
              </td>
              <td>
                <if @finished_tasks.done_by_name@ not nil>
                  <if @finished_tasks.done_by_url@ not nil>
                    <a href="@finished_tasks.done_by_url@">@finished_tasks.done_by_name@</a>
                  </if>
                  <else>@finished_tasks.done_by_name</else>
                  <if @finished_tasks.done_by_email@ not nil>
                    (<a href="mailto:@finished_tasks.done_by_email@">@finished_tasks.done_by_email@</a>)
                  </if>
                </if>
                <else>&nbsp;</else>
              </td>
            </tr>
          </multiple>
        </table>
      </td>
    </tr>
  </table>
</else>
