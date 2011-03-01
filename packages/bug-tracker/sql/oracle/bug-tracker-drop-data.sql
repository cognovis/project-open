-- Drop all bugs in the bug tracker

create function inline_0 ()
returns integer as '
declare
    v_bug_id    integer;
begin
    loop        
        select min(bug_id) into v_bug_id from bt_bugs;
        exit when not found or v_bug_id is null;
        perform bt_bug__delete(v_bug_id);
    end loop;

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();
