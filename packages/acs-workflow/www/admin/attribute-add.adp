<master>
<property name="title">#acs-workflow.Add_attribute#</property>
<property name="context">@context;noquote@</property>
<property name="focus">#acs-workflow.attributename#</property>

<form action="attribute-add-2" name="attribute">
@export_vars;noquote@

<table>
  <tr>
    <th align=right>#acs-workflow.Name#</th>
    <td>
      <input type="text" size="30" name="attribute_name">
      <br><small>#acs-workflow.lt_no_special_characters#</small>
    </td>
  </tr>
  <tr>
    <th align=right>#acs-workflow.Pretty_name#<br>#acs-workflow.Question#</th>
    <td>
      <input type="text" size="80" name="pretty_name">
    </td>
  </tr>
  <tr>
    <th align=right>#acs-workflow.Datatype#</th>
    <td>
      <select name="datatype">
        <multiple name="datatypes">
          <option value="@datatypes.datatype@">@datatypes.datatype@</option>
        </multiple>
      </select>
    </td>
  </tr>
  <tr>
    <th align=right>#acs-workflow.Default_value#</th>
    <td>
      <input type="text" size="80" name="default_value">
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center"><input type="submit" value="Add"></td>
  </tr>
</table>

</form>

</master>
