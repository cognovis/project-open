<master src="/packages/intranet-core/www/admin/master">
<property name="title">@title@</property>
<property name="context">@context@</property>
<property name="navbar_list">@navbar@</property>
<property name="admin_navbar_label">dynfield_admin</property>
<property name="left_navbar">@left_navbar;noquote@</property>

<if @focus@ not nil><property name="focus">@focus@</property></if>

<slave>

