<master src="/packages/intranet-contacts/lib/contacts-master" />
<property name="party_id">@party_id@</property>

<include src="/packages/mail-tracking/lib/messages" 
	party="@party_id@" 
	page="@page@" 
	page_size="25"
	pkg_id="@pkg_id@"
        />