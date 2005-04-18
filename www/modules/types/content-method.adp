<include src="../../table-header" 
  title="Registered Content Insertion Methods">
<table cellspacing=0 cellpadding=0 border=0 width="100%">


<if @user_permissions.cm_write@ eq t and @unregistered_method_count@ gt 0>
  <tr>
    <td><formtemplate id="register">
      <table cellspacing=0 cellpadding=4 border=0 width="100%">
      <tr bgcolor="#EEEEEE"><td>
	<b>Register Content Insertion Method:</b>&nbsp;&nbsp;
	<formwidget id="content_type">
	<formwidget id="return_url">
        <formwidget id="content_method">&nbsp;
        <formwidget id="submit">
      </td></tr>
      </table>
      </formtemplate>
    </td>
  </tr>
</if>


<tr>
<td>


<table cellspacing=0 cellpadding=4 border=0 width="100%">

<if @content_methods:rowcount@ eq 0>
  <tr bgcolor="#99CCFF">
  <td>
    <em>There are no content methods registered to this content type. 
	By default, all content methods will be available to this
	content type.</em>
  </td>
  </tr>
</if>
<else>
  <tr bgcolor="#99CCFF">
    <th align=left>Content Method</th>
    <th align=left>Description</th>
    <th align=left>Is Default?</th>
    <th align=right>&nbsp;</th>
  </tr>

  <multiple name="content_methods">
  <if @content_methods.is_default@ eq t><tr bgcolor="#FFFFCC"></if>
  <else>
    <if @content_methods.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>
  </else>
    <td>@content_methods.label@</td>
    <td>@content_methods.description@</td>
    <td>
      <if @content_methods.is_default@ eq t>Yes</if><else>No</else>
    </td>
    <td align=right>
      <if @user_permissions.cm_write@ eq t>

      [
      <if @content_methods.is_default@ eq t>
	<a href="content-method-unset-default?content_type=@content_type@">Unset default</a>
      </if>
      <else>
        <a href="content-method-set-default?content_type=@content_type@&content_method=@content_methods.content_method@">Set as default</a>
      </else>
      |
      <a href="content-method-unregister?content_type=@content_type@&content_method=@content_methods.content_method@">Unregister</a>
      ]
      </if>
      <else>&nbsp;</else>
    </td>
  </tr>
  </multiple>

</else>

</table>
</td>
</tr>

</table>

<include src="../../table-footer">
