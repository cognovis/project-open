<table>
  <multiple name="user_info">
  <if @user_info.show_p@ eq 1>
    <tr @td_class;noquote@>
      <td>@user_info.col_name;noquote@</td>
      <td>@user_info.col_value;noquote@</td>
    </tr>
  </if>
  </multiple>
  <if @profile_component@ ne "">
  <tr @td_class;noquote@>
    <td>#intranet-core.Profile#</td>
    <td>@profile_component;noquote@</td>
  </tr>
</if>
  <formtemplate id="person_view" style="standard-withouttabletab"></formtemplate>
  <if @write_p@>
    <tr>
      <td class=form-label>&nbsp;</td>
      <td class=form-widget>
        <form action=new method=POST>
	  <input type="hidden" name="user_id" value="@user_id@">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type="submit" value="#intranet-core.Edit#">
	</form>
      </td>
    </tr>
  </if>
</table>

