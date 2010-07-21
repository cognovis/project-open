<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">projects</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<table width=100%><tr>
<td width=50%></td>
<td>@help;noquote@</td>
</table>

<table>
<form action="/intranet-portfolio-management/department-planner/action" method=POST>
@header_html;noquote@
@first_html;noquote@
@body_html;noquote@
@submit_html;noquote@
</form>
</table>


<if "" ne @error_html@>
<br>
<h1>Errors</h1>
<ul>
@error_html;noquote@
</ul>
</if>

