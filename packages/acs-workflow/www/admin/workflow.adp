<master>
<property name="title">@workflow.pretty_name;noquote@</property>
<property name="context">@context;noquote@</property>

<!-- Tab bar -->
<include src="workflow-tabs" tab="@tab;noquote@" workflow_key="@workflow_key;noquote@">

<table width="100%" cellspacing="4" cellpadding="2" border="0">
  <tr>
    <td valign="top">

      <!-- Left side -->

      <if @tab@ eq "home">

        <!-- HOME TAB BEGIN -->
 
	<!-- Process Name -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    @workflow.pretty_name@
		  </th>
		</tr>
	       <tr bgcolor="#ffffff">
		 <td>
		   @workflow.description@
		   <div align="right">(<a href="name-edit?workflow_key=@workflow.workflow_key@">#acs-workflow.edit_name#</a>)</div>
		 </td>
	       </tr>
	     </table>
	   </td>
	  </tr>
	</table>
	
	<p>
  
	<!-- Actions -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Actions#
		  </th>
		</tr>
               <tr bgcolor="#ffffff">
                 <td>
                   (<a href="@edit_process_url@">#acs-workflow.lt_graphic_process_edito#</a>)
                   (<a href="@export_process_url@">#acs-workflow.export_process#</a>)
                   <if @copy_process_url@ not nil>
                     (<a href="@copy_process_url@">#acs-workflow.make_a_copy#</a>)
                   </if>
		 </td>
	       </tr>
	     </table>
	   </td>
	  </tr>
	</table>
	
	<p>
  
	<!-- Cases -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>#acs-workflow.Cases#</th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td>
		    <if @workflow.num_unassigned_tasks@ gt 0>
		      <strong>#acs-workflow.Note_# 
			<a href="unassigned-tasks?workflow_key=@workflow.workflow_key@">
			  @workflow.num_unassigned_tasks@ 
			  unassigned task<if @workflow.num_unassigned_tasks@ gt 1>s</if>
			</a>
		      </strong>
		      <p>
		    </if>
		    <p>
		    <if @workflow.num_active_cases@ eq 0>
		      #acs-workflow.No_active_cases#
		    </if>
		    <if @workflow.num_active_cases@ eq 1>
		      <a href="cases?state=active&workflow_key=@workflow.workflow_key@">#acs-workflow.1_active_case#</a>
		    </if>
		    <if @workflow.num_active_cases@ gt 1>
		      <a href="cases?state=active&workflow_key=@workflow.workflow_key@">#acs-workflow.lt_workflownum_active_ca#</a>
		    </if>
		    <p>
		    <if @workflow.num_cases@ eq 0>
		      #acs-workflow.No_old_cases#
		    </if>
		    <if @workflow.num_cases@ eq 1>
		      <a href="workflow-summary?workflow_key=@workflow.workflow_key@">#acs-workflow.1_case_total#</a>
		    </if>
		    <if @workflow.num_cases@ gt 1>
		      <a href="workflow-summary?workflow_key=@workflow.workflow_key@">#acs-workflow.lt_workflownum_cases_cas#</a>
		    </if>
		    <p>
		    (<a href="init?workflow_key=@workflow.workflow_key@">#acs-workflow.start_new_case#</a>)
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

        <p>

        <!-- Extreme actions -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>#acs-workflow.Extreme_Actions#</th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td>
		    <if @workflow.num_cases@ gt 0>
		      (<a href="javascript:if(confirm('Are you sure that you want to delete all cases of this process?'))location.href='workflow-cases-delete?workflow_key=@workflow.workflow_key@'">#acs-workflow.delete_all_cases#</a>) &nbsp;
		    </if>
		    (<a href="javascript:if(confirm('Are you sure you want to delete this business process definition?
	Doing so will delete all cases of this workflow.'))location.href='workflow-delete?workflow_key=@workflow.workflow_key@'">#acs-workflow.lt_delete_process_entire#</a>)
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

        <!-- HOME TAB END -->
      </if>

      <if @tab@ eq "process">
        <!-- PROCESS TAB BEGIN -->

	<!-- Transitions -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Transitions#
		  </th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td align="left">
		    <include src="transitions-table" workflow_key="@workflow_key;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>
	
        <!-- PROCESS TAB END -->
      </if>

      <if @tab@ eq "attributes">
        <!-- ATTRIBUTES TAB BEGIN -->

	<!-- Attributes -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Attributes#
		  </th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td align="left">
		    <include src="attributes-table" workflow_key="@workflow_key;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

        <!-- ATTRIBUTES TAB END -->
      </if>

      <if @tab@ eq "roles">
        <!-- ROLES TAB BEGIN -->   

	<!-- Roles -->
	
	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Roles#
		  </th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td align="left">
		    <include src="roles-table" workflow_key="@workflow_key;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

        <!-- ROLES TAB END -->
      </if>

      <if @tab@ eq "timing">
        <!-- TIMING TAB BEGIN -->   


        <!-- TIMING TAB END -->
      </if>

      <if @tab@ eq "panels">
        <!-- PANELS TAB BEGIN -->   

	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Transition_Panels#
		  </th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td align="left">
		    <include src="transition-panels-table" workflow_key="@workflow_key;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

        <!-- PANELS TAB END -->
      </if>

      <if @tab@ eq "assignments">
        <!-- ASSIGNMENTS TAB BEGIN -->   

	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table width="100%" cellspacing="1" cellpadding="2" border="0">
		<tr valign="middle" bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Static_Assignments#
		  </th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td align="left">
		    <include src="static-assignments-table" workflow_key="@workflow_key;noquote@" return_url="@return_url;noquote@" modifiable_p="@modifiable_p;noquote@">
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

        <!-- ASSIGNMENTS TAB END -->
      </if>



    </td>
    <td align="center" valign="top">

      <!-- Right side -->

      <if 1 eq 1>

	<!-- Process graph -->
	<table width="100%" cellspacing="0" cellpadding="0" border="0">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table border="0" cellspacing="1" cellpadding="2" width="100%">
		<tr bgcolor="#ccccff">
		  <th>
		    #acs-workflow.Process#
		  </th>
		</tr>
		<tr bgcolor="#ffffff">
		  <td>
		    <include src="workflow-graph" workflow_key="@workflow_key;noquote@" size="3,6" modifiable_p="@modifiable_p;noquote@">
		  </td>
		</tr>
	      </table>
	    </td>
	  </tr>
	</table>

      </if>

    </td>
  </tr>
  <tr>

    <!-- Bottom row -->

    <td colspan="2">
      
    </td>
  </tr>
</table>


</master>

