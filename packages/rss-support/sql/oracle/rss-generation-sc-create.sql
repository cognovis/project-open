--
-- ACS-SC Contract: RssGenerationSubscriber
--

declare
  foo integer;
begin
  foo := acs_sc_contract.new(
	contract_name => 'RssGenerationSubscriber',
        contract_desc => 'RSS Generation Subscriber'
  );

  foo := acs_sc_msg_type.new(
	msg_type_name => 'RssGenerationSubscriber.Datasource.InputType',
	msg_type_spec => 'summary_context_id:string'
  );

  foo := acs_sc_msg_type.new(
	msg_type_name => 'RssGenerationSubscriber.Datasource.OutputType',
	msg_type_spec => 'version:string,channel_title:string,channel_link:uri,channel_description:string,image:string,items:string,channel_language:string,channel_copyright:string,channel_managingEditor:string,channel_webMaster:string,channel_rating:string,channel_pubDate:timestamp,channel_lastBuildDate:timestamp,channel_skipDays:integer,channel_skipHours:integer'
  );

  foo := acs_sc_operation.new(
   	contract_name => 'RssGenerationSubscriber',
        operation_name => 'datasource',
        operation_desc => 'Data Source',
        operation_iscachable_p => 'f',
        operation_nargs => 1,
        operation_inputtype => 'RssGenerationSubscriber.Datasource.InputType',
        operation_outputtype => 'RssGenerationSubscriber.Datasource.OutputType'
  );

  foo := acs_sc_msg_type.new(
	msg_type_name => 'RssGenerationSubscriber.LastUpdated.InputType',
	msg_type_spec => 'summary_context_id:string'
  );

  foo := acs_sc_msg_type.new(
	msg_type_name => 'RssGenerationSubscriber.LastUpdated.OutputType',
	msg_type_spec => 'lastupdate:timestamp'
  );

  foo := acs_sc_operation.new(
   	contract_name => 'RssGenerationSubscriber',
        operation_name => 'lastUpdated',
        operation_desc => 'Last Updated',
        operation_iscachable_p => 'f',
        operation_nargs => 1,
        operation_inputtype => 'RssGenerationSubscriber.LastUpdated.InputType',
        operation_outputtype => 'RssGenerationSubscriber.LastUpdated.OutputType'
  );

end;
/
show errors
