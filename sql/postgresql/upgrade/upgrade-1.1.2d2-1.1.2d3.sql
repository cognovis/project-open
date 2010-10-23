-- add missing alias for $1

create or replace function category__name (
    integer   -- category_id
)
returns integer as '
declare
    p_category_id       alias for $1;
    v_name      varchar;
begin
	select name into v_name
	from category_translations
	where category_id = p_category_id
	and locale = ''en_US'';

        return 0;
end;
' language 'plpgsql';