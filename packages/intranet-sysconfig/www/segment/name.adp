<!-- packages/intranet-sysconfig/www/segment/name.adp -->
<!-- @author Christof Damian (christof.damian@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="master">
<property name="title">System Configuration Wizard</property>

<input type=hidden name=name value=1>

<h2>Organization Name and Default Email</h2>

<p>
Please enter your organization name. This name appears in emails,<br>
invoices and other legal documents. Example: "ABC Consulting, Inc."
</p><br>
<p>
<input type=text name=name_name value=@name_name@ size=40>
</p>

<p>
Please enter the email of the "application owner", that is the person<br>
in charge of @po;noquote@. This email address appears in the <br>
"Contact" footer at every page. Please see below for an example.
</p><br>
<p>
<input type=text name=name_email value=@name_email@ size=40>
</p>