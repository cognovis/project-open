<master>
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin</property>


<table width="70%">
<tr>
<td>

<h1>@page_title;noquote@</h1>



<table style="background-color: rgb(255, 255, 204);" border="0" cellpadding="5" cellspacing="5"><tbody><tr><td valign="top">
Before you can use the @po;noquote@ ASUS
(Automatic Software Update Service) and the ADMIN tools of ]project-open[ you need to agree 
to the following terms and conditions of this service. <strong>Please read carefully and make your choice at the bottom of the page in order to continue.</strong>
<br><br>Please note:<br>
ASUS is there to make your life easier. Among other advantages you will be able to
update your system with a simple click on a button.
Signing up for ASUS is not a mandatory action required to use ]project-open[.
You will be able to use ]project-open[ without ASUS. Updates can be performed at any time
for free against our central CVS repository.<br>
</td></tr></table>

<br>
<h2>The Automatic Software Update Service</h2>

<p>
The ASUS service performs several actions:
<br>&nbsp;<br>
<ul>
<li>
	<b>Check for known security flaws and bugs</b>. <br>
	As a result of this check, ASUS will display a
	message with the status of the system and possibly update 
	recomendations.
	<br>&nbsp;<br>
<li>
	<b>Download system updates and security patches</b>.<br>
	It will ask the user to confirm before taking any important
	action.
	<br>&nbsp;<br>
<li>
	<b>Update exchange rates</b>.<br>
	Exchange rates are necessary in order to calculate Profit &amp;
	Loss for projects.
	<br>&nbsp;<br>
<li>
	<b>Proactive Maintenance</b>.<br>
	Future versions of ASUS will check important system parameters
	including memory consumption, hard disk space, database 'vacuum'
	time, Internet availability etc. in order to alert system 
	administrators before a system failure acutally happens.
	<br>&nbsp;<br>
</ul>
</p>


<br>
<h2>Price</h2>
<p>
ASUS is a free service at the moment (October 2009). However, 
we plan to introduce a yearly fee for ASUS in the future.
We will notify you about possible changes with three months in 
advance. 
</p>
<br>

<br>
<h2>Data Collection</h2>
<p>
In order to check your system we need to collect data from 
your installation. 
This information includes the version of your @po;noquote@ 
packages, your operating system and your PostgreSQL database.
Also, we will generate an anonymous unique ID for your hardware 
and your @po;noquote@ installation and transmit the number of
users in your system in order to maintain statistics about
the product.
Collecting your email address will allow us to alert you 
in case of critical security threads.
</p>


<br>
<h2>Limitation of Data Collection</h2>
<p>
You can also choose to limit the collected data to anonymous
system information only. In this case please select 
'Limit ASUS to anonymous data' below.
</p>


<br>
<h2>Disable ASUS</h2>
<p>
You can also decide to disable ASUS completely. In order to do
so please go now to Admin (at the left navigation bar) -&gt; 
Portlet Components, select Package="intranet-security-update-client"
and set the listed component to "Not Enabled".
</p>


<br>
<h2>Warranty and Disclaimer</h2>
<p>
@po;noquote@ makes no representations or warrenties regarding the accuracy or completeness
of the information provided by ASUS. @po;noquote@ disclaims all warranties in connection
with the ASUS, and will not be liable for any damage of loss resulting from your use
of the service or the product.

</td>
</tr>
<tr>
<td>

<br>

<form action="/intranet-security-update-client/update-preferences">
<%= [export_form_vars return_url] %>
<input type=radio name=verbosity value=1 checked>Enable full Automatic Security Update Service (ASUS)<br>
<input type=radio name=verbosity value=0>Limit ASUS to anonymous data<br>
<br>
<input type=submit value="Enable ASUS">
</form>

</td>
</tr>
</table>

