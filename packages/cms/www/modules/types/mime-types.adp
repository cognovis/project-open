
  <p>


<include src="../../table-header" title="Registered Mime Types">
<table cellspacing=0 cellpadding=0 border=0 width="100%">

<if @user_permissions.cm_write@ eq t and @unregistered_mime_types_count@ gt 0>
  <tr>
    <td><formtemplate id="register">
      <table cellspacing=0 cellpadding=4 border=0 width="100%">
      <tr bgcolor="#EEEEEE"><td>
	<b>Register MIME type:</b>&nbsp;&nbsp;
	<formwidget id="id">
	<formwidget id="content_type">
        <formwidget id="mime_type">
        <input type=submit value="Register">
      </td></tr>
      </table>
      </formtemplate>
    </td>
  </tr>
</if>

<tr><td>

  <table class="blue" cellspacing=0 cellpadding=4 border=0 width="100%">
  <if @registered_mime_types:rowcount@ eq 0>
    <tr>
      <td>
        <em>There are no MIME types registered to this content type.</em>
      </td>
    </tr>
  </if>
  <else>
    <tr bgcolor="#99CCFF">
      <th align=left>Registered MIME Types</th>
      <th>&nbsp</th>
    </tr>

    <multiple name="registered_mime_types">
    <if @registered_mime_types.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>
      <td>@registered_mime_types.label@</td>
      <td align=right>
        <if @user_permissions.cm_write@ eq t>
          <a href="unregister-mime-type?content_type=@content_type@&mime_type=@registered_mime_types.mime_type@">Unregister</a>
        </if>
        <else>&nbsp;</else>
      </td>
    </tr>
    </multiple>
  </else>
  </table>


</td></tr>

</table>
<include src="../../table-footer">
<p>


