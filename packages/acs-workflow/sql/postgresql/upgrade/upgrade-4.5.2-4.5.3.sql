-- upgrade-4.5.2-4.5.3.sql

-- Detecting the case of an empty return string,
-- representing a NULL value in TCL(?)
--
create or replace function wf_callback__guard_attribute_true (integer,varchar,varchar,varchar,varchar,varchar)
returns boolean as '
declare
  guard_attribute_true__case_id         alias for $1;
  guard_attribute_true__workflow_key    alias for $2;
  guard_attribute_true__transition_key  alias for $3;
  guard_attribute_true__place_key       alias for $4;
  guard_attribute_true__direction       alias for $5;
  guard_attribute_true__custom_arg      alias for $6;

  v_value                               varchar;
begin
        v_value := workflow_case__get_attribute_value(
            guard_attribute_true__case_id,
            guard_attribute_true__custom_arg
        );
        IF substring(v_value from 1 for 1) = ''t'' THEN return true; END IF;
        IF substring(v_value from 1 for 1) = ''f'' THEN return false; END IF;
        IF '''' = v_value THEN return null; END IF;

        RAISE WARNING ''workflow_case__get_attribute_value(%,%) returned non-boolean value %'',
                guard_attribute_true__case_id, guard_attribute_true__custom_arg, v_value;
        return null;
end;' language 'plpgsql';
