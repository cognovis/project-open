
-- create or replace package body wf_callback
-- function guard_attribute_true
create or replace function wf_callback__guard_attribute_true (integer,varchar,varchar,varchar,varchar,varchar)
returns boolean as '
declare
  guard_attribute_true__case_id         alias for $1;  
  guard_attribute_true__workflow_key    alias for $2;  
  guard_attribute_true__transition_key  alias for $3;  
  guard_attribute_true__place_key       alias for $4;  
  guard_attribute_true__direction       alias for $5;  
  guard_attribute_true__custom_arg      alias for $6;  

  v_value				varchar;
begin
        v_value := workflow_case__get_attribute_value(
	    guard_attribute_true__case_id, 
	    guard_attribute_true__custom_arg
	);

	IF ''t'' = substring(v_value from 1 for 1) THEN return true; END IF;
	IF ''f'' = substring(v_value from 1 for 1) THEN return false; END IF;

	return null;
end;' language 'plpgsql';


-- function time_sysdate_plus_x
create or replace function wf_callback__time_sysdate_plus_x (integer,varchar,text)
returns timestamptz as '
declare
  time_sysdate_plus_x__case_id          alias for $1;  
  time_sysdate_plus_x__transition_key   alias for $2;  
  time_sysdate_plus_x__custom_arg       alias for $3;  
begin
        return now() + (time_sysdate_plus_x__custom_arg || '' days'')::interval;
     
end;' language 'plpgsql';



