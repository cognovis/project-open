<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<!-- 

       Parameters:

       party_ids   = List of party_id's to send a message. Here they are project assignees
       export_vars = variables that you want to be present on the include form (For example project_id)
       return_url  = Url to redirect after the process is finished
       file_ids    = revision_id of files you wan't to include in your message

 -->

<include src="/packages/intranet-mail/lib/email" return_url=@return_url;noquote@ object_id=@object_id@ no_callback_p="f" checked_p="f" use_sender_p="f" cc="@cc@" cc_ids="@cc_ids@" bcc="@bcc@" mime_type="text/html" subject="@subject;noquote@" export_vars="@export_vars@" log_id="@log_id@" to_addr="@to_addr@" content="@content_body;noquote@" file_ids="@files@">
