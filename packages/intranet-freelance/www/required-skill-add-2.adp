<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label"></property>

<h1>@page_title@</h1>

<table>
<form action=required-skill-add-2 method=POST>
<%= [export_form_vars object_id skill_type_id return_url] %>

  <tr class="list-header">
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-freelance.Skills "Skills"] %></th>
    <th class="list-narrow">
	<input type="checkbox" name="_dummy" onclick="acs_ListCheckAll('alerts', this.checked)" title="<%= [lang::message::lookup "" intranet-forum.Check_Uncheck_all_rows "Check/Uncheck all rows"] %>">
    </th>
  </tr>

  <multiple name=skills>
  <if @skills.rownum@ odd>
    <tr class="list-odd">
  </if> <else>
    <tr class="list-even">
  </else>

    <td class="list-narrow">
        @skills.category@
    </td>
    <td class="list-narrow">
        <input type=checkbox name=notifyee_id value="@skills.category_id@" id="alerts,@category_id@" @skills.checked@>
    </td>
  </tr>
  </multiple>


  <tr>
    <td colspan=3 align=right>
      <input type=submit value="<%= [lang::message::lookup "" intranet-forum.Add_Skills "Add Skills"] %>">
    </td>
  </tr>

</form>
</table>

