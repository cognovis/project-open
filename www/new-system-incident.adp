<master src="../../intranet-core/www/master">
<property name="title">Home</property>

<H1>Incident Received</H1>

<p>
Thank you for submitting your incident.
</p><p>
We will notify you as soon as possible.
</p>


<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top>
  <td valign=top>


<table border=0 cellspacing=1 cellpadding=1>
<tr class=rowtitle>
  <td class=rowtitle align=center colspan=2>
    Incident Information
  </td>
</tr>
<tr>
  <td>Your Name</td>
  <td>@error_first_names@ @error_last_name@</td>
</tr>
<tr>
  <td>Your Email</td>
  <td>@error_user_email@</td>
</tr>
<tr>
  <td>System URL</td>
  <td>@system_url@</td>
</tr>
<tr>
  <td>Publisher Name</td>
  <td>@publisher_name@</td>
</tr>
<tr>
  <td>Error URL</td>
  <td>@error_url@</td>
</tr>
</table>


  </td>
  <td valign=top>

<table border=0 cellspacing=1 cellpadding=1>
<tr class=rowtitle>
  <td class=rowtitle align=center colspan=2>
    Do you have a support contract?
  </td>
</tr>
<tr>
  <td colspan=2>
<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@error_user_email;noquote@" &="__adp_properties">
  </td>
</tr>
</table>

  </td>
</tr>
</table>







