<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">System Configuration Wizard</property>


<h2>Size of your Organization</h2>


<table border=0 width="90%">
<tr><td colspan=3>

	<p>
	@po;noquote@ can be adapted to organizations of different size.
	Smaller organization may be able to work with a simplified version
	while larger organizaitons need all available communication and
	organization features.
	</p>
	
	<p>
	"<i>Size</i>" refers to full-time members inside your organization such
	as employees and management team.
	Please don't include external users such as your customers,
	freelancers or vendors.
	
	<p>
	"<i>Organization</i>" refers to the actual organization to use
	@po_small;noquote@. Please give only the size of your department 
	if your department is part of a larger company (such as the IT
	or translation department of a larger corporation).

	<p>
	My organization consists of
	</p>

</td></tr>
<tr valign=top>
  <td><input type=radio name=orgsize value=2</td>
  <td colspan=2>
	<b>2-4 Full-Time Members</b><br>
	We are a very small organization with mutual trust. 
	We don't need any internal structure and i

  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=biz_consulting</td>
  <td colspan=2>
	<b>Business Consulting</b><br>
	Strategic Consulting, Financial Consulting, Organizational Development, ... <br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=translation</td>
  <td colspan=2>
	<b>Translation and Localization</b><br>
	Translation, Software Localization, Technical Documentation, ...<br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=advertizing</td>
  <td colspan=2>
	<b>Advertizing &amp; Web Development</b><br>
	Advertizing or Interactive Media development. <br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=it_consulting</td>
  <td colspan=2>
	<b>Product Development & Engineering</b><br>
	Mechanical Engineering, Electrical Engineering, Marketing, ... <br>&nbsp;
  </td>
</tr>

<tr valign=top>
  <td><input type=radio name=orgsize value=other</td>
  <td>
	<b>Other / Everything</b><br>
	Install everything. <br>
	Please specify your area:
	
  </td>
  <td align=left><input type=text name=other size=30>
  </td>
</tr>



</table>
