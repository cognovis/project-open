<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard</property>


<h2>Size of Your Organization</h2>


<table border=0 width="80%">
<tr><td colspan=3>

	<p>
	@po_short;noquote@ can be adapted to different <i>organization sizes</i>.
	</p>
	
	<p>
	Organization size refers to full-time members inside your core organization
	that are going to use @po_short;noquote@ every day. <br>
	Please don't include external users 
	such as vendors, freelancers, customer or users of other departments that might peek
	into the system from time to time.
	
	<p>
	My "core" organization consists of:<br>&nbsp;
	</p>

</td></tr>
<tr valign=top>
  <td width="30"><input type=radio name=orgsize value=one <if @orgsize@ eq "one">checked</if>></td>
  <td colspan=2>
	<b>One hierarchical level</b><br> 
	3-15 full-time members including support & financial staff
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=two <if @orgsize@ eq "two">checked</if>></td>
  <td colspan=2>
	<b>Two hierarchical levels</b><br>
	15-80 full-time members including support & financial staff
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=three <if @orgsize@ eq "three">checked</if>></td>
  <td colspan=2>
	<b>Three hierarchical levels</b><br>
	80-600 full-time members including support & financial staff
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=four <if @orgsize@ eq "four">checked</if>></td>
  <td colspan=2>
	<b>Four hierarchical levels</b><br>
	600-3000 full-time members including support & financial staff<br>
	<br>&nbsp;
  </td>
</tr>

</table>
