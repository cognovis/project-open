<master src="../../intranet-core/www/admin/master">
<property name="title">Automatic Software Update Client</property>
<property name="main_navbar_label">admin</property>
<property name="admin_navbar_label">software_updates</property>


<h1>Automatic Software Updates</h1>

<table width="500">
<tr><td>

Please follow the steps below for an "automatic sofware update" of your
<span class=brandfirst>Project/</span><span class=brandsec>Open</span>
server.

<ol>

<li>Please read:<br>
    <a href=http://www.project-open.com/product/services/software-updates/>
    Software Update Service overview</a>
    <br>&nbsp;

<li>
    Get a
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    account</a>:<br>
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

<li>Test the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    account:<br>
    Login manually at <a href="http://projop.dnsalias.com/">
    http://projop.dnsalias.com/</a>.
    <br>&nbsp;

<li>Please use our 
    <a href="http://www.project-open.com/contact/">contact form</a> 
    to request participation in the "automatic software update" service. 
    We will send you an email message once the service is set up for
    you.
    <br>&nbsp;

<li>Backup your 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    software:
    Please make a full backup of your
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    source code directory (C:\ProjectOpen\projop\packages in Windows and
    /web/projop/packages in Linux/Unix). You can use ZIP, TAR or any other
    archieving tool for this.
    <br>&nbsp;

<li>Backup your
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    database contents:
    Please use the PostgreSQL built-in "pg_dump" tool for a complete
    database backup: 
    <nobr><tt>pg_dump -c -O -F p -f backup.YYYY-MM-DD.sql</tt></nobr>.<br> 
    This command works both with Windows (CygWin shell) and Unix/Linux.
    <br>&nbsp;

<li>Update the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    software
    <br>&nbsp;

<li>At your 
    <span class=brandfirst>P/</span><span class=brandsec>O</span> System
    go to the "Admin / Software Updates" menu:<br>
    You will see the list of available updates
    <br>&nbsp;

<li>Decide whether you want to update:<br>
    You don't have to upgrade your system with every new option. However,
    this Automatic Upgrade Service makes reduces the effort or installing
    patches etc.
    <br>&nbsp;

<li>Update the 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    database contents
    <br>&nbsp;

<li>Restart your 
    <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
    server
    <br>&nbsp;

<li><a href=load-update-xml>Check for Latest Software Updates</a>
    <br>&nbsp;

<li>ACS Package Manager <a href=/acs-admin/apm/>Status and Main Page</a>
    <br>&nbsp;

<li>ACS Package Manager <a href=/acs-admin/apm/packages-install>Install Package Data Models<a>
    <br>&nbsp;

</ol>


</td></tr>
</table>

<h2>Help</h2>

The <span class=brandfirst>Project/</span><span class=brandsec>Open</span>
software update process consists of several steps:

<ol>
<li>Obtail a software update account: Login to the Project/Open server and 
<li>
</ol>


<p>
For detailed help please see the "Project/Open Configuration Guide".
</p>