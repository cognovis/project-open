{"totalCount":"@inquiries_count@",
"inquiries":[
<multiple name=inquiries>
        {"inquiry_id":"@inquiries.inquiry_id;noquote@","name":"@inquiries.name;noquote@", "email":@inquiries.email;noquote@, "company_name":@inquiries.company_name;noquote@, "phone":"@inquiries.phone@"}
        <if @inquiries.rownum@ ne @row_count@>
        ,
        </if>
</multiple>
]}


