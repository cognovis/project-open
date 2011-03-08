<master src="../../master">
<property name="title">User Groups</property>

<script language=javascript>
  top.treeFrame.setCurrentFolder('@mount_point@', '@id@', '@parent_id@');
</script> 

<table width=95% cellspacing=0 cellpadding=4>
<tr>
  <td class=large>
    <include src="../../bookmark" 
             mount_point="@mount_point;noquote@" 
             id="@info.group_id;noquote@">&nbsp;
    <b>@info.group_name@</b>
  </td>
</tr>
</table>
<br>

<if @info.email@ not nil>
 <b>Email:</b> <href="mailto:@info.email@">@info.email@</a>
 <br>
</if>



<if @subgroups:rowcount@ gt 0>

  <include src="../../table-header" title="Subgroups">
  <table bgcolor=#99CCFF cellspacing=0 cellpadding=4 border=0 width="100%">

  <tr bgcolor="#99CCFF">
    <th width="5%">&nbsp;</th>
    <th width="5%">&nbsp;</th>
    <th width="30%">Name</th>
    <th>Email</th>
    <th>Users</th>
    <if @admin_p@ eq t>
      <th>&nbsp;</th>
    </if>
  </tr>

  <multiple name=subgroups>
  <if @subgroups.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>
    <td nowrap height=12>
      <include src="../../bookmark" 
               mount_point="@mount_point;noquote@" 
               id="@subgroups.group_id;noquote@">
    </td>
    <td>
      <a href="index?id=@subgroups.group_id@&mount_point=@mount_point@&parent_id=@id@">
        <img src="../../resources/Open24.gif" border=0>      
      </a>
    </td>
    <td>
      <a href="index?id=@subgroups.group_id@&mount_point=@mount_point@&parent_id=@id@">
        @subgroups.group_name@
      </a>
    </td>
    <td>@subgroups.email@</td>
    <td>@subgroups.user_count@</td>
    <if @admin_p@ eq t>
      <td><a href="@admin_url@@subgroups.group_id@">Make Admin</a></td>
    </if>
  </tr>
  </multiple>  

  </table>
  <include src="../../table-footer">
  <p>
</if>

<if @users:rowcount@ gt 0>

  <include src="../../table-header" title="Users">
  <table bgcolor=#99CCFF cellspacing=0 cellpadding=4 border=0 width="100%">

  <tr bgcolor="#99CCFF">
    <th width="5%">&nbsp;</th>
    <th width="5%">&nbsp;</th>
    <th width="30%">Name</th>
    <th>Screen Name</th>
    <th>Email</th>
    <if @id@ not nil><th>Membership</th></if>
    <if @admin_p@ eq t>
      <th>&nbsp;</th>
    </if>
  </tr>

  <multiple name=users>
  <if @users.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>
    <td nowrap height=12>
      <include src="../../bookmark" 
               mount_point="@mount_point;noquote@" 
               id="@users.user_id;noquote@">
    </td>
    <td>
      <a href="one-user?id=@users.user_id@&mount_point=@mount_point@&parent_id=@id@">
        <img src="../../resources/Page24.gif" border=0>
      </a>
    </td>
    <td>
      <a href="one-user?id=@users.user_id@&mount_point=@mount_point@&parent_id=@id@">
        @users.pretty_name@
      </a>
    </td>
    <td>@users.screen_name@</td>
    <td>@users.email@</td>
    <if @id@ not nil><td>@users.state_html;noquote@</td></if>
    <if @admin_p@ eq t>
      <td><a href="@admin_url@@users.user_id@">Make Admin</a></td>
    </if>
  </tr>
  </multiple>  

  </table>
  <include src="../../table-footer">
  <p>

</if>
<else>
  <i>There are no users in this group.</i>
</else>



<p>

<if @perm_p@ eq t and @id@ nil>
  <include src="../permissions/index" 
    object_id="@current_id;noquote@" 
    mount_point="@mount_point;noquote@" 
    return_url="@return_url;noquote@&mount_point=@mount_point;noquote@&id=@id;noquote@&parent_id=@parent_id;noquote@"
  > 
</if>

<hr>

<if @id@ not nil>

  <a href="edit?id=@id@&@passthrough@"><img 
    src="../../resources/Edit24.gif" width=24 height=24 border=0></a>
  <a href="edit?id=@id@&@passthrough@">Edit</a> this group <br>

  <if @info.is_empty@ eq t>
    <a href="delete?id=@id@&@passthrough@"><img 
	src="../../resources/Delete24.gif" width=24 height=24 border=0></a>
    <a href="delete?id=@id@&@passthrough@">Delete</a> this group <br>
  </if>

</if>

<a href="create?parent_id=@id@&mount_point=@mount_point@"><img 
  src="../../resources/Open24.gif" width=24 height=24 border=0></a>
<a href="create?parent_id=@id@&mount_point=@mount_point@">Create a new subgroup</a> 
  within this group.<br>

<a href="user-assoc?id=@id@&@passthrough@"><img 
  src="../../resources/Copy24.gif" width=24 height=24 border=0></a>
<a href="user-assoc?id=@id@&@passthrough@">Associate</a>
  marked users with this group.<br>

<a href="user-search?group_id=@id@&@passthrough@"><img 
  src="../../resources/Search24.gif" width=24 height=24 border=0></a>
<a href="user-search?group_id=@id@&@passthrough@">Search</a>
  members of this group.<br>

<p>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>

</body>
</html>





