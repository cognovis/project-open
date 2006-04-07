<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<h1>Login Status</h1>
<p>
The <span class=brandsec>]</span><span class=brandfirst>project-open</span><span class=brandsec>[</span>
server at "@service_url@" responded:
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

<if @login_status@ eq "ok">
  <tr>
    <td class=rowodd>CVS User</td>
    <td class=rowodd>@cvs_user@</td>
  </tr>
  <tr>
    <td class=roweven>CVS Password</td>
    <td class=roweven>@cvs_password@</td>
  </tr>
</if>

<if @login_message@ ne "">
  <tr>
    <td class=rowodd>Login message</td>
      <if @login_status@ eq "ok">
        <td class=rowodd>@login_message@</td>
     </if>
     <else>
       <td class=rowodd><font color=red>@login_message@</font></td>
    </else>
  </tr>
</if>
</table>


<if @ctr@ ne 0>

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


<if @login_status@ eq "ok">
<h1>Installed Packages</h1>

@table;noquote@
</if>



