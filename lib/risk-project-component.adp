<div style="clear:both;"></div>
<div class="risk_outer">
	<div class="risk_matrix">
		@risk_chart_html;noquote@
	</div>
	<div class="risk_table">	
		<form action="/intranet-riskmanagement/action" method=GET>
		<%= [export_form_vars return_url] %>
		<table width="100%">
		@table_header_html;noquote@
		@table_body_html;noquote@
		@table_footer_html;noquote@
		</table>
		</form>
	</div>
</div>
