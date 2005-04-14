<master>
<property name="title">@page_title@</property>

<p/>

<include src="../../../cms/www/bookmark" mount_point="@mount_point@" id="@parent_id@">

@page_title;noquote@ 

<p/>

&nbsp;&nbsp;&nbsp;
<if @info.description@ not nil>@info.description@</if>
<else>No description</else>

<p/>

<include src="../../../cms/www/modules/sitemap/ancestors" item_id=@parent_id@ 
  index_page_id=@index_page_id@ 
  mount_point=@mount_point@>

<p/>

<listtemplate name="folder_items"></listtemplate>

<p/>

<br/>

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
</if>

<if @mount_point@ eq sitemap>
  <if @num_revision_types@ gt 0>
    <formtemplate id=add_item>
    <img src="../../resources/Add24.gif" width=24 height=24 border=0>
    <formwidget id=folder_id>
    <formwidget id=mount_point>
    Add a new <formwidget id=content_type> under this @what@.
    <input type=submit value="Add Item">
    </formtemplate><br>
  </if>
</if>

<br>

<p>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>







