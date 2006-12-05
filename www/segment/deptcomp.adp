<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">System Configuration Wizard</property>
<property name="page">sector</property>


<h2>Company or Department?</h2>

<table border=0 width="80%">
<tr><td colspan=3>

	<p>
	Do you want to run the entire company on @po_short;noquote@ 
	or just your department?
	
	<p>
	My organization is a:<br>&nbsp;
	</p>

</td></tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=dept></td>
  <td colspan=2>
	<b>Corporate Department</b><br>
	We would use @po_short;noquote@ to manage a department
	of 2-200 employees as part of a larger company.
	@po_short;noquote@ would have to connect to our ERP system.<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=subsidary></td>
  <td colspan=2>
	<b>Independent Subsidary or Division</b><br>
	My organization is a subsidary or division of a larger corporation.
	 @po_short;noquote@ would need to communicate financial 
	information to our headquarter's financial reporting system.<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=sme></td>
  <td colspan=2>
	<b>Small or Medium Enterprise (SME)</b><br>
	My company is a SME with 2-200 employees. We need to export
	@po_short;noquote@ financial information to our local accounting system.
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=other></td>
  <td>
	<b>Other / Everything</b><br>
	None of the above fits my type of organization.<br>
	Please install everything.
  </td>
</tr>



</table>
