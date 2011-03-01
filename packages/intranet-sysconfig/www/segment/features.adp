<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard</property>


<h2>Simplified or Complete Install?</h2>

<table border=0 width="80%">
<tr><td colspan=3>

	<p>
	@po_small;noquote@ offers a total of ~100 packages which can be enabled/disabled<br>
	 individually. However enabling/disabling them may take some time. <br>
	So please select your start configuration. You can later change the <br>
	configuration by running this wizard again.<br>&nbsp;
	</p>
	
</td></tr>
<tr valign=top>
  <td><input type=radio name=features value=minimum <if @features@ eq "minimum">checked</if>></td>
  <td colspan=2>
	<b>Simplified System</b><br>
	Install only essential packages.<br>
	This option is useful for first time @po;noquote@ users and users
	who don't want to be confused by the system.
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=features value=frequently_used <if @features@ eq "frequently_used">checked</if>></td>
  <td colspan=2>
	<b>Default System</b><br>
	Install frequently used packages and disables less 
	frequently used extensions.<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=features value=other <if @features@ eq "other">checked</if>></td>
  <td colspan=2>
	<b>Complete / Full Installation</b><br>
	Install everything.<br>
	This option is useful if you are checking for specific
	features/ options for your organization or if you want to
	enable/ disable features yourself.
	<br>&nbsp;
  </td>
</tr>
</table>
