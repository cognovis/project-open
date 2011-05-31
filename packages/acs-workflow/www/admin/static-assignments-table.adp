<if @roles:rowcount@ eq 0>
  <blockquote>
    <em>#acs-workflow.No_roles_defined#</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table cellspacing="1" cellpadding="4" border="0">
	  <tr valign=middle bgcolor="#ffffe4">
            <th>#acs-workflow.Role#</th>
            <th>#acs-workflow.Assignments#</th>
            <th>#acs-workflow.Action#</th>
	  </tr>
   
	  <multiple name="roles">
	    <tr bgcolor="#eeeeee">
              <td>@roles.role_name@</td>
              <td>
                <group column="role_key">
                  <if @roles.party_id@ not nil>
		    <li>
		      @roles.party_name@ 
		      <if @roles.party_email@ not nil>
			(<a href="mailto:@roles.party_email@">@roles.party_email@</a>)
		      </if>
		      (<a href="@roles.remove_url@">#acs-workflow.remove#</a>)
		    </li>
                  </if>
                  <else>
                    <em>#acs-workflow.Unassigned#</em>
                  </else>
                </group>
	      </td>
              <if @roles.user_select_widget@ not nil>
		<form action="static-assignment-add" method="post">
		  @roles.add_export_vars;noquote@
		  <td>
		    @roles.user_select_widget;noquote@
		    <input type="submit" value="Add">
		  </td>
		</form>
              </if>
	      <else>
	        <td>&nbsp;</td>
              </else>
	    </tr>
	  </multiple>
	</table>
      </td>
    </tr>
  </table>
</else>




