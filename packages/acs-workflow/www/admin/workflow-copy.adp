<master>
<property name="title"><#Copy_Process Copy Process#></property>
<property name="context">@context;noquote@</property>
<property name="focus"><#lt_workflownew_workflow_ workflow.new_workflow_pretty_name#></property>

<#lt_Youre_about_to_make_a You're about to make a copy of the process @pretty_name@.#>

<p>

<#lt_You_must_come_up_with You must come up with a new name (both singular and plural) for the copy of the process.
The form has been pre-filled with new names that, while not very imaginative, are at 
least unique.#>

<form action="workflow-copy-2" name="workflow" method="post">
@export_vars;noquote@

<blockquote>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table width="100%" cellspacing="1" cellpadding="4" border="0">
	  <tr>
	    <th bgcolor="#ffffe4" align="left">
              <#New_Name New Name#>
            </th>
	    <td bgcolor="#eeeeee">
              <input type="text" size="50" name="new_workflow_pretty_name" value="@new_workflow_pretty_name@" />
            </td>
	  </tr>
          <tr>
            <td bgcolor="#eeeeee" align="center" colspan="2"> 
              <input type="submit" value="Copy" />
            </td>
          </tr>
	</table>
      </td>
    </tr>
  </table>
</blockquote>

</form>


</master>
