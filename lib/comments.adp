<h3>#intranet-contacts.Comments#</h3>

<if @form@ eq top>
<formtemplate id="comment_add" style="../../../contacts/resources/forms/inline"></formtemplate>
</if>

<if @comments:rowcount@ gt 0>
  <dl class="comments">
<multiple name="comments">
    <dt id="@comments.comment_id@" class="<if @comments.creation_user@ eq @user_id@>mine-</if><if @comments.rownum@ odd>odd</if><else>even</else>"><if @size@ eq small><a href="comments#@comments.comment_id@" class="number"></if><else><span class="number"></else>@comments.comment_number@.<if @size@ eq small></a></if><else></span></else> @comments.comment_number@.</a> @comments.pretty_date@ #intranet-contacts.at# @comments.pretty_time@ <a href="@comments.contact_url@">@comments.author@</a></dd>
      <dd class="<if @comments.creation_user@ eq @user_id@>mine-</if><if @comments.rownum@ odd>odd</if><else>even</else>">@comments.comment_html;noquote@</dd>
</multiple>
  </dl>
</if>

<if @form@ eq bottom>
<formtemplate id="comment_add" style="../../../contacts/resources/forms/inline"></formtemplate>
</if>

