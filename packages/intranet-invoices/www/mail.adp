<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>

<include src="/packages/intranet-core/lib/email" object_id="@invoice_id@" party_ids="@recipient_id@" subject="@subject;noquote@" content_body="@body;noquote@" return_url="@return_url;noquote@" file_ids="@invoice_revision_id@" export_vars="invoice_id"/>
