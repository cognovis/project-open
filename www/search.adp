<master src="/packages/intranet-contacts/lib/contacts-master" />

<formtemplate id="advanced_search" style="../../../contacts/resources/forms/inline"></formtemplate>

<if @search_exists_p@>
<br />
<br />
<if @add_columns@ not nil or @remove_columns@ not nil>
<table cellpadding="0" cellspacing="0" border="0">
  <tr>
  <if @add_columns@ not nil>
    <td><formtemplate id="add_column_form" style="../../../contacts/resources/forms/inline"></formtemplate></td>
  </if>
  <if @remove_columns@ not nil>
    <td><formtemplate id="remove_column_form" style="../../../contacts/resources/forms/inline"></formtemplate></td>
    <td><a href="./?search_id=@search_id@&report_p=1" class="button">#intranet-contacts.Aggregated_Report#</a></td>
  </if>
  </tr>
</table>
</if>
</if>


