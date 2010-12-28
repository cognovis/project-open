<!-- packages/intranet-sysconfig/sector/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">Confirm your Configuration</property>

<h2>Confirm your Configuration</h2>

<table border=0 width="80%">

<if @ready@>

<tr><td colspan=3>

	<p>Please read the latest release notes:
	</p>

	<iframe src="@iframe_url;noquote@" width="90%" height="200" name="Release Notes">
  <p>No IFrames supported...</p>
</iframe>

	<p>Please confirm your selection and start the configuration process:
	</p>

	<blockquote>
	<input type=button value='Start Configuration Process'
	onClick="window.document.wizard.action='/intranet-sysconfig/configure'; submit();" 
	title='Confirm' alt='Confirm'>
	</blockquote
</td><tr>

</if>
<else

    <tr><td colspan=3>

	<p>&nbsp;
	<p>&nbsp;</p>

	<center>
	<b>Undefined Variables</b><br>
	One or more of the installation parameters are undefined.<br>
	For a status please see the status bar at the right.
	<p>
	Please go back and select the missing parameters.
	</center>
    </td><tr>

</else>



</table>

