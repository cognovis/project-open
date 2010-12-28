<!-- packages/intranet-sysconfig/www/segment/profiles.adp -->
<!-- @author Christof Damian (christof.damian@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard - Trust Model</property>

<input type=hidden name=profiles value=1>

<h2>Trust Model</h2>

Please choose how much you want to trust your "Employees" (normal staff) 
and "Project Managers"? "Senior Managers" are trusted anyway...

<p>
<table>
<tr>
  <td align=center></td>
  <td align=center><%=[lang::message::lookup "" "intranet-sysconfig.profiles_all_projects" all_projects]%></td>
  <td align=center><%=[lang::message::lookup "" "intranet-sysconfig.profiles_all_companies" all_companies]%></td>
  <td align=center><%=[lang::message::lookup "" "intranet-sysconfig.profiles_finance" finance]%></td>
</tr>

<% foreach i [list employees project_managers senior_managers] { %>
<tr>
<td><%=[lang::message::lookup "" "intranet-sysconfig.profiles_$i" $i]%></td>
<%   
  foreach j [list all_projects all_companies finance] { 
    if {[info exists profiles_array($i,$j)]} {
      set check checked
    } else {
      set check ""
    }

    if { $i=="senior_managers" } {
%>
<td align=center><input type=checkbox name="profiles_array.<%=$i,$j%>" checked disabled=1></td>
<% } else { %>
<td align=center><input type=checkbox name="profiles_array.<%=$i,$j%>" <%=$check%>></td>
<% } } %>
</tr>
<% } %>
</table>

<p>
<b>Examples:</b>
<p>

<table>
<tr valign=top><td>
	<table border=1 cellspacing=0 cellpadding=0>
	<tr><td>&nbsp;x&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
	<tr><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td><td>&nbsp;</td></tr>
	<tr><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td></tr>
	</table>
</td>
<td>
	Typical Configuration: <br>
	"Employees" are allowed to see and edit all projects,
	but don't get to see the complete customer list.
	Financial management is limited to "Senior Managers"
	and "Accountants".
</td>
</tr>
</table>


<table>
<tr valign=top><td>
	<table border=1 cellspacing=0 cellpadding=0>
	<tr><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td><td>&nbsp;</td></tr>
	<tr><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td></tr>
	<tr><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td><td>&nbsp;x&nbsp;</td></tr>
	</table>
</td>
<td>
	Permissive Configuration:<br>
	"Employees" don't need to know about finance, but apart
	from that everybody has access to everything.
</td>
</tr>
</table>
