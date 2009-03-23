<master src="master">
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">admin</property>

<if @missing_dynfield_object_types@ ne "">
<p><font color=red>
There are invalid DynFields in the system for the following object types.<br>
These DynFields won't be shown.<br>
<ul>@missing_dynfield_object_types;noquote@</ul>
Please check these DynFields and make sure that every DynField has a "Pos-Y" value<br>
by editing the DynField and specifying a value. You can use '0' as a default.
</font></p><br>&nbsp;<br>
</if>

<ul>
  <li><a href="object-types"><b>Object Types</b></a>:<br>
	The main DynField configuration page. Allows you to define DynFields
	per object type.<br>
	
  <li><a href="permissions"><b>Permissions</b></a>:<br>
	Defines who can read or write a DynField.

  <li><a href="@param_url;noquote@"><b>Parameters</b></a><br>
	
  <li><a href="widgets"><b>Widgets</b></a><br>
	DynField-Widgets are pieces of HTML code to display the value of
	a dynfield, together with the definition of a value range. 
	
  <li><a href="widget-examples"><b>Widget Examples</b></a>:<br>
	Shows a preview of all available widgets.
	
	
  <li><a href="/doc/intranet-dynfield"><b>Documentation</b></a>:<br>
	In-detail documentation of the DynField system.

</ul>
