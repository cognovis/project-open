<table valign="top" width="100%" cellpadding="20" border=1>
  <multiple name=task_info>
    <if @task_info.heading@ not nil>
      <tr>
        <td colspan="2" align="left">
          <h3 class="contact-title">@task_info.heading@</h3>
        </td>
      </tr>
    </if>
    <tr>
      <td align="right" valign="top" class="attribute" width="20%">@task_info.pretty_name;noquote@: </td>
      <td align="left" valign="top" class="value">@task_info.value;noquote@</td>
    </tr>
  </multiple>    
  <if @write@>
    <tr> 
      <td>&nbsp; </td>
      <td> 
        <form action=/intranet-timesheet2-tasks/new method=POST>
	  <input type="hidden" name="task_id" value="@task_id@">
	  <input type="hidden" name="form_mode" value="edit">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type=submit value="#intranet-core.Edit#" name=submit3>
        </form>
      </td>
    </tr>
  </if>
</table>