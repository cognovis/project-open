<master src="../../intranet-core/www/admin/master">
<property name="title">Automatic Software Update Service</property>
<property name="main_navbar_label">admin</property>
<property name="admin_navbar_label">software_updates</property>


<table width="100%">
<tr valign=top>
  <td width="60%">

<h1>Automatic Software Update Service</h1>


The Automatic Software Update Service (ASUS) automatically keeps your @po;noquote@ 
system up to date and fixes security issues. 
All software has bugs, so it is highly recommended to update a production system
atleast once every month.


<h4>Free Manual Updates</h4>

For manual updates please check the "Latest News" section at our 
<a href="http://sourceforge.net/projects/project-open/">SourceForge</a> community
for new versions and follow the update instructions.


<h4>Register for ASUS</h4>

The ASUS service is a convenience service that automates updates. 
The ASU service is <i>not free</i>. 
Please read <a href=http://www.project-open.com/en/services/#asus>Overview</a> 
and the <a href=disclaimer>Disclaimer</a>.
Then <a href="http://www.project-open.net/register/user-new?return_url=/intranet-cust-projop/asus/new-asus"
>Register your Account</a>. We will contact you for details.


<h4>Update your System</h4>


<ol>
<li><b>Perform a backup</b>:<br>
    Please perform a <a href="/intranet/admin/backup/">database backup</a> and
    save your source code at C:\ProjectOpen\projop\packages (Win32)
    or /web/projop/packages (Linux) using zip or tar.
    <br>&nbsp;

<li><b>Test your ASUS account</b>:<br>
    Login manually at <a href="http://www.project-open.net/">http://www.project-open.net/</a>
    using your ASUS email/password.
    <br>&nbsp;

<li><b>Check for ASUS updates</b>:<br>
    Check for the <a href=load-update-xml>latest software updates</a>.
    You will see a menu of the available updates. Please use the same email/password
    as in the previous step.
    <br>&nbsp;

<li><b>Decide whether you want to update</b>:<br>
    Please check the forum links to decide whether you want to upgrade. 
    You don't have to follow each and every upgrade.
    <br>&nbsp;

<li><B>Upgrade your system</b>:<br>
    Pressing the "Update" button will update your @po;noquote@ code. 
    <br>&nbsp;

<li><b>Update your database</b>:<br>
    Please use the <a href="/acs-admin/apm/packages-install">Package Manager</a>
    to update the database. Please check <b>only</b> the "Update" options.
    Please don't perform any "Install" options unless you know what you are doing.
    <br>&nbsp;

<li><b>Restart your server</b>:<br>
    Please use the <a href="/acs-admin/server-restart">Server Restart</a>
    page to restart the server.
    <br>&nbsp;
</ol>

</td>
<td>

	<table width="100%">
	<tr><td>
	<%= [im_table_with_title "Quick Links" "
		<ul>
		<li><a href=load-update-xml>Check for Latest Software Updates</a></li>
		<li><a href=\"/acs-admin/apm/packages-install\">Install Packages</a></li>
		<li><a href=\"/acs-admin/server-restart\">Server Restart</a></li>
		</ul>
	"] %>
	
	</td></tr>
	</table>

</td>
</tr>
</table>



