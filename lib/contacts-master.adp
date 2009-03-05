<if @contacts_master_template@ eq /packages/intranet-contacts/lib/contacts-master>

	<master>
	<property name="title">@title@</property>
	<property name="context">@context@</property>
	<property name="header_stuff">
		<link href="/resources/intranet-contacts/contacts.css" rel="stylesheet" type="text/css">
	</property>
	<property name="navbar_list">@navbar@</property>
	<if @focus@ not nil>
		<property name="focus">@focus@</property>
	</if>
	<property name="sub_navbar">@contacts_navbar_html;noquote@</property>

</if>
<else>

	<master src="@contacts_master_template@">
	<property name="title">@title@</property>
	<property name="context">@context@</property>
	<property name="header_stuff">
		<link href="/resources/contacts/contacts.css" rel="stylesheet" type="text/css">
	</property>

</else>

<slave>

