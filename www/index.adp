<master src="master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>


<table width="70%">
<tr>
<td>

<h2>DynField Administration Pages</h2>
<ul>
  <li><a href="object-types"><b>Object Types</b></a>:<br>
	The main DynField configuration page. Allows you to define DynFields
	per object type.<br>
	
  <li><a href="permissions"><b>Permissions</b></a>:<br>
	Defines who can read or write a DynField.
	
  <li><a href="widgets"><b>Widgets</b></a><br>
	DynField-Widgets are pieces of HTML code to display the value of
	a dynfield, together with the definition of a value range. 
	
  <li><a href="widget-examples"><b>Widget Examples</b></a>:<br>
	Shows a preview of all available widgets.
	
	
  <li><a href="/doc/intranet-dynfield"><b>Documentation</b></a>:<br>
	In-detail documentation of the DynField system.
	<br>&nbsp;

</ul>

<H2>Soon Available</H2>

<ul>
  <li><a hhref="permissions_per_object_type"><b>Configuration per Object Sub-Type</b></a>:<br>
	Allows you to configure DynFields depending on 
	an object's sub-type. For example, you can define that
	a company of sub-type "Customer" should exhibit an 
	"A-B-C" classification field, 
	while a company of sub-type "Partner" may exhibit a "Partner Status"
	field.

  <li><a hhref="permissions_per_object_status"><b>Configuration per Object Status</b></a>:<br>
	Allows you to display DynFields depending on 
	an object's status. For example, you can show a "Budget"
	field in read/write mode during the "Project definition" status
	of a project, while making this field read-only in all futher
	project stati. 

  <li><a hhref="export.xml"><b>Export</b></a>:<br>
	Export the DynField configuration to an XML file
	
  <li><a hhref="upload"><b>Import</b></a>:<br>
	Imports a DynField configuration from an XML file

	
</ul>

</td>
</tr>
</table>
