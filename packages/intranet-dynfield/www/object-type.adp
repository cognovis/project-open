<master src="master">

<property name="title">@title@</property>
<property name="context">@context@</property>

<h1>@title@</h1>

<form method=post action=attribute-delete>
<input type=hidden name=return_url value="@return_url@">
<input type=hidden name=object_type value="@object_type@">
<table class="list">

  <tr class="list-header">
    <th class="list-narrow">#intranet-dynfield.Attribute_Name#</th>
    <th class="list-narrow">#intranet-dynfield.Pretty_Name#</th>
    <th class="list-narrow">#intranet-dynfield.Located# <br>#intranet-dynfield.in_Table#</th>
    <th class="list-narrow">Widget<br>Name</th>
    <th class="list-narrow">Attrib<br>Type</th>
    <th class="list-narrow">Table<br>Type</th>
    <th class="list-narrow">Y-Pos</th>
    <th class="list-narrow">Also<br>Hard<br>Coded</th>
    <th class="list-narrow">#intranet-dynfield.Del#</th>
  </tr>

  <multiple name=attributes>
  <if @attributes.rownum@ odd>
    <tr class="list-odd">
  </if> <else>
    <tr class="list-even">
  </else>

    <td class="list-narrow">
	<a href="attribute-new?attribute_id=@attributes.im_dynfield_attribute_id@">
	  @attributes.attribute_name@
	</a>
    </td>
    <td class="list-narrow">
	@attributes.pretty_name@
    </td>
    <td class="list-narrow">
	@attributes.table_name@
    </td>
    <td class="list-narrow">
	<a href="widget-new?widget_id=@attributes.widget_id@">
	  @attributes.widget_name@
	</a>
    </td>
    <td class="list-narrow">
	@attributes.attribute_data_type@
    </td>
    <td class="list-narrow">
	@attributes.table_data_type@
    </td>
    <td class="list-narrow">
	@attributes.pos_y@
    </td>
    <td class="list-narrow">
	@attributes.also_hard_coded_p@
    </td>
    <td class="list-narrow">
	<input type=checkbox name=attribute_ids value="@attributes.im_dynfield_attribute_id@">
    </td>

  </tr>
  </multiple>

  <tr valign=top>
    <td colspan=8 align=left>

<ul>
<li><a href="attribute-new?form_mode=edit&object_type=@object_type@&action=completely_new">#intranet-dynfield.lt_Add_a_completely_new_#</a></li>
<li><a href="attribute-new?form_mode=edit&object_type=@object_type@&action=already_existing">#intranet-dynfield.lt_Add_an_attribute_that#</a></li>
</ul>

    </td>
    <td align=right>
      <input type=submit value="Del">
    </td>
  </tr>
</table>
</form>

<br>


<h1>#intranet-dynfield.lt_Extension_Tables_for_#</h1>
<form method=post action=extension-table-delete>
<input type=hidden name=object_type value="@object_type@">
<input type=hidden name=return_url value="@return_url@">
<table class="list">
  <tr class="list-header">
    <th class="list-narrow">#intranet-dynfield.Table_Name#</th>
    <th class="list-narrow">#intranet-dynfield.ID_Column#</th>
    <th class="list-narrow">#intranet-dynfield.Del#</th>
  </tr>
  <multiple name=extension_tables>
  <if @extension_tables.rownum@ odd>
    <tr class="list-odd">
  </if> <else>
    <tr class="list-even">
  </else>
    <td class="list-narrow">
	@extension_tables.table_name@
    </td>
    <td class="list-narrow">
	@extension_tables.id_column@
    </td>
    <td class="list-narrow">
	<input type=checkbox name=extension_tables value="@extension_tables.table_name@">
    </td>
  </tr>
  </multiple>
  <tr valign=top>
    <td colspan=2 align=right>

<ul class="action-links">
<li><a href="extension-table-new?object_type=@object_type@&return_url=@return_url_encoded;noquote@">#intranet-dynfield.lt_Add_a_new_extension_t#</a>
</ul>

    </td>
    <td colspan=1 align=right>
      <input type=submit value="Del">
    </td>
  </tr>
</table>
</form>


<br>


<h1>#intranet-dynfield.Dynfield_Layout#</h1>
<listtemplate name="layout_list"></listtemplate>

<br>

<h1>#intranet-dynfield.Dynfield_Actions#</h1>
<ul class="action-links">
<!-- <li><a href="layout-manager?object_type=@object_type@">#intranet-dynfield.Layout_Manager#</a>:<br> -->
<li><a href="attribute-type-map?object_type=@object_type@">Attribute-Type-Map</a>:<br>
	You need to configure when to show a DynFields, depending on the 
	object's sub-type. <br>
	For example, you can define that
	a company of sub-type "Customer" should exhibit an <br>
	"A-B-C" classification field, 
	while a company of sub-type "Partner" may exhibit a <br>
	"Partner Status" field.
<li><a href="permissions?object_type=@object_type@">Attribute Permissions</a>:<br>
	You need to configure who should be able to read or write a DynField.
</ul>


