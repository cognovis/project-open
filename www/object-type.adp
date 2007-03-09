<master>

<property name="title">@title@</property>
<property name="context">@context@</property>



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
	<input type=checkbox name=attribute_ids value="@attributes.im_dynfield_attribute_id@">
    </td>

  </tr>
  </multiple>

  <tr>
    <td colspan=99 align=right>
      <input type=submit value="Del">
    </td>
  </tr>
</table>
</form>
<ul class="action-links">
<li><a href="attribute-new?object_type=@object_type@&action=already_existing">#intranet-dynfield.lt_Add_an_attribute_that#</a>
<li><a href="attribute-new?object_type=@object_type@&action=completely_new">#intranet-dynfield.lt_Add_a_completely_new_#</a>
<li><a href="layout-manager?object_type=@object_type@">#intranet-dynfield.Layout_Manager#</a></li>
</ul>


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

  <tr>
    <td colspan=99 align=right>
      <input type=submit value="Del">
    </td>
  </tr>
</table>
</form>

<ul class="action-links">
<li><a href="extension-table-new?object_type=@object_type@&return_url=@return_url_encoded;noquote@">#intranet-dynfield.lt_Add_a_new_extension_t#</a>
</ul>


<p>

<if @generate_interfaces@ eq "1" and @attributes:rowcount@ gt "0">
	<if @show_interfaces_p@ eq "1">
		<br/>
		@show_hidde_link;noquote@
		<br/>
		<h1>#intranet-dynfield.dbi_interfaces#</h1>

		<h5>#intranet-dynfield.dbi_headers#</h5>
		@dbi_interfaces;noquote@

		<br/>

		<h5>#intranet-dynfield.dbi_inserts#</h5>
		@dbi_inserts;noquote@

		<br/>

		<h5>#felxbase.dbi_procs#</h5>
<pre>
@dbi_procs;noquote@
</pre>
	</if>
	<br>
	@show_hidde_link;noquote@
</if>