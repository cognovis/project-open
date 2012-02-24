<master>
<property name="title">#acs-workflow.Add_Assignee#</property>
<property name="context">@context;noquote@</property>
<property name="focus">@focus;noquote@</property>

<if @party_widget@ nil>
  <blockquote>
    <em>#acs-workflow.lt_Every_possible_assign#</em>
    <p>
    <ul>
      <li><a href="@return_url@">#acs-workflow.Go_back#</a></li>
    </ul>
  </blockquote>
</if>

<else>
  <form action="assignee-add-2" name="assign">
  @export_vars;noquote@
  <table>
    <tr>
      <th align="right">
	#acs-workflow.Party_to_assign#
      </th>
      <td>
	@party_widget;noquote@ <input type="submit" value="Add" />
      </td>
    </tr>
    </table>
  </form>
</else>

</master>

