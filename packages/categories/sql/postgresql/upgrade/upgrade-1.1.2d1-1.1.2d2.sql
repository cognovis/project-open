alter table category_tree_map add column widget varchar(20);

drop function category_tree__map ( integer, integer, integer, char, char );

create or replace function category_tree__map (
    integer,   -- object_id
    integer,   -- tree_id
    integer,   -- subtree_category_id
    char,      -- assign_single_p
    char,      -- require_category_p
    varchar    -- widget
)
returns integer as '
declare
    p_object_id              alias for $1;
    p_tree_id                alias for $2;
    p_subtree_category_id    alias for $3;
    p_assign_single_p        alias for $4;
    p_require_category_p     alias for $5;
    p_widget                 alias for $6;

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
	    assign_single_p, require_category_p, widget)
	   values (p_tree_id, p_subtree_category_id, p_object_id,
	           p_assign_single_p, p_require_category_p, p_widget);
	end if;
        return 0;
end;
' language 'plpgsql';
