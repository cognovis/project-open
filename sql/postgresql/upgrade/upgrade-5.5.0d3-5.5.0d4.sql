



-- Drop contstraints if exists
create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count                 integer;
BEGIN
	select count(*) into v_count from pg_constraint
	where  lower(conname) = ''cr_revisions_lob_fk'';
        IF v_count = 0 THEN return 0; END IF;

	alter table cr_revisions
	drop constraint cr_revisions_lob_fk;

        return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


alter table cr_revisions
add constraint cr_revisions_lob_fk
foreign key (lob) references lobs on delete set null;
