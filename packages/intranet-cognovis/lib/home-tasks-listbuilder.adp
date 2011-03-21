
<form action="/intranet-timesheet2-tasks/home-task-action" method=POST>
  <input type=hidden name=view_id value="@view_id;noquote@">
  <input type=hidden name=return_url value="@return_url;noquote@">
 
  <listtemplate name="tasks"></listtemplate>
  
  <table align="center" valign="top" width="100%">
    <tr>
     <td valign=top align=left> <input type="submit" name="submit" value="Update Tasks"></td>
    </tr>
  </table>
</form>
