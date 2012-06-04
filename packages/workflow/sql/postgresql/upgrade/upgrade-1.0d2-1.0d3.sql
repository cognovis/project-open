-- Upgrade script
--
-- Redefine workflow_case__delete.
-- workflow_case__delete was implemented wrong, so it tried to delete the case by object_id instead of case_id.
--
-- Lars Pind (lars@collaboraid.biz)
-- $Id$

create or replace function workflow_case__delete (integer)
returns integer as '
declare
  delete_case_id                alias for $1;
  rec                           record;
begin

    for rec in select cr.item_id
                   from cr_items cr, workflow_case_log wcl
                   where cr.item_id = wcl.entry_id
                   and wcl.case_id = delete_case_id loop

                delete from workflow_case_log where entry_id = rec.item_id;
                perform content_item__delete(rec.item_id);                
    end loop;

    -- All workflow data cascades from the case id
    delete from workflow_cases
      where case_id = delete_case_id;    

  return 0; 
end;' language 'plpgsql';

