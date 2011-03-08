<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<if @group_id@>
#intranet-contacts.lt_permissions_for_groups_explained#
</if>
<else>
#intranet-contacts.lt_permissions_for_package_explained#
</else>

<include src="/packages/acs-subsite/www/permissions/perm-include" object_id="@object_id@" user_add_url="permissions-user-add" privs="read create write delete admin">
