<if @view_mode@ eq "all">
	<table cellpadding=2 cellspacing=2 class="table-display" width="600px" bgcolor="#999999">
	<tr valign=top class="table-header">
	  <th colspan=2>Message</th>
	</tr valign=top>
	<tr valign=top>
	  <td class="odd">From</td>
	  <td class="odd">@from@</td>
	</tr valign=top>
	<tr valign=top>
	  <td class="odd">To</td>
	  <td class="odd">@to@</td>
	</tr valign=top>
	<tr valign=top>
	  <td class="odd">Sent</td>
	  <td class="odd">@send_date@</td>
	</tr valign=top>
	<tr valign=top>
	  <td class="odd">Subject</td>
	  <td class="odd">@subject@</td>
	</tr valign=top>
	<tr valign=top>
	  <td class="odd">Body</td>
	  <td class="odd"><pre>@body@</pre></td>
	</tr> 

	</table>
</if>

<if @view_mode@ eq "body">
<% 

	set body "<pre>[string trimleft $body]</pre>"
	append body $attachment_html
	doc_return 200 "text/html" $body 
%>
</if>

<if @view_mode@ eq "noBody">
			        <table cellpadding=2 cellspacing=2 class="table-display" width="600px" bgcolor="#cccccc">
<!--
			        <tr valign=top class="table-header">
			          <th colspan=2>Message</th>
			        </tr>
-->
			        <tr valign=top>
			          <td class="odd">From:</td>
			          <td class="odd">@from@</td>
			        </tr>
			        <tr valign="top">
			          <td class="odd">To:</td>
			          <td class="odd">@to@</td>
			        </tr valign=top>
			        <tr>
			          <td class="odd">Sent:</td>
			          <td class="odd">@send_date@</td>
			        </tr>
			        <tr valign=top>
			          <td class="odd">Subject:</td>
			          <td class="odd">@subject@</td>
			        </tr>
			        <tr valign=top>
			          <td class="odd" colspan="2">Body:</td>
			        </tr>
			        </table>
</if>