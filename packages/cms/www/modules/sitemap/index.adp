<master src="../../master">
<property name="title">Folder Listing</property>

<script language=javascript>
  top.treeFrame.setCurrentFolder('@mount_point@', '@original_id@', '@parent_id@');
</script> 

<include src="ancestors" 
  item_id=@id;noquote@ 
  index_page_id=@index_page_id;noquote@ 
  mount_point=@mount_point;noquote@>

<table width="95%" cellspacing=0 cellpadding=4>
<tr>
  <td class=large>
    <b>
    <if @is_symlink@ eq t>
      Symlink to
    </if>
    @info.label@
    </b>
  </td>
</tr>
</table>
<br>

<if @info.description@ not nil>
  @info.description@
</if>
<p>


<if @items:rowcount@ gt 0> 

<!-- pagination context bar -->
<table cellpadding=4 cellspacing=0 border=0 width="95%">
<tr>
  <td align=left width="5%">
    <if @info.previous_group@ not nil>
      <a href="index?id=@id@&@passthrough@&orderby=@orderby@&page=@info.previous_group@">
        &lt;&lt;</a>
      &nbsp;&nbsp;
    </if>
    <if @info.previous_page@ gt 0>
      <a href="index?id=@id@&@passthrough@&orderby=@orderby@&page=@info.previous_page@">
        &lt;</a>
    </if>
    <else>&nbsp;</else>
  </td>

  <td align=center>
  <multiple name=pages>
    <if @page@ ne @pages.page@>
      <a href="index?id=@id@&@passthrough@&orderby=@orderby@&page=@pages.page@">@pages.page@</a>
    </if>
    <else>
      @page@
    </else>
  </multiple>
  </td>

  <td align=right width="5%">
    <if @page@ lt @info.page_count@>
      <a href="index?id=@id@&@passthrough@&orderby=@orderby@&page=@info.next_page@">&gt;</a>
    </if>
    <else>&nbsp;</else>

    <if @info.next_group@ not nil>
      &nbsp;&nbsp;
      <a href="index?id=@id@&@passthrough@&orderby=@orderby@&page=@info.next_group@">
        &gt;&gt;</a>
    </if>
  </td>
</tr>
</table>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
<tr><td>
<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr bgcolor="#99ccff"><td colspan=2>&nbsp</td>
      <th>
        <if @orderby@ ne name>
          <a href="index?id=@id@&@passthrough@&page=@page@">Name</a>
        </if>
        <else>Name</else>
      </th>
      <th>
        <if @orderby@ ne size>
          <a href="index?id=@id@&orderby=size&@passthrough@&page=@page@">
            Size</a>
        </if>
        <else>Size</else>
      </th>

      <th>
        <if @orderby@ ne publish_date>
	  <a href="index?id=@id@&@passthrough@&orderby=publish_date&page=@page@">Publish Date</a>
        </if>
        <else>Publish Date</else>
      </th>
      <th>
        <if @orderby@ ne object_type>
          <a href="index?id=@id@&@passthrough@&orderby=object_type&page=@page@">Type</a>
        </if>
        <else>Type</else>
      </th>
      <th>
        <if @orderby@ ne last_modified>
	  <a href="index?id=@id@&@passthrough@&orderby=last_modified&page=@page@">Last Modified</a>
        </if>
        <else>Last Modified</else>
      </th>
  </tr>



  <multiple name=items>
    <if @items.is_index_page@ eq t><tr bgcolor="#FFFFCC"></if>
    <else>
      <if @items.rownum@ odd><tr bgcolor="#FFFFFF"></if>
      <else><tr bgcolor="#EEEEEE"></else>
    </else>

      <td nowrap height=12>
        <include src="../../bookmark" 
                 mount_point="@mount_point;noquote@" 
                 id="@items.item_id;noquote@">&nbsp;
      </td>
      <td>
	<img width=24 height=24 
	     src="../../resources/@items.icon@.gif" border=0>
      </td>
      <td>
        <if @mount_point@ eq templates>
          <if @items.object_type@ eq content_item>
            <a href="../templates/template?template_id=@items.item_id@">
              @items.title@
            </a>
	  </if>
          <else>
            <a href="@items.link@">@items.title@</a>
          </else>
        </if>
        <else>
          <a href="@items.link@">@items.title@</a>
        </else>
      </td>
      <td>
        <if @items.object_type@ eq content_folder><center>-</center></if>
        <else>@items.file_size@ K</else>
      </td>
      <td align=center>
	<if @items.publish_date@ nil>-</if>
        <else>@items.publish_date@</else>
      </td>
      <td>
        <if @items.content_type@ not nil>@items.content_type@</if>
        <else>&nbsp;</else>
      </td>
      <td>@items.last_modified_date@</td>
    
    </tr> 
  </multiple>

</table>

</td></tr>

</table>

</if>
<else>
  <p><em>This folder is empty.</em></p>
</else>

  </table></td></tr>
</table>

<br>
<hr>

<p>
<if @symlinks:rowcount@ gt 0>
  <b>Links to this folder</b>: 

  <table border=0 cellpadding=4 cellspacing=0>
  <multiple name=symlinks>
    <tr><td>
      <a href="index?id=@symlinks.id@">
        <img src="../../resources/shortcut.gif" border=0>
        @symlinks.path@ 
      </a>
    </td></tr>
  </multiple>
  </table>
  <br>
  <hr>
</if>


<a href="attributes?folder_id=@id@&mount_point=@mount_point@">
  <img src="../../resources/Add24.gif" width=24 height=24 border=0>
  Folder attributes...
</a>
<br>

<if @id@ not nil>

  <if @is_symlink@ eq f>
    <a href="delete?id=@id@&@passthrough@">
      <img src="../../resources/Delete24.gif" width=24 height=24 border=0>
      Delete
    </a> 
    this @what@
  </if>
  <else>
    <a href="../types/content_symlink/delete?id=@original_id@&@passthrough@">
      <img src="../../resources/Delete24.gif" width=24 height=24 border=0>
      Delete
    </a> 
    this @what@
  </else>
  <br>

  <if @user_permissions.cm_write@ eq t>
    <a href="rename?item_id=@id@&@passthrough@">
      <img src="../../resources/Edit24.gif" width=24 height=24 border=0>
      Rename
    </a> 
    this @what@ 
  </if>
  <br>
</if>


<if @user_permissions.cm_write@ eq t>
  <img src="../../resources/Copy24.gif" width=24 height=24 border=0>

  <if @symlinks_allowed@ eq "t">
    <a href="move?id=@id@&@passthrough@">Move</a>,
    <a href="copy?id=@id@&@passthrough@">Copy</a> or 
    <a href="symlink?id=@id@&@passthrough@">Link</a> 
  </if>
  <else>
    <a href="move?id=@id@&@passthrough@">Move</a> or
    <a href="copy?id=@id@&@passthrough@">Copy</a>
  </else>
  marked items to this @what@.<br>


  <!-- DELETE MARKED ITEMS LINK -->
  <img src="../../resources/Delete24.gif" width=24 hieght=24 border=0>
  <a href="delete-items?id=@id@&@passthrough@">Delete</a>
  marked items.
</if>
<br>

<if @subfolders_allowed@ eq "t">
  <a href="create?parent_id=@id@&mount_point=@mount_point@">
    <img src="../../resources/Open24.gif" width=24 height=24 border=0>
    Create a new folder
  </a> 
  within this @what@.
</if>
<br>

<if @mount_point@ eq sitemap>
  <if @num_revision_types@ gt 0>
    <formtemplate id=add_item>
    <img src="../../resources/Add24.gif" width=24 height=24 border=0>
    <formwidget id=id>
    <formwidget id=mount_point>
    Add a new <formwidget id=content_type> under this @what@.
    <input type=submit value="Add Item">
    </formtemplate><br>
  </if>
</if>

<if @mount_point@ eq templates>
  <if @templates_allowed@ eq "t">
    <img src="../../resources/Add24.gif" width=24 height=24 border=0>
    <a href="../templates/template-create?parent_id=@id@">
      Add a template
    </a> 
    to this @what@.
  </if>
</if>
<br>

<p>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>







