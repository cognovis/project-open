<master src="../../master">
<property name="title">Content Item</property>

<include src="../sitemap/ancestors" item_id=@item_id;noquote@>

<p>

<table cellpadding=1 cellspacing=0 border=0 width="100%">
<tr bgcolor=#000000><td>

<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr bgcolor=#eeeeee><td>

<!-- Tabs begin -->

<tabstrip id=item_props></tabstrip>

</td></tr>

<tr bgcolor=#FFFFFF><td align=center>

<!-- Tabs end -->

<br>
<table cellspacing=0 cellpadding=0 border=0 width="95%">


<if @item_props.tab@ eq editing>
  <tr><td>
  <include src="attributes" revision_id="@info.latest_revision;noquote@">
  <p>

  <include src="revisions" item_id="@item_id;noquote@" page="@page;noquote@">
  <p>

  <include src="keywords" item_id="@item_id;noquote@" mount_point="@mount_point;noquote@">  
  <p>
  </td></tr>
</if>

<if @item_props.tab@ eq children>
  <tr><td>
  <include src="children" item_id="@item_id;noquote@">
  <p>

  <include src="related-items" item_id="@item_id;noquote@">
  <p>
  </td></tr>

  <tr><td valign=top><br><br>
  <!-- DELETE MARKED ITEMS LINK -->
  <img src="../../resources/Delete24.gif" width=24 hieght=24 border=0>
  <a href="../sitemap/delete-items?id=@item_id@&@passthrough@">Delete</a>
  marked items.
  </td></tr>
</if>

<if @item_props.tab@ eq publishing>
  <tr><td>

  <include src="publish-status" item_id="@item_id;noquote@">
  <p>


  <include src="templates" item_id="@item_id;noquote@">
  <p>

  <if @user_permissions.cm_item_workflow@ eq t>
    <include src="../workflow/case-status" item_id="@item_id;noquote@">
    <p>
  </if>

  <include src="comments" item_id="@item_id;noquote@">
  <p>
  </td></tr>
</if>

<if @item_props.tab@ eq permissions>
  <tr><td>
  <include src="../permissions/index" object_id="@item_id;noquote@" 
    mount_point="@mount_point;noquote@" return_url="@return_url;noquote@" passthrough="@passthrough;noquote@">
  <p>
  </td></tr>
</if>


</table>

<br>

</td></tr>
</table>

</td></tr></table>

<!-- Options at the end -->

<if @user_permissions.cm_write@ eq t>
  <p>
  <a href="rename?item_id=@item_id@&mount_point=@mount_point@">
    Rename</a> this content item
</if>
<if @user_permissions.cm_write@ eq t>
  <br>
  <a href="delete?item_id=@item_id@&mount_point=@mount_point@" 
     onClick="return confirm('Warning! You are about to delete this content item.');">
     Delete</a> this content item
  <p>
</if>


<p>
