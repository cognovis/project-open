<if @hide_form_p@ false>
<if @no_more_available_p@ nil>
<formtemplate id="add_to_group" style="../../../contacts/resources/forms/inline"></formtemplate>
</if>
<else>
<p>#intranet-contacts.lt_You_cannot_add_this_c#</p>
</else>
<h3 class="contact-title"><if @hide_form_p@ true><a href="./groups"></if>#intranet-contacts.Groups#<if @hide_form_p@ true></a></if></h3>
</if>
<if @groups:rowcount@ gt 0>
<dl class="groups">
<multiple name="groups">
   <if @groups.sub_p@><dd class="subgroup"></if><else><dt class="primarygroup"></else>
   @groups.group;noquote@ <a href="@groups.remove_url@"><img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0" alt="#intranet-contacts.Delete_from# @groups.group;noquote@"></a> - <font size="-2">[@groups.creation_date@]</font>
   <if @groups.sub_p@></dd></if><else><dt></else>
</multiple>
<if @user_p@ eq 1><dt class="primarygroup">#intranet-contacts.Users#</dt></if>
</dl>
</if>
<else>
<if @hide_form_p@ true><h3 class="contact-title"><a href="./groups">#intranet-contacts.Groups#</a></h3></if>
<if @user_p@ eq 1>
<dl class="groups">
  <dt class="primarygroup">#intranet-contacts.Users#</dt>
</dl>
</if>
</else>

<if @hide_form_p@ false and @delete_p@>
<h3>#intranet-contacts.Other_Options#</h3>
<ul class="action-links">
  <li><a href="@remove_url@">#intranet-contacts.lt_Delete_this_contact#</a>
<if @upgrade_url@ not nil>
  <li><a href="@upgrade_url@">#intranet-contacts.lt_Upgrade_this_person_to_a_user#</a>
</if>
</ul>
</if>
