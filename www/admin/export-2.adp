<master>
<property name="title">#acs-workflow.lt_Export_Business_Proce#</property>
<property name="context">@context;noquote@</property>

<if @message@ not nil>
  <blockquote><strong>@message@</strong></blockquote>
</if>

<if @format@ eq "view">
  <pre>@sql_script@</pre>
</if>
<else>
  <blockquote>
    <textarea name="sql_script" rows="30" cols="80">@sql_script@</textarea>
  </blockquote>
</else>

<table width="100%">
  <form action="workflow">
  <input type="hidden" name="workflow_key" value="@workflow_key@">
  <tr bgcolor="#dddddd">
    <td align="right">
      <input type="submit" value="Done">
    </td>
  </tr>
</table>

</master>
