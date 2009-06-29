<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard</property>


<h2>Size of your Organization</h2>


<table border=0 width="80%">
<tr><td colspan=3>

	<p>
	@po_short;noquote@ can be adapted to different organization sizes.
	</p>
	
	<p>
	"<i>Organization Size</i>" refers to full-time members inside your "core" organization<br>
	that is going to use @po_short;noquote@. Please don't include "external" users such as <br>
	vendors, freelancers, customer or users of other departments that might peek <br>
	into the system from time to time.
	
	<p>
	My "core" organization consists of:<br>&nbsp;
	</p>

</td></tr>
<tr valign=top>
  <td width="30"><input type=radio name=orgsize value=one <if @orgsize@ eq "one">checked</if>></td>
  <td colspan=2>
	<b>One hierarchical level</b><br> 
	2-8 full-time members plus support & financial staff
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=two <if @orgsize@ eq "two">checked</if>></td>
  <td colspan=2>
	<b>Two hierarchical levels</b><br>
	8-40 full-time members plus support & financial staff
	<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=three <if @orgsize@ eq "three">checked</if>></td>
  <td colspan=2>
	<b>Three hierarchical levels</b><br>
	40-200 full-time members plus support & financial staff</b><br>
	<br>&nbsp;
  </td>
</tr>
</table>
