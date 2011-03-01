<table>
<form action=save method=post>
<%= [export_vars -form {return_url filter_year include_remaining_p}] %>
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

