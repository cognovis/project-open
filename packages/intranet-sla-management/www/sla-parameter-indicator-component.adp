<if @sla_read@>
<script language="JavaScript" type="text/javascript" src="/resources/diagram/diagram/diagram.js"></script>
<form action="/intranet-sla-management/sla-parameter-action" method=GET>
<%= [export_form_vars return_url] %>
<table>
@header_html;noquote@
@body_html;noquote@
</table>
</form>
@footer_html;noquote@
</if>
