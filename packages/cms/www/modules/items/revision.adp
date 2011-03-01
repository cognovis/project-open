<master src="../../master">
<property name="title">@page_title;noquote@</property>
<h2>@page_title@</h2>


<h4>Content Type: @content_type@</h4>

<if @live_revision_p@ eq 1>
  This revision is live. &nbsp;
  <if @user_permissions.cm_item_workflow@ eq t>
    <a href="unpublish?item_id=@item_id@">Unpublish</a>
  </if>
</if>
<else>
  <if @user_permissions.cm_item_workflow@ eq t and @is_publishable@ eq t>
    [ <a href="publish?item_id=@item_id@&revision_id=@revision_id@">
      Make this revision live
    </a> ]
  </if>
</else>
<p>

<include src="../../table-header">

<table bgcolor="#6699CC" cellspacing=0 cellpadding=4 border=0 width="100%">
  <tr bgcolor="#99ccff">
    <th>Attribute</th>
    <th>Revision Type</th>
    <th>Value</th>
  </tr>
    
  <tr bgcolor="#FFFFFF">
    <td>Title</td>
    <td>Basic Item</td>
    <td>@one_revision.title@</td>
  </tr>
  <tr bgcolor="#EEEEEE">
    <td>Mime Type</td>
    <td>Basic Item</td>
    <td>@one_revision.mime_type_pretty@</td>
  </tr>
  <tr bgcolor="#FFFFFF">
    <td>Description</td>
    <td>Basic Item</td>
    <td>
      <if @one_revision.description@ nil>&nbsp</if>
      <else>@one_revision.description@</else>
    </td>
  </tr>
  <tr bgcolor="#EEEEEE">
    <td>Publish Date</td>
    <td>Basic Item</td>
    <td>
      <if @one_revision.publish_date_pretty@ nil>&nbsp</if>
      <else>@one_revision.publish_date_pretty@</else>
    </td>
  </tr>

  @revision_attr_html;noquote@

</table>
<include src="../../table-footer">


<include src="../../table-header">
<table bgcolor="#6699CC" cellspacing=0 cellpadding=4 border=0 width="100%">
    
  <tr bgcolor="#99CCFF">
    <th align=left>Content</th>
    <td align=right>
      <if @content_size@ gt 1>&nbsp;</if>
      <else>
        <if @user_permissions.cm_write@ eq t>
	  [<a href="content-add-1?revision_id=@revision_id@">Add</a>]
        </if>
        <else>&nbsp;</else>
      </else>
    </td>
  </tr>
  <tr bgcolor="#FFFFFF">
    <td colspan=2>
      <if @content_size@ gt 1>
	<if @is_text_mime_type@ eq t>@content@</if>
        <else>
          <if @is_image_mime_type@ eq t>
            <img src="content-download?revision_id=@revision_id@">
          </if>
          <else>
	    <a href="content-download?revision_id=@revision_id@">
   	      View Content
            </a>
          </else>
        </else>
      </if>
      <else><i>No Content</i></else>
    </td>
  </tr>
</table>

<include src="../../table-footer">
<p>


<if @user_permissions.cm_write@ eq t>
  <a href="revision-add-1?item_id=@item_id@">
    Add a revision this content item</a>
  <br> 
</if>


<a href="index?item_id=@item_id@">Back to the content item</a>
<p>
