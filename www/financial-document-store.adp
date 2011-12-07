{"totalCount":"<%=$docs_count%>",
"docs":[
<multiple name=docs>
        { "id":"@docs.id;noquote@", "title":"@docs.cost_name;noquote@","doc_date":"@docs.doc_date;noquote@", "status_id":"@docs.invoice_status;noquote@", "amount":"@docs.invoice_amount_formatted;noquote@","currency":"@docs.invoice_currency;noquote@","project_nr":"@docs.project_nr;noquote@" }
	        <if @docs.rownum@ ne @row_count@>
	        ,
	        </if>
</multiple>
]}