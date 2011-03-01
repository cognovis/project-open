<if @report_p@>
<p>
  <a href="@contacts_mode_url;noquote@" class="button">#intranet-contacts.View_Contacts#</a>
  <a href="@report_csv_url;noquote@" class="button">#intranet-contacts.CSV#</a>
</p>
<listtemplate name="report"></listtemplate>

</if>
<else>

<if @search_id@ not nil and @hide_form_p@ nil>
    <br>
    <table>
	<tr><td><b>#intranet-contacts.You_can_extend#</b></td></tr>
	<tr>
    	<if @available_options@ not nil>
	   <td><formtemplate id="extend" style="inline"></formtemplate></td>
           <td>&nbsp;&nbsp;&nbsp;</td>
        </if>
	</tr>
    </table>
</if>
<br>
<listtemplate name="contacts"></listtemplate>

</else>


<if @add_columns@ not nil or @remove_columns@ not nil>
<table cellpadding="0" cellspacing="0" border="0">
  <tr>
  <if @add_columns@ not nil>
    <td><formtemplate id="add_column_form" style="../../../contacts/resources/forms/inline"></formtemplate></td>
  </if>
  <if @remove_columns@ not nil>
    <td><formtemplate id="remove_column_form" style="../../../contacts/resources/forms/inline"></formtemplate></td>
  </if>
  <if @extended_columns@ not nil>
    <td>
      <if @report_p@ true>
        <a href="@contacts_mode_url;noquote@" class="button">#intranet-contacts.View_Contacts#</a>
      </if>
      <else>
        <a href="@report_mode_url;noquote@" class="button">#intranet-contacts.Aggregated_Report#</a>
      </else>
    </td>
  </if>
  </tr>
</table>
</if>
