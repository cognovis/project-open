<master>
<property name="title">Assignments to be done by @transition_name;noquote@</property>
<property name="context">@context;noquote@</property>

The user performing the task <strong>@transition_name@</strong> will be asked to <strong>assign the following roles</strong>:

<table>
  <tr>
    <td width="10%">&nbsp;</td>
    <td>
      <table cellspacing="0" cellpadding="0" border="0">
	<tr>
	  <td bgcolor="#cccccc">
	    <table width="100%" cellspacing="1" cellpadding="4" border="0">
              <tr bgcolor="#ffffe4">
		<th>Role To Assign</th>
                <th>Action</th>
              </tr>
              <if @assigned_by_this:rowcount@ eq 0>
                 <tr bgcolor="#eeeeee">
                   <td colspan="4">
                     <em>No roles to be assigned by this task.</em>
                   </td>
                 </tr>
              </if>
              <else>
                <multiple name="assigned_by_this">
		  <tr bgcolor="#eeeeee">
		    <td>@assigned_by_this.role_name@</td>
		    <td align="center">
                      <small>(<a href="@assigned_by_this.delete_url@">remove</a>)</small>
		    </td>
		  </tr>
		</multiple>    
              </else>
            </table>
          </td>
        </tr>
      </table>
    </td>
    <td width="10%">&nbsp;</td>
  </tr>

  <tr><td colspan="3">&nbsp;</td></tr>

  <tr>
    <td>&nbsp;</td>
    <td colspan="2">
      <if @to_be_assigned_by_this:rowcount@ gt 0>
	<form action="@assign_url@">
	@assign_export_vars;noquote@
	Assign this:
	<select name="role_key">
	  <multiple name="to_be_assigned_by_this">
	    <option value="@to_be_assigned_by_this.role_key@">@to_be_assigned_by_this.role_name@</option>
	  </multiple>
	</select>
	<input type="submit" value="Add" />
	</form>
      </if>    
    </td>
  </tr>

  <tr><td colspan="3">&nbsp;</td></tr>

  <form action="define">
  <input type="hidden" name="workflow_key" value="@workflow_key@" />
  <input type="hidden" name="transition_key" value="@transition_key@" />
  <tr bgcolor="#dddddd">
    <td colspan="3" align="right">
      <input type=submit value="Done" />
    </td>
  </tr>
  </form>
</table>



</master>