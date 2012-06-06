--
-- Workflow Service Contracts
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @version $Id$
--
-- GNU GPL v2
--

--
-- The service contract for workflows
-- 

begin

   acs_sc_contract.new (
      contract_name => 'NotificationType',
      contract_desc => 'Notification Type'
   );

   acs_sc_msg_type.new (
       msg_type_name => 'NotificationType.GetURL.InputType',
       msg_type_spec => 'object_id:integer'
   );

   acs_sc_msg_type.new (
       msg_type_name => 'NotificationType.GetURL.OutputType',
       msg_type_spec => 'url:string'
   );

   acs_sc_operation.new (
       contract_name => 'NotificationType',
       operation_name =>  'GetURL',
       operation_desc =>  'gets the URL for an object in this notification type',
       operaion_iscachable_p => 'f',
       operation_nargs => 1,
       operation_inputtype => 'NotificationType.GetURL.InputType',
       operation_outputtype => 'NotificationType.GetURL.OutputType'
   ); 

   acs_sc_msg_type.new ( 
       msg_type_name => 'NotificationType.ProcessReply.InputType',
       msg_type_spec => 'reply_id:integer'
   ); 

   acs_sc_msg_type.new ( 
       msg_type_name => 'NotificationType.ProcessReply.OutputType',
       msg_type_spec => 'success_p:boolean'
   ); 

   acs_sc_operation.new 
       contract_name =>  'NotificationType',
       operation_name => 'ProcessReply',
       operation_desc => 'Process a single reply',
       operation_iscachable_p => 'f',
       operation_nargs =>         1,
       operation_inputtype =>    'NotificationType.ProcessReply.InputType',
       operation_outputtype =>   'NotificationType.ProcessReply.OutputType'
   ); 

end;
/
show errors

