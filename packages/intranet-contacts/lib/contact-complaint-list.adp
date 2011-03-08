<table cellpadding="3" cellspacing="3" width="100%">
  <tr>
    <if @filter_p@ eq 1>
      <td class="list-filter-pane-big" valign="top" width="20%">
          <listfilters name="complaint"></listfilters>
      </td>            
    </if>
    <if @complaint:rowcount@ gt 0>
    <td valign="top" width="80%">
	<listtemplate name="complaint"></listtemplate>	
    </td>
    </if>
  </tr>
</table>

