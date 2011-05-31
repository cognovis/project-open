<master>
<property name="title">#acs-workflow.lt_Edit_role_namenoquote#</property>
<property name="context">@context;noquote@</property>
<property name="focus">role.role_name</property>

<form action="role-edit-2" name="role" method="post">
@export_vars;noquote@
<table>
  <tr>
    <th align="right">
      #acs-workflow.Role_name#
    </th>
    <td>
      <input name="role_name" type="text" value="@role_name@" size="50" />
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <input type="submit" name="submit" value="Edit" />
      &nbsp; &nbsp; &nbsp;
      <input type="submit" name="cancel" value="Cancel" />
    </td>
  </tr>
</table>

</form>

</master>
