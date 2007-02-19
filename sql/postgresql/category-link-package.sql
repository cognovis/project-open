--
-- The Categories Package
-- Extension for linking categories
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2004-02-04
--

create or replace function category_link__new (
	integer,   -- from_category_id
	integer    -- to_category_id
) returns integer as '
	-- function for adding category links
declare
	p_from_category_id	alias for $1;
	p_to_category_id	alias for $2;
	v_link_id		integer;
begin
	v_link_id := nextval (''category_links_id_seq'');

	insert into category_links (link_id, from_category_id, to_category_id)
	values (v_link_id, p_from_category_id, p_to_category_id);

	return v_link_id;
end;' language 'plpgsql';

create or replace function category_link__del (
	integer    -- link_id
) returns integer as '
	-- function for deleting category links
declare
	p_link_id	alias for $1;
begin
	delete from category_links
	where link_id = p_link_id;

	return p_link_id;
end;' language 'plpgsql';
