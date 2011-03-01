<if @form@ eq top and @hide_form_p@ false>
<formtemplate id="comment_add" style="../../../contacts/resources/forms/inline"></formtemplate>
</if>

<if @history:rowcount@ gt 0>
  <dl class="comments">
<multiple name="history">
    <dt id="@history.object_id@" class="<if @history.creation_user@ eq @user_id@>mine-</if><if @history.rownum@ odd>odd</if><else>even</else>">@history.date@ #intranet-contacts.at# @history.time@ @history.user_link@<if @history.delete_url@> <a href="@history.delete_url@"><img src="/resources/acs-subsite/Delete16.gif" alt="#acs-subsite.Delete#" border="0" title="#acs-subsite.Delete#" /></a></if></dd>
      <dd class="<if @history.creation_user@ eq @user_id@>mine-</if><if @history.rownum@ odd>odd</if><else>even</else>">
   
	<if @history.include@ nil>
	      @history.content;noquote@
        </if>
        <else>
              <include src=@history.include@ content=@history.content;noquote@ object_id=@history.object_id@ party_id=@party_id@>
        </else>

      </dd>
</multiple>
  </dl>
</if>
<if @form@ eq bottom and @hide_form_p@ false>
<formtemplate id="comment_add" style="../../../contacts/resources/forms/inline"></formtemplate>
</if>

