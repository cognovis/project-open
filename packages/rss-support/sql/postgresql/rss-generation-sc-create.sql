--
-- ACS-SC Contract: RssGenerationSubscriber
--

select acs_sc_contract__new (
       'RssGenerationSubscriber',		-- contract_name
       'RSS Generation Subscriber'		-- contract_desc
);

select acs_sc_msg_type__new (
       'RssGenerationSubscriber.Datasource.InputType',
       'summary_context_id:string'  
);

select acs_sc_msg_type__new (
       'RssGenerationSubscriber.Datasource.OutputType',
       'version:string,channel_title:string,channel_link:uri,channel_description:string,image:string,items:string,channel_language:string,channel_copyright:string,channel_managingEditor:string,channel_webMaster:string,channel_rating:string,channel_pubDate:timestamp,channel_lastBuildDate:timestamp,channel_skipDays:integer,channel_skipHours:integer'
);

select acs_sc_operation__new (
       'RssGenerationSubscriber',			-- contract_name
       'datasource',					-- operation_name
       'Data Source',					-- operation_desc
       'f',						-- operation_iscachable_p,
       1,						-- operation_nargs
       'RssGenerationSubscriber.Datasource.InputType',  -- operation_inputtype
       'RssGenerationSubscriber.Datasource.OutputType'  -- operation_outputtype
);

select acs_sc_msg_type__new (
       'RssGenerationSubscriber.LastUpdated.InputType',
       'summary_context_id:string'  
);

select acs_sc_msg_type__new (
       'RssGenerationSubscriber.LastUpdated.OutputType',
       'lastupdate:timestamp'
);

select acs_sc_operation__new (
       'RssGenerationSubscriber',			-- contract_name
       'lastUpdated',					-- operation_name
       'Last Updated',					-- operation_desc
       'f',						-- operation_iscachable_p,
       1,						-- operation_nargs
       'RssGenerationSubscriber.LastUpdated.InputType',  -- operation_inputtype
       'RssGenerationSubscriber.LastUpdated.OutputType'  -- operation_outputtype
);
