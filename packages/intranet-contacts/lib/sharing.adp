<master src="/packages/intranet-contacts/lib/contacts-master" />
<property name="title">@title@: #intranet-contacts.Sharing#</property>

<p><a href="@return_url@" class="button">#intranet-contacts.Return_to_where_you_were#</a></p>



<h2>#intranet-contacts.Sharing#: <if @public_p@>#intranet-contacts.Public#</if><else>#intranet-contacts.Owners_Only#</else></h2>

<if @admin_p@>
<ul>
<li><a href="@public_url@">#intranet-contacts.Change_Sharing#</a></li>
</ul>
</if>
<h2>#intranet-contacts.Owners#</h2>

<listtemplate name="owners"></listtemplate>

<p><formtemplate id="add_owner" style="../../../contacts/resources/forms/inline"></formtemplate></p>

