<master>
<property name="title">#acs-workflow.lt_Assignments_to_be_don#</property>
<property name="context">@context;noquote@</property>

#acs-workflow.lt_The_user_performing_t# <strong>@transition_name@</strong> #acs-workflow.will_be_asked_to# <strong>#acs-workflow.lt_assign_the_following_#</strong>:

<table>
  <tr>
    <td width="10%">&nbsp;</td>
    <td>
      <table cellspacing="0" cellpadding="0" border="0">
	<tr>
	  <td bgcolor="#cccccc">
	    <table width="100%" cellspacing="1" cellpadding="4" border="0">
              <tr bgcolor="#ffffe4">
		<th>#acs-workflow.Role_To_Assign#</th>
                <th>#acs-workflow.Action#</th>
              </tr>
              <if @assigned_by_this:rowcount@ eq 0>
                 <tr bgcolor="#eeeeee">
                   <td colspan="4">
                     <em>#acs-workflow.lt_No_roles_to_be_assign#</em>
                   </td>
                 </tr>
              </if>
              <else>
                <multiple name="assigned_by_this">
		  <tr bgcolor="#eeeeee">
		    <td>@assigned_by_this.role_name@</td>
		    <td align="center">
                      <small>(<a href="@assigned_by_this.delete_url@">#acs-workflow.remove#</a>)</small>
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
	#acs-workflow.lt_assign_export_varsnoq#
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
