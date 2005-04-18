<master src="../../master">
<property name="title">One User</property>

<h2>User: @info.first_names@ @info.last_name@</h2>

<h3>User Info</h3>
  
<table border=0 cellpadding=4 cellspacing=0>
  <tr><td align=right><b>First Names:</b></td>
      <td align=left>@info.first_names@</td></tr>
  <tr><td align=right><b>Last Name:</b></td>
      <td align=left>@info.last_name@</td></tr> 
  <tr><td align=right><b>Screen Name:</b></td>
      <td align=left>@info.screen_name@</td></tr>   
  <tr><td align=right><b>Email:</b></td>
      <td align=left><a href="mailto:@info.email@">@info.email@</a></td></tr>
  <tr><td align=right><b>URL:</b></td>
      <td align=left>
        <if @info.no_alerts_until not nil><a href="@info.url@">@info.url@</a></if>
        <else>&nbsp;</else>
      </td></tr>
  <tr><td align=right><b>Last Visit:</b></td>
      <td align=left>
        <if @info.no_alerts_until not nil>@info.last_visit@</if>
        <else>never</else>
      </td></tr>   
  <if @info.no_alerts_until@ not nil>
    <tr><td align=right><b>No Alerts Until:</b></td>
        <td align=left>@info.no_alerts_until@</td></tr>   
  </if>
</table>

<h3>Groups this user belongs to</h3>

<if @groups:rowcount@ gt 0>
  <multiple name=groups> 
    <if @groups.rownum@ gt 1>, </if>
    <a href="index?id=@groups.group_id@&@passthrough@">@groups.group_name@</a>
  </multiple>
</if>
<else>
  none
</else>

<br>
<hr>

<a href="edit-user?id=@id@&@passthrough@"><img 
  src="../../resources/Edit24.gif" width=24 height=24 border=0></a>
<a href="edit-user?id=@id@&@passthrough@">Edit</a> this user <br>

<a href="delete-user?id=@id@&@passthrough@"><img 
   src="../../resources/Delete24.gif" width=24 height=24 border=0></a>
<a href="delete-user?id=@id@&@passthrough@">Delete</a> this user <br>



