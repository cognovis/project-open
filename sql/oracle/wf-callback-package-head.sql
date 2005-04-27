--
-- acs-workflow/sql/wf-callback-package-head.sql
--
-- Creates the PL/SQL package that provides a small library of reusable
-- workflow callback functions/procedures.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

create or replace package wf_callback
as

    function guard_attribute_true(
        case_id 	in number,
	workflow_key 	in varchar2,
	transition_key 	in varchar2,
	place_key 	in varchar2,
	direction 	in varchar2,
	custom_arg 	in varchar2
    ) return char;
    	
    function time_sysdate_plus_x(
	case_id 	in number,
	transition_key 	in varchar2,
	custom_arg in varchar2
    ) return date;

end wf_callback;
/
show errors;
