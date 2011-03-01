<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<br>&nbsp;<br>
<h1>Login Status</h1>
<p>
The <span class=brandsec>]</span><span class=brandfirst>project-open</span><span class=brandsec>[</span>
server responded:
</p>

<table cellspacing=1 cellpadding=1>
<tr class=rowtitle>
  <td class=rowtitle>Field</td>
  <td class=rowtitle>Value</td>
</tr>
<tr>
  <td class=roweven>Login status</td>
  <td class=roweven>@login_status@</td>
</tr>
</table>


<if @ctr@ ne 0>

<br>&nbsp;<br>
<h1>Automatic Software Updates</h1>
<ul>
<li>Please <b>DON'T UPDATE</b> before having read completely
the <a href="index">instructions</a>.<br> 
<li>You need to perform a complete backup before each and every update.
</ul>

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
<p>&nbsp;</p>

</if>

