alter table category_tree_map add (
	widget                  varchar2(20)
);

comment on column category_tree_map.widget is '
  What widget do we want to use for this cateogry?
';

@@../category-tree-package.sql
