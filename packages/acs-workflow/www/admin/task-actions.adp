<master>
<property name="title">@workflow_name@ - @transition_name@ - Task Actions</property>
<property name="context">@context;noquote@</property>
<property name="focus">actions.enable_callback</property>

<form action="task-actions-2" name="actions">
@export_vars;noquote@
<table cellspacing="0" cellpadding="0" border="0">
  <tr>
    <td bgcolor="#cccccc">
      <table width="100%" cellspacing="1" cellpadding="4" border="0">

        <tr bgcolor="#ccccff">
          <th>Action Type</th>
          <th></th>
          <th>Value</th>
        </tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="2">Enable</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="enable_callback" size="80" value="@enable_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="enable_custom_arg" size="80" value="@enable_custom_arg@" /></td>
        </tr>

	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="2">Fire</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="fire_callback" size="80" value="@fire_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="fire_custom_arg" size="80" value="@fire_custom_arg@" /></td>
        </tr>

	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="2">Time</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="time_callback" size="80" value="@time_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="time_custom_arg" size="80" value="@time_custom_arg@" /></td>
        </tr>
       
	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="3">Deadline</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="deadline_callback" size="80" value="@deadline_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="deadline_custom_arg" size="80" value="@deadline_custom_arg@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>or use Attribute name</td>
          <td>
            <input type="text" name="deadline_attribute_name" size="80" value="@deadline_attribute_name@" />
          </td>
        </tr>


	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="2">Hold Timeout</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="hold_timeout_callback" size="80" value="@hold_timeout_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="hold_timeout_custom_arg" size="80" value="@hold_timeout_custom_arg@" /></td>
        </tr>

	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="2">Notification</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="notification_callback" size="80" value="@notification_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="notification_custom_arg" size="80" value="@notification_custom_arg@" /></td>
        </tr>

	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <th bgcolor="#ffffe4" rowspan="2">Unassigned task</th>
          <td>PL/SQL proc</td>
          <td><input type="text" name="unassigned_callback" size="80" value="@unassigned_callback@" /></td>
        </tr>
        <tr bgcolor="#dddddd">
          <td>Custom argument</td>
          <td><input type="text" name="unassigned_custom_arg" size="80" value="@unassigned_custom_arg@" /></td>
        </tr>

	<tr><td height="4" colspan="3"></td></tr>

	<tr bgcolor="#dddddd">
          <td colspan="3" align="center">
            <input type="submit" value="Update" />
          </td>
        </tr>
	
      </table>
    </td>
  </tr>
</table>

<p>

</master>
