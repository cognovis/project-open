{"totalCount":"@files_count@",
"files":[
<multiple name=files>
	{"inquiry_files_id":"@files.inquiry_files_id;noquote@","file_name":"@files.file_name;noquote@", "source_language":"@files.source_language;noquote@", "target_languages":"@files.target_languages;noquote@", "deliver_date":"@files.deliver_date;noquote@"}
	<if @files.rownum@ ne @row_count@>
	,
	</if>
</multiple>
]}

