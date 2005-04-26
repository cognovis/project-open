<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<h1>Automatic Software Updates - Login</h1>
The <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
server at "@service_url@" responded:
<ul>
<li>Login status:<br> @login_status@
    <br>&nbsp;
<if @login_message@ ne "">
<li>Login message:<br>@login_message@
    <br>&nbsp;
</if>
</ul>


<h1>Automatic Software Updates</h1>
<ul>
<li>Please <b>DON'T UPDATE</b> before having read completely
the <a href="index">instructions</a>.<br> 
<li>You need to perform a complete backup before each and every update.
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
<p>&nbsp;</p>
</if>


<if @login_status@ eq "ok">
<h1>Installed Packages</h1>

@table;noquote@
</if>



