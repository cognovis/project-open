<master>
<property name="title">Add attribute</property>
<property name="context">@context;noquote@</property>
<property name="focus">attribute.name</property>

<form action="attribute-add-2" name="attribute">
@export_vars;noquote@

<table>
  <tr>
    <th align=right>Name</th>
    <td>
      <input type="text" size="30" name="attribute_name">
      <br><small>(no special characters)</small>
    </td>
  </tr>
  <tr>
    <th align=right>Pretty name<br>(Question)</th>
    <td>
      <input type="text" size="80" name="pretty_name">
    </td>
  </tr>
  <tr>
    <th align=right>Datatype</th>
    <td>
      <select name="datatype">
        <multiple name="datatypes">
          <option value="@datatypes.datatype@">@datatypes.datatype@</option>
        </multiple>
      </select>
    </td>
  </tr>
  <tr>
    <th align=right>Default value</th>
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