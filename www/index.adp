<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>

<br>
<table cellspacing=5 cellpadding=5>
<tr valign=top>
<td width="48%">
<listtemplate name="object_types"></listtemplate>
</td>
<td width="4%">
&nbsp;&nbsp;
</td>
<td width="48%">

<h1>@page_title@</h1>

<p>
This page lists all &#93;project-open&#91; 
<a href="http://www.project-open.org/documentation/list_object_types">object types</a> that are exposed
through this REST Web-Service API, together with the implementation
status of CRUD operations (see below) for each object type and a 
link to the &#93;project-open&#91; Documentation Wiki.
</p>
<br>
<p>
<ul>
<li>
	<b>Object Type</b>:<br>
	The system name of the object type.<br>
	Click on the link to get a list of all objects of
	this type in this &#93;project-open&#91; instance.
<li>
	<b>Pretty Name:</b><br>
	Human readable name for object type.
<li>
	<b>CRUD Status</b>:<br>
	Lists the implemented REST API operations available for this
	object type:
	<ul>
	<li>C - Create
	<li>R - Read
	<li>U - Update
	<li>D - Delete
	</ul>
<li>
	<b>Wiki</b>:<br>
	A link (if available) to the &#93;project-open&#91; 
	Documentation Wiki page for this object type.
</ul>
</p>

</td>
</tr>
</table>

