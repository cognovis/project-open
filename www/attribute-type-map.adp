<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<h1>@page_title;noquote@</h1>

<b>Explanation</b>
<ul>
<li>N - D - E
<li>First = "None" - Don't display the field
<li>Second = "Display" - "Read only" mode
<li>Third = "Edit" - Edit the field
</ul>

<form action=attribute-type-map-2 method=POST>
<%= [export_form_vars acs_object_type return_url] %>

<table>
@header_html;noquote@
@body_html;noquote@
<tr>
  <td></td>
  <td colspan=99><input type=submit></td>
</tr>
</table>
</form>


