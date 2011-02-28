<if 1 ne @nomaster_p@>
<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
</if>

<h1>@page_title;noquote@</h1>



<if 1 ne @nomaster_p@>
<form action="attribute-type-map" method=POST>
<%= [export_form_vars object_type return_url] %>
	<table>
	<tr class=rowtitle><td class=rowtitle align=center colspan=2>Filter Subtypes</td></tr>
	<tr>
	  <td class=form-label>Object Subtype</td>
	  <td class=form-widget><%= [im_category_select -include_empty_p 1 $category_type object_subtype_id $object_subtype_id] %></td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget><input type=submit></td>
	</tr>
	</table>
</form>
</if>


<b>Explanation</b>
<ul>
<li>N - D - E
<li>First = "None" - Don't display the field
<li>Second = "Display" - "Read only" mode
<li>Third = "Edit" - Edit the field
</ul>


<form action="attribute-type-map-2" method=POST>
<%= [export_form_vars acs_object_type object_subtype_id return_url] %>

<table>
@header_html;noquote@
@body_html;noquote@
<tr>
  <td></td>
  <td colspan=99><input type=submit></td>
</tr>
</table>

</form>


