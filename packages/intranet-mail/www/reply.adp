<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>

<include src="../lib/email" object_id="@object_id@" to_addr="@sender_addr@" cc_ids="@cc_ids@" party_ids="@sender_id@" subject="Re: @subject;noquote@" return_url="@return_url;noquote@" export_vars="log_id" />
<br />
<br />
<hr />
<br />
<br />

@body;noquote@