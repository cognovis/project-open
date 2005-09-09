<master>
  <property name="title">#acs-subsite.Log_In#</property>
  <property name="context">{#acs-subsite.Log_In#}</property>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>

<table>
<tr class=rowtitle>
<td class=rowtitle>Existing User</td>
<td class=rowtitle>New User</td>
</tr>
<tr valign=top>
<td>
  <include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">

</td>
<td>
  <include src="/packages/acs-subsite/lib/user-new" email="@email@" return_url="@return_url;noquote@" />
</td>
</tr>
</table>


