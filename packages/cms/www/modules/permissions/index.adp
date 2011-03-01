<if @user_permissions.cm_perm@ eq t>



<include src="../../table-header" 
  title="Permissions"
  header="@header;noquote@">


<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">
  <tr bgcolor="#99CCFF">
    <if @permissions:rowcount@ eq 0>
      <td colspan=3><em>No permissions.</em></td></if>
    <else>
      <th align=left nowrap>User</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Email</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Privilege(s)</th>
      <th>&nbsp</th>
    </else> 
  </tr>

  <if @permissions:rowcount@ gt 0>
    <multiple name=permissions>
      <if @permissions.grantee_id@ eq -1><tr bgcolor="CCFFFFFF"></if>
      <else>
        <if @permissions.rownum@ odd><tr bgcolor="#ffffff"></if>
        <else><tr bgcolor="#EEEEEE"></else>
      </else>

	<td>
          <if @permissions.grantee_id@ eq -1>
            <b>@permissions.grantee_name@</b>
          </if>
          <else>
            <a href="../users/one-user?id=@permissions.grantee_id@&mount_point=users">
	     @permissions.grantee_name@</a>
          </else>
	</td>
	<td>&nbsp;&nbsp;&nbsp;</td>
	<td><a href="mailto:@permissions.email@">@permissions.email@</a></td>
	<td>&nbsp;&nbsp;&nbsp;</td>
	<td>
	  <group column="grantee_name">
	    <if @permissions.groupnum@ gt 1>, </if>
            <if @permissions.pretty_name@ not nil>
              @permissions.pretty_name@ 
            </if>
            <else>
              @permissions.privilege@
            </else>
	  </group>
	</td>
	<td>
          <if @user_permissions.cm_perm@ eq t>
            <a href="../permissions/permission-alter?@perms_url_extra@&grantee_id=@permissions.grantee_id@">
            <img src="../../resources/Edit16.gif" border=0></a>
          </if>
          <else>&nbsp;</else>
	</td>

      </tr>
    </multiple>
  </if>

</table>


<include src="../../table-footer">

<p>
</if>
