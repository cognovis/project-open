<!-- packages/intranet-sysconfig/www/segment/profiles.adp -->
<!-- @author Christof Damian (christof.damian@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard</property>

<input type=hidden name=profiles value=1>

<h2>Profiles</h
<table>
<tr>
  <td></td>
  <td><%=[lang::message::lookup "" "intranet-sysconfig.profiles_all_projects" all_projects]%></td>
  <td><%=[lang::message::lookup "" "intranet-sysconfig.profiles_all_companies" all_companies]%></td>
  <td><%=[lang::message::lookup "" "intranet-sysconfig.profiles_finance" finance]%></td>
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
<td><input type=checkbox name="profiles_array.<%=$i,$j%>" checked disabled=1></td>
<% } else { %>
<td><input type=checkbox name="profiles_array.<%=$i,$j%>" <%=$check%>></td>
<% } } %>
</tr>
<% } %>
</table>