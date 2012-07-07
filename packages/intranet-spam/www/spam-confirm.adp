<!-- spam confirmation page -->

<master src=../../intranet-core/www/master>
<property name="title">Confirm Spam</property>
<property name="context">@context;noquote@</property>

<h1>Confirm Spam</h1>

<p>
You are about to send the following message to
<a href="@spam_show_users_url@">@num_recipients@ user(s)</a>.
</p>

<p>
The mail will be sent on @pretty_date@ at @send_time.time@ @send_time.ampm@
</p>

<form action="@confirm_target@" method="post" enctype="multipart/form-data">
@export_vars;noquote@
<table cellspacing=1 border=0 cellpadding=1>

	<tr class=roweven>
	  <td>User List:</td>
	  <td>@selector_short_name@</td>
	</tr>
	<tr class=rowodd>
	  <td>Subject:</td>
	  <td>@subject_subs@</td>
	</tr>
	<tr class=roweven>
	  <td>Posted in</td>
	  <td><A href="@object_rel_url@">@object_name@</A></td>
	</tr>
	<tr  class=rowodd>
	  <td>Posted by:</td>
	  <td>@spam_sender@</td>
	</tr>
	<tr class=roweven>
	  <td>Posting Date:</td>
	  <td>@pretty_date@</td>
	</tr>
<if @body_plain_subs@ not nil>
	<tr class=rowplain>
	<td>Plain Text</td>
	<td>
	  <table cellspacing=2 cellpadding=2 border=0><tr><td>
	  <pre>@body_plain_subs@</pre>
	  </td></tr></table>
	</td></tr>
</if>
<if @body_html_subs@ not nil>
	<tr class=rowplain>
	<td>HTML Text</td>
	<td>
	  <table cellspacing=2 cellpadding=2 border=0><tr><td>
	  <pre>@body_html_subs@</pre>
	  </td></tr></table>
	</td></tr>
</if>
	<tr class=rowplain>
		<td>Attachment</td>
		<td>
	       <input type="file" name="upload_file">
	    </td>
	</tr>
	<tr  class=rowodd>
	  <td>Actions</td>
	  <td>
	    <input type="submit" value="Confirm">
	  </td>
	</tr>
</table>
</form>










