<master src="../../master">
<property name="title">@page_title;noquote@</property>
<h2>@page_title@</h2>



<include src="../../table-header" title="Registered Content Types">
<table cellspacing=0 cellpadding=4 border=0 width="100%">

<if @content_types:rowcount@ eq 0>
  <tr bgcolor="#99CCFF">
    <td><em>There are no content types registered to this folder.</em></td>
  </tr>
</if>
<else>

  <tr bgcolor="#99CCFF">
    <th align=left>Content Type</th>
    <th align=left>&nbsp</th>
  </tr>

  <multiple name=content_types>
  <if @content_types.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>
    <td>@content_types.pretty_name@</td>
    <td>
      <if @user_permissions.cm_write@ eq t>
        <a href="type-unregister?folder_id=@folder_id@&type_key=@content_types.content_type@">Unregister this content type</a>
      </if>
      <else>&nbsp;</else>
    </td>
  </tr>
  </multiple>
</else>

</table>

<if @user_permissions.cm_write@ eq t>
  <include src="../../table-footer" footer="@register_marked_content_types;noquote@">
</if>
<else>
  <include src="../../table-footer">
</else>

<p>



<!-- FOLDER OPTIONS TABLE -->

<table cellspacing=0 cellpadding=0 border=0 width="100%">
<tr bgcolor="#FFFFFF"><td>
  <table cellspacing=0 cellpadding=4 border=0 width="100%">
  <tr bgcolor="#FFFFFF">
    <th align=left>Folder Options</th>
  </tr>
  </table>
</td></tr>
<tr><td>
  <formtemplate id="register_types" style="wizard"></formtemplate>
</td></tr>
</table>

<p>





<include src="../permissions/index" object_id="@folder_id;noquote@" 
  mount_point="@mount_point;noquote@" return_url="@return_url;noquote@" passthrough="@passthrough;noquote@">

