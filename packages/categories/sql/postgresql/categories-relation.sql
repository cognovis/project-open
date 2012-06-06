--
-- Categories Relation 
--
-- @author Miguel Marin (miguelmarin@viaro.net)
-- @author Viaro Networks www.viaro.net
-- @creation-date 2005-07-26
--

create function inline_0 ()
returns integer as '
begin

  -- We create the roles to use them on the rel_type create
  PERFORM acs_rel_type__create_role(''party'', ''Party'', ''Parties'');
  PERFORM acs_rel_type__create_role(''category'', ''Category'', ''Categories'');
  PERFORM acs_rel_type__create_role(''meta_category'', ''Meta Category'', ''Meta Categories'');

  -- Creating two new rel_types
  PERFORM acs_rel_type__create_type (
      ''meta_category_rel'',		-- rel_type 
      ''Meta Category Relation'',       -- pretty_name
      ''Meta Category Relation'',       -- pretty_plural
      ''relationship'',			-- supertype
      ''meta_categories'',		-- table_name
      ''meta_category_id'',		-- id_column 
      null,				-- package_name
      ''category'',		        -- object_type_one 
      ''category'',		        -- role_one
      1,				-- min_n_rels_one
      1,				-- max_n_rels_one 
      ''category'',           		-- object_type_two
      ''category'',		        -- role_two
      1,				-- min_n_rels_two
      1					-- max_n_rels_two
  );

  PERFORM acs_rel_type__create_type (
      ''user_meta_category_rel'',	-- rel_type
      ''User Meta Category Relation'',  -- pretty_name
      ''User Meta Category Relation'',  -- pretty_plural
      ''relationship'',			-- supertype
      ''user_meta_categories'',		-- table_name
      ''user_meta_category_id'',	-- id_column
      null,				-- package_name
      ''meta_category_rel'',		-- object_type_one
      ''meta_category'',		-- role_one
      1,				-- min_n_rels_one
      1,				-- max_n_rels_one
      ''party'',			-- object_type_two
      ''party'',			-- role_two
      1,				-- min_n_rels_two
      1					-- max_n_rels_two
  );

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();
