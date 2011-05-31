<master>
<property name="title">@workflow.pretty_name;noquote@</property>
<property name="context">@context;noquote@</property>

<!-- Tab bar -->

<table width="100%" cellspacing="4" cellpadding="2" border="0">
  <tr>
    <td valign="top">

      <!-- Left side -->

      <if @tab@ eq "hooome">
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
		   <div align="right">(<a href="name-edit?workflow_key=@workflow.workflow_key@">#intranet-workflow.edit_name#</a>)</div>
		 </td>
	       </tr>
	     </table>
	   </td>
	  </tr>
	</table>
	<p>
      </if>



    </td>
    <td align="center" valign="top">

      <!-- Right side -->

      <if 1 eq 1>

	<!-- Process graph -->
	<table cellspacing="0" cellpadding="0" border="0">
	  <tr>
	    <td bgcolor="#cccccc">
	      <table border="0" cellspacing="1" cellpadding="2" width="100%">
		<tr bgcolor="#ccccff">
		  <th>
		    #intranet-workflow.Process#
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

