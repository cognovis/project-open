<if @gone_p@ true>
  <if @object_type@ eq organization>
    <h3 class="contact-title contact-privacy">#intranet-contacts.This_organization_has_closed_down#</h3>
  </if>
  <else>
    <h3 class="contact-title contact-privacy">#intranet-contacts.This_person_is_deceased#</h3>
  </else>
</if>
<else>
  <if @email_p@ false><h3 class="contact-title contact-privacy">#intranet-contacts.Do_not_email#</h3></if>
  <if @mail_p@  false><h3 class="contact-title contact-privacy">#intranet-contacts.Do_not_mail#</h3></if>
  <if @phone_p@ false><h3 class="contact-title contact-privacy">#intranet-contacts.Do_not_phone#</h3></if>
</else>
