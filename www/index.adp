<master src="../../intranet-core/www/admin/master">
<property name="title">Automatic Software Update Client</property>
<property name="main_navbar_label">admin</property>
<property name="admin_navbar_label">software_updates</property>


<table width="100%">
<tr valign=top>
  <td width="50%">

<h1>Automatic Software Updates</h1>


Please follow the steps below for an "automatic sofware update" of your
<span class=brandfirst>Project/</span><span class=brandsec>Open</span>
server.

<ol>

<li><b>Please read</b>:<br>
    <a href=http://www.project-open.com/product/services/software-updates/>
    Software Update Service overview</a> and the 
    <a href=disclaimer>Disclaimer</a>
    <br>&nbsp;

<li><b>Get a
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    account</a></b>:<br>
    Please 
    <a href="http://projop.dnsalias.com/register/user-new">register</a> 
    at the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    server, fill out the registration form and follow the registration
    instructions. If possible, please use the same email address as with
    your corporate
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    server, but choose a different password.
    <br>&nbsp;

<li><b>Test the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    account</b>:<br>
    Login manually at <a href="http://projop.dnsalias.com/">
    http://projop.dnsalias.com/</a>.
    <br>&nbsp;

<li><b>Subscribe to the Automatic Update Service</b>:<br>
    Please use our 
    <a href="http://www.project-open.com/contact/">contact form</a> 
    to request participation in the "automatic software update" service. 
    We will send you an email message once the service is set up for
    you.
    <br>&nbsp;

<li><b>Backup your 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    software</b>:<br>
    Please make a full backup of your
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    source code directory (C:\ProjectOpen\projop\packages in Windows and
    /web/projop/packages in Linux/Unix). You can use ZIP, TAR or any other
    archieving tool for this.
    <br>&nbsp;

<li><b>Backup your
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    database contents</b>:<br>
    Please use the PostgreSQL built-in "pg_dump" tool for a complete
    database backup: 
    <nobr><tt>pg_dump -c -O -F p -f backup.YYYY-MM-DD.sql</tt></nobr>.<br> 
    This command works both with Windows (CygWin shell) and Unix/Linux.
    <br>&nbsp;

<li><b><a href=load-update-xml>Check for Latest Software Updates</a></b>:<br>
    Go to this page (Admin / Software Updates) and follow this link.
    You will get a menu of the latest updates.
    <br>&nbsp;

<li><b>Decide whether you want to update</b>:<br>
    You don't have to follow each and every upgrade. The system is
    capable of upgrading several versions at a time.<br>
    Also, please check the forum link ("Forum" column in the update menu)
    associated with each particular update for more information.
    <br>&nbsp;

<li><B>Upgrade the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    code</b>:<br>
    Pressing the "Update" button will update your 
    <span class=brandfirst>P/</span><span class=brandsec>O</span>
    code. However, you will still have to get the database in sync
    with the new code. This is done in the next step.
    <br>&nbsp;

<li><b>Update the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    database contents</b>:<br>
    Please use the <a href="/acs-admin/apm/packages-install">Package Manager</a>
    to install the updates and to synchronize the database.
    <br>&nbsp;

<li><b>Restart your 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    server</b>:<br>
    Please use the <a href="/acs-admin/server-restart">Server Restart</a>
    page to restart the server. Or you can restart the server via the
    Windows "Start ProjectOpen Server" menu.
    <br>&nbsp;

</ol>

</td>
<td>

<table>
<tr><td>
<%= [im_table_with_title "Quick Links" "

<ul>
<li><a href=\"http://projop.dnsalias.com/register/user-new\">
    Register your 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    Account</a></li>
<li><a href=load-update-xml>Check for Latest Software Updates</a></li>
<li><a href=\"/acs-admin/apm/packages-install\">Install Packages</a></li>
<li><a href=\"/acs-admin/server-restart\">Server Restart</a></li>
</ul>

Advanced Options
<p>
Please see the <a href=\"http://www.openacs.org/doc/openacs-5-1\">
OpenACS documentation</a> for more information about the following
options:
</p>

<ul>
<li><a href=\"/acs-admin/apm/\">OpenACS Package Manager</a></li>
<li><a href=\"/acs-admin/\">OpenACS Core Administration</a></li>
<li><a href=\"/acs-admin/developer\">OpenACS Developer Administration</a></li>
<li><a href=\"/admin/site-map/\">OpenACS Site Map</a></li>
</ul>

"] %>
</td></tr>
</table>

</td>
</tr>
</table>

That's it. Please contact <a href="mailto:support@project-open.com">
support@project-open.com</a>


