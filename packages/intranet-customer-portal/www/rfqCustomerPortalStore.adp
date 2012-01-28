{"totalCount":"@inquiries_count@",
"rfq":[
<multiple name=inquiries>
        {"id":"@inquiries.id;noquote@", "inquiry_id":"@inquiries.inquiry_id;noquote@", "title":"@inquiries.title;noquote@", "company_name":"@inquiries.company_name;noquote@", "inquiry_date":"@inquiries.inquiry_date@", "status_id":"@inquiries.status_id;noquote@", "cost_name":"@inquiries.cost_name;noquote@", "amount":"@inquiries.amount;noquote@", "currency":"@inquiries.currency;noquote@", "action_column":"@inquiries.action_column;noquote@", "project_id":"@inquiries.project_id;noquote@" }
        <if @inquiries.rownum@ ne @row_count@>
        ,
        </if>
</multiple>
]}