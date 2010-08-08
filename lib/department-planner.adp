
<table>
<form action=save>
<%= [export_vars return_url] %>
@header_html;noquote@
@first_line_html;noquote@
@body_html;noquote@
<tr>
<td colspan=99>
<input type=submit name='Save'>
</td>
</tr>
</table>

<if "" ne @error_html@>
<br>
<h1>Errors</h1>
<ul>
@error_html;noquote@
</ul>
</if>

