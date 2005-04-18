<master src="../../master">
<property name="title">Permissions on @info.object_name;noquote@ for @info.grantee_name;noquote@ </property>

<if @info.user_cm_perm@ eq t>

  <h2>Permissions on @info.object_name@ for @info.grantee_name@</h2>

  <h3>Alter permissions</h3>
  <formtemplate id="own_permissions"></formtemplate>
</if>

