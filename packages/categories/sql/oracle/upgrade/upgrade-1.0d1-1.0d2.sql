alter table category_tree_map add (
	assign_single_p		char(1) default 'f' constraint cat_tree_map_single_p_ck check (assign_single_p in ('t','f')),
	require_category_p	char(1) default 'f' constraint cat_tree_map_categ_p_ck check (require_category_p in ('t','f'))
);

comment on column category_tree_map.assign_single_p is '
  Are the users allowed to assign multiple or only a single category
  to objects?
';

@@../category-tree-package.sql
