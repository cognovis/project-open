<master src="../../intranet-customer-portal/www/master">
<property name="title">@page_title;noquote@</property>
<property name="show_left_navbar_p">0</property>

<br><br><br><br><br><br><br>
<div id="dummy" align="center" widt="100%">
<table border="0" width="600px">
<tr>
	<td valign="top"><h1>Already a registered user?</h1></td>
        <td><img src="/intranet/images/cleardot.gif" width="100px"</td>
	<td valign="top"><h1>New customer?</h1></td>
</tr>

<tr>
        <td valign="top">If you are already a customer please login:</td>
        <td></td>
        <td valign="top">If you are a new customer please register:</td>
</tr>

<tr>
        <td valign="top">
		<include src="@login_template@" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">
        </td>
        <td></td>
        <td valign="top">
		<div id="form_customer_registration"></div>
        </td>
</tr>

</table>
</div>





