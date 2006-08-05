<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>

<h1>@page_title@</h1>


<table cellpadding=1 cellspacing=0 border=0>
<tr>
  <td>Status:</td>
  <td>@status@</td>
</tr>
<if "" ne @error@>
	<tr>
	  <td>Error:</td>
	  <td>@error@</td>
	</tr>
</if>
<else>
	<tr>
	  <td>Object Info:</td>
	  <td>@result;noquote@</td>
	</tr>
</else>
</table>

