<!-- packages/intranet-sysconfig/prodtest/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">Evaluation or Producton?</property>

<h2>Evaluation or Production?</h2>

<table border=0 width="80%">
<tr><td colspan=3>

	<p>
	Are you going to evaluate the system or are are you going to start
	production use now?


</td></tr>

<tr valign=top>
  <td>
	<input type=radio name=prodtest value=test <if @prodtest@ eq "test">checked</if>>
  </td>
  <td colspan=2>
	<b>Evaluation</b><br>
	This is the default. The system comes with a sample company configuration 
	that defines a number of users, customers, projects etc.
	These sample data make it easier for your to learn about and evaluate the system.
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td>
	<input type=radio name=prodtest value=production <if @prodtest@ eq "production">checked</if>>
  </td>
  <td colspan=2>
	<b>Production</b><br>
	This option will delete any demo contents in the system and leave you
	with an empty system ready to start production use.<br>
	Please only use this option if your are sure about what you do.
	<br>&nbsp;
  </td>
</tr>

</table>

