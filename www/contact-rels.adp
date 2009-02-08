<master src="/packages/intranet-contacts/lib/contact-master">
<property name="party_id">@party_id@</property>
<property name="focus">search.searchterm</property>


<p>
<formtemplate id="search" style="../../../contacts/resources/forms/inline"></formtemplate>
</p>

<if @query@ not nil and @role_two@ not nil>
<listtemplate name="contacts"></listtemplate>

<h3>#intranet-contacts.lt_Existing_Relationship#</h3>
</if>
<listtemplate name="relationships"></listtemplate>


