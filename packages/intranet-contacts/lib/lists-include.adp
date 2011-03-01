<if @lists:rowcount@ gt 0 or @form_p@>

<h3>#intranet-contacts.Lists#</h3>

<ul>
<multiple name=lists>
  <li><a href="@lists.list_url@">@lists.title@</a><if @lists.owner_p@> <a href="@lists.delete_url@"><img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" alt="#intranet-contacts.Delete#" border="0" /></a></if></li>
</multiple>
<if @form_p@>
 <li><formtemplate id="add_list_member" style="../../../contacts/resources/forms/inline"></formtemplate></li>
</if>
</ul>
</if>


</if>
