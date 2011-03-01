<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard</property>
<property name="page">sector</property>


<h2>Company or Department?</h2>

<table border=0 width="80%">
<tr><td colspan=3>

	<p>
	Do you want to run the entire company on @po_short;noquote@ 
	or just your department?
<!--
	<p>
	There are different @po_short;noquote@ modules available for
	the different options.
-->
	<p>
	My organization is a:<br>&nbsp;
	</p>

</td></tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=dept <if @deptcomp@ eq "dept">checked</if>></td>
  <td colspan=2>
	<b>Corporate Department</b><br>
	My organization is a department within a larger corporation.<br>
	@po_short;noquote@ will have to be integrated with our ERP system.<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=subsidary <if @deptcomp@ eq "subsidary">checked</if>></td>
  <td colspan=2>
	<b>Independent Subsidary or Division</b><br>
	My organization is a subsidary or division of a larger corporation.<br>
	 @po_short;noquote@ would need to communicate financial 
	information to our headquarter's financial reporting system.<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=sme <if @deptcomp@ eq "sme">checked</if>></td>
  <td colspan=2>
	<b>Small or Medium Enterprise (SME)</b><br>
	My company is a SME with 3-3000 employees.<br>
	We need to export @po_short;noquote@ financial information to our accounting system.
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=deptcomp value=other <if @deptcomp@ eq "other">checked</if>></td>
  <td>
	<b>Other / Everything</b><br>
	None of the above fits my type of organization.<br>
	Please install everything.
  </td>
</tr>



</table>
