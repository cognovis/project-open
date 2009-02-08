<master src="/packages/intranet-contacts/lib/contacts-master" />

<if @delete_list_id@>


<p>#intranet-contacts.Are_you_sure_you_want_to_delete_list#</p>
<p><a href="@yes_url@">#acs-kernel.common_Yes#</a> - <a href="@no_url@">#acs-kernel.common_No#</a></p>
</if>
<else>

<p><formtemplate id="add_list" style="../../../contacts/resources/forms/inline"></formtemplate></p>
<br>
<listtemplate name="lists"></listtemplate>

</else>
