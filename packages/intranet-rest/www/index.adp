<if @xml_p@>@xml;noquote@</if>
<else>

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
	<a href="http://www.project-open.org/en/list_object_types">object types</a> that are exposed
	through this REST Web-Service API, together with the implementation
	status of CRUL (Create, Read, Update and List) operations (see below) for each object type and a 
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
		<b>CRUL Status</b>:<br>
		Lists the implemented REST API operations available for this
		object type:
		<ul>
		<li>C - Create
		<li>R - Read
		<li>U - Update
		<li>L - List
		</ul>
	<li>
		<b>Wiki</b>:<br>
		A link (if available) to the &#93;project-open&#91; 
		Documentation Wiki page for this object type.
	</ul>
	</p>
	
	<br>
	<h1>Authentication</h1>
	
	<p>
	Authentication of the REST API is managed per user, applying the same 
	access right as with the Web GUI. A user will only see the objects he or
	she would also see via the Web GUI. 
	This mechanism includes the case of external users including 
	customers and providers to access to ]po[.
	</p>
	
	<p>
	The &#93;project-open&#91; REST API supports the following 
	authentication mechanisms:
	</p>
	<ul>
	<li>
		<b>Basic HTTP Authentication</b>:<br>
		&#93;po&#91; accepts standard username/password combinations.<br>
		Please note that the username is <i>not</i> the user's email.
		You can find out about a user's username either in the user's
		home page or in the cc_users.username field
		(you need to set the parameter EnableUsersUsernameP to 1).
	<li>
		<b>Auto-Login Token</b>:<br>
		An auto-login token is a hashed password.
		To determine a user's auto-login token please visit the URL
		<a href="/intranet-rest/auto-login">/intranet-rest/auto-login</a>.
		This page will return an auto-login token for a user who has
		authenticated via Cookie or Basic Auth.
	<li>
		<b>Cookie Authentication</b>:<br>
		The standard OpenACS authentication allows you to explore the
		REST API interactively in HTML format. The fact that you see
		this page right now is due to cookie authentication.
		However, cookie authentication is not very useful for
		machine-machine communication...
	</ul>
	
	<br>
	<h1>XML and HTML Output Formats</h1>
	<p>
	Every page in the REST API understands the optional parameter "&amp;format=&lt;format&gt;"
	where format can be one of {html|xml}. The default format for cookie authentication is 
	html, while the default for Basic HTTP and auto-login authentication is xml.
	
	</td>
	</tr>
	</table>
	
</else>
