<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<h1>@page_title@</h1>

Login Status:
<ul>
<li>@login_status@

<if @login_message@ ne "">
<li>@login_message@
</if>

</ul>

<if @ctr@ ne 0>
<table cellspacing=2 cellpadding=2>
<tr class=rowtitle>
  <td class=rowtitle align=middle>Update</td>
  <td class=rowtitle align=middle>Package</td>
  <td class=rowtitle align=middle>Package Version</td>
  <td class=rowtitle align=middle>P/O Version</td>
  <td class=rowtitle align=middle>Release<br>Date</td>
  <td class=rowtitle align=middle>Forum</td>
  <td class=rowtitle align=middle>Update?</td>
  <td class=rowtitle align=middle>What's New</td>
</tr>
@version_html;noquote@
</table>

</if>

<h1>Already Installed Packages</h1>

@table;noquote@


