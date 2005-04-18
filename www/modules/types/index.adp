<master src="../../master">
<property name="title">@page_title;noquote@</property>

<if @refresh_tree@ eq t>
  <script language=javascript>
    top.treeFrame.setCurrentFolder('@mount_point@', '@refresh_id@', '@parent_id@');
  </script> 
</if>

<h2>@page_title@</h2>

<table border=0 cellpadding=4 cellspacing=0 width="95%">
<tr>
  <td nowrap align=left>
    <font size=-1>
    <b>Inheritance:</b>&nbsp;
    <if @content_type_tree:rowcount@ eq 0>
      <a href="index?id=content_revision">Basic Item</a>
    </if>
    <else>
      <multiple name=content_type_tree>
        <if @content_type_tree.rownum@ ne 1> : </if>
        <if @content_type_tree.object_type@ eq @content_type@>
          @content_type_tree.pretty_name@
        </if>
        <else>
          <a href="index?id=@content_type_tree.object_type@&mount_point=types&parent_id=@content_type_tree.parent_type@">
            @content_type_tree.pretty_name@
          </a>
        </else> 
      </multiple>
    </else>
    </font>
  </td>
  <td align=right>
    <include src="../../bookmark" 
             mount_point="@mount_point;noquote@" 
            id="@content_type;noquote@">&nbsp;
    <font size=-1>Add this content type to the clipboard.</font>
  </td>
</tr>
</table>

<p>


<table cellpadding=1 cellspacing=0 border=0 width="100%">
<tr bgcolor=#000000><td>

<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr bgcolor=#eeeeee><td>

<!-- Tabs begin -->

<tabstrip id=type_props></tabstrip>

</td></tr>

<tr bgcolor=#FFFFFF><td align=center>

<!-- Tabs end -->

<br>
<table cellspacing=0 cellpadding=0 border=0 width="95%">

<if @type_props.tab@ eq attributes>
  
  <tr><td>


    <!-- ATTRIBUTES TABLE -->
    <include src="../../table-header" title="Attributes">
    <table cellspacing=0 cellpadding=4 border=0 width="100%">
    <if @attribute_types:rowcount@ eq 0>
      <tr bgcolor="#99CCFF">
	<td><em>This content type has no attributes.</em></td>
      </tr>
    </if>
    <else>

      <tr bgcolor="#99ccff">
	<th>Attribute Name</th>
	<!-- <th>Description Key</th> -->
	<!-- <th>Description</th>     -->
	<th>Object Type</th>
	<th>Data Type</th>
	<th>Widget</th>
	<th>&nbsp;</th>
      </tr>

      <multiple name=attribute_types>
	<if @attribute_types.rownum@ odd><tr bgcolor="#FFFFFF"></if>
	<else><tr bgcolor=#EEEEEE></else>
	  <td>@attribute_types.attribute_name_pretty@</td>
	  <td>@attribute_types.pretty_name@</td>
	  <td>@attribute_types.datatype@</td>
	  <td>
	    <if @attribute_types.widget@ nil>None</if>
	    <else>@attribute_types.widget@</else>
	  </td>
	  <td align=right>
	    <if @can_edit_widgets@ eq t>
	      <if @attribute_types.object_type@ eq @content_type@
		and @attribute_types.object_type@ ne content_revision>
		<if @attribute_types.widget@ nil>
		  <a href="widget-register?attribute_id=@attribute_types.attribute_id@&content_type=@content_type@">Register Widget</a>
		</if>
		<else>
		  [ <a href="widget-register?attribute_id=@attribute_types.attribute_id@&content_type=@content_type@&widget=@attribute_types.widget@">Edit Widget</a> | 
		  <a href="widget-unregister?attribute_id=@attribute_types.attribute_id@&content_type=@content_type@">Unregister Widget</a> ]
		</else>
	      </if>
	      <else>&nbsp;</else>
	    </if>
	    <else>&nbsp;</else>
	  </td>
	</tr>
      </multiple>
    </else>
    </table>
    <include src="../../table-footer">
    <p>

    <include src="mime-types" content_type="@content_type;noquote@">
    <p>

    <include src="content-method" content_type="@content_type;noquote@">
  </td></tr>
</if>

<if @type_props.tab@ eq relations>
  <tr><td>
    <include src="relations" type=@content_type;noquote@>
  </td></tr>
</if>

<if @type_props.tab@ eq templates>
  <tr><td>
    <include src="../../table-header" title="Registered Templates">
    <table cellspacing=0 cellpadding=4 border=0 width="100%">

    <if @type_templates:rowcount@ eq 0>
      <tr bgcolor="#99CCFF">
	<td>
	  <em>There are no templates registered to this content type.</em>
	</td>
      </tr>
    </if>
    <else>

      <tr bgcolor="#99CCFF">
	<th>Template Name</th>
	<th>Path</th>
	<th>Content Type</th>
	<th>Context</th>
	<th>&nbsp</th>
	<th>&nbsp</th>
      </tr>

      <multiple name=type_templates>
      <if @type_templates.rownum@ odd><tr bgcolor="#FFFFFF"></if>
      <else><tr bgcolor="#EEEEEE"></else>
	<td>@type_templates.name@</td>
	<td>@type_templates.path@</td>
	<td>@type_templates.pretty_name@</td>
	<td>@type_templates.use_context@</td>
	<td>
	  <if @type_templates.is_default@ eq t>Default</if>
	  <else>
	    <if @user_permissions.cm_write@ eq t>
	      <a href="set-default-template?template_id=@type_templates.template_id@&context=@type_templates.use_context@&content_type=@content_type@">Make this the default</a>
	    </if>
	    <else>&nbsp;</else>
	  </else>
	</td>

	<td align=right>
	  <if @user_permissions.cm_write@ eq t>
	    <a href="unregister-template?template_id=@type_templates.template_id@&context=@type_templates.use_context@&content_type=@content_type@">Unregister</a>
	  </if>
	  <else>&nbsp;</else>
	</td>
      </tr>
      </multiple>
    </else>
    </table>
    <include src="../../table-footer" footer="@footer;noquote@">
  </td></tr>
</if>

<if @type_props.tab@ eq permissions>
  <tr><td>
    <include src="../permissions/index" 
      object_id=@module_id;noquote@ 
      mount_point="types" 
      return_url="@return_url;noquote@" 
      passthrough="@passthrough;noquote@">
  </td></tr>
</if>

</table>

<br>

</td></tr>
</table>

</td></tr></table>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>
