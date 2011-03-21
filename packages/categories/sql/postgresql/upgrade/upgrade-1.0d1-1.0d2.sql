alter table category_tree_map add column
	assign_single_p		char(1) constraint cat_tree_map_single_p_ck check (assign_single_p in ('t','f'))
;
alter table category_tree_map alter column assign_single_p set default 'f';

alter table category_tree_map add column
	require_category_p	char(1) constraint cat_tree_map_categ_p_ck check (require_category_p in ('t','f'))
;
alter table category_tree_map alter column require_category_p set default 'f';
update category_tree_map set assign_single_p = 'f', require_category_p = 'f';

comment on column category_tree_map.assign_single_p is '
  Are the users allowed to assign multiple or only a single category
  to objects?
';
comment on column category_tree_map.require_category_p is '
  Do the users have to assign at least one category to objects?
';

drop function category_tree__map (integer,integer,integer);

create or replace function category_tree__map (
    integer,   -- object_id
    integer,   -- tree_id
    integer,   -- subtree_category_id
    char,      -- assign_single_p
    char       -- require_category_p
)
returns integer as '
declare
    p_object_id              alias for $1;
    p_tree_id                alias for $2;
    p_subtree_category_id    alias for $3;
    p_assign_single_p        alias for $4;
    p_require_category_p     alias for $5;

    v_map_count              integer;
begin
	select count(*) 
	into v_map_count
	from category_tree_map
	where object_id = p_object_id
	and tree_id = p_tree_id;

	if v_map_count = 0 then
	   insert into category_tree_map
	   (tree_id, subtree_category_id, object_id,
	    assign_single_p, require_category_p)
	   values (p_tree_id, p_subtree_category_id, p_object_id,
	           p_assign_single_p, p_require_category_p);
	end if;
        return 0;
end;
' language 'plpgsql';
