<master>
<property name="title">Add Assignee</property>
<property name="context">@context;noquote@</property>
<property name="focus">@focus;noquote@</property>

<if @party_widget@ nil>
  <blockquote>
    <em>Every possible assignee is already assigned</em>
    <p>
    <ul>
      <li><a href="@return_url@">Go back</a></li>
    </ul>
  </blockquote>
</if>

<else>
  <form action="assignee-add-2" name="assign">
  @export_vars;noquote@
  <table>
    <tr>
      <th align="right">
	Party to assign
      </th>
      <td>
	@party_widget;noquote@ <input type="submit" value="Add" />
      </td>
    </tr>
    </table>
  </form>
</else>

</master>
