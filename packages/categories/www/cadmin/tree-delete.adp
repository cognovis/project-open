<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="locale">@locale;noquote@</property>

<p>
<table>
  <tr><th>Tree Name</th><td>@tree_name@</td></tr>
  <tr><th>Description</th><td>@tree_description@</td></tr>
</table>
</p>

<if @instances_using_p@ eq t>
  This tree is still used by some modules. For a complete list, please go
  <a href="@usage_url@">here</a>.
</if>

<if @used_categories:rowcount@ gt 0>
  <p><b>Categories still used</b>
  <listtemplate name="used_categories"></listtemplate>
  <p>
</if>

<if @instances_using_p@ ne t>
  Are you sure you want to delete the tree "@tree_name@"?
  <p>
    <a href="@delete_url@" class="button">Delete</a>
    &nbsp;&nbsp;&nbsp;
    <a href="@cancel_url@" class="button">No, Cancel</a>
  </p>
</if>
