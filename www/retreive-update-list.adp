<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>
<property name="admin_navbar_label">software_updates</property>

<table cellspacing=0 cellpadding=0 width="100%">
<tr valign=top>
<td>
	<h1><nobr>@page_title@</nobr></h1>
	<%= [lang::message::lookup "" intranet-security-update-client.Guide_Intro "
	The <a href='http://www.project-open.org/documentation/asus'>Automatic Software Update Service (ASUS)</a> 
	keeps your @po;noquote@ system up to date and fixes security issues."] %><br>&nbsp;
	<h2><%= [lang::message::lookup "" intranet-security-update-client.Guide_Update "Update Your System"] %></h2>
</td>
</tr>
</table>


<ol>
<li><b><%= [lang::message::lookup "" intranet-security-update-client.Guide_Perform_Database_Backup "Perform a Database Backup"] %></b>:<br>
    <%= [lang::message::lookup "" intranet-security-update-client.Guide_Perform_Database_Backup_Msg "
    Please perform a <a href='/intranet/admin/backup/'>database backup</a>."] %>
    <br>&nbsp;

<li><b><%= [lang::message::lookup "" intranet-security-update-client.Guide_Perform_Code_Backup "Perform a Code Backup"] %></b>:<br>
    <%= [lang::message::lookup "" intranet-security-update-client.Guide_Perform_Code_Backup_Msg "
    Please save your source code at &lt;install-dir&gt;\\servers\\projop\\packages (Win32)
    or /web/projop/packages (Linux) manually using zip or tar."] %>
    <br>&nbsp;


<li><b><%= [lang::message::lookup "" intranet-security-update-client.Guide_Decide "Decide whether you want to update"] %></b>:<br>
    <%= [lang::message::lookup "" intranet-security-update-client.Guide_Decide_Msg "
    Please check the forum (link below!) to decide whether you want to upgrade. <br>
    You don't have to follow each and every upgrade."] %>
    <br>&nbsp;


<if @ctr@ ne 0>
<table cellspacing=2 cellpadding=2 width="100%">
<tr class=rowtitle>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Update "Update"] %></td>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Package "Package"] %></td>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Version "Version"] %></td>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Release_Date "Release<br>Date"] %></td>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Forum "Forum"] %></td>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Update_Urgency "Update<br>Urgency"] %></td>
  <td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.Whats_New "What's New"] %></td>
</tr>
@version_html;noquote@
</table>
<p>&nbsp;</p>
</if>
<else>
<li><b><%= [lang::message::lookup "" intranet-security-update-client.Guide_Error_Retreiving_Update_List "Error retreiving the list of available updates"] %></b>:<br>
</else>

<li><B><%= [lang::message::lookup "" intranet-security-update-client.Guide_Upgrade_System "Upgrade your system"] %></b>:<br>
    <%= [lang::message::lookup "" intranet-security-update-client.Guide_Upgrade_System_Msg "
    Pressing the 'Update' button will update your @po;noquote@ code."] %>
    <br>&nbsp;

<li><b><%= [lang::message::lookup "" intranet-security-update-client.Guide_Upgrade_DB "Update your database"] %></b>:<br>
    <%= [lang::message::lookup "" intranet-security-update-client.Guide_Upgrade_DB_Msg "
    Please use the <a href='/acs-admin/apm/packages-install'>Package Manager</a>
    to update the database. Please check <b>only</b> the 'Update' options.<br>
    Please don't perform any 'Install' options unless you know what you are doing."] %>
    <br>&nbsp;

<li><b><%= [lang::message::lookup "" intranet-security-update-client.Guide_Restart "Restart your server"] %></b>:<br>
    <%= [lang::message::lookup "" intranet-security-update-client.Guide_Restart_Msg "
    Please use the <a href='/acs-admin/server-restart'>Server Restart</a>
    page to restart the server."] %>
    <br>&nbsp;
</ol>

