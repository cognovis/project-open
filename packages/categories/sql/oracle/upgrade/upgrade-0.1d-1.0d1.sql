--
-- Adding view useful when getting categories for a specific tree
--

create or replace view category_object_map_tree as
  select c.category_id,
         c.tree_id,
         m.object_id
  from   category_object_map m,
         categories c
  where  c.category_id = m.category_id;

