--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

drop table category_search_results;
drop table category_search_index;
drop table category_search;
drop table category_synonym_index;
drop table category_synonyms;
drop sequence category_search_id_seq;
drop sequence category_synonyms_id_seq;
drop trigger ins_synonym_on_ins_transl_trg;
drop trigger upd_synonym_on_upd_transl_trg;

drop table category_links;
drop sequence category_links_id_seq;

drop table category_temp;

drop table category_object_map;

drop table category_tree_map;

drop table category_translations;

drop table categories;

drop table category_tree_translations;

drop table category_trees;

delete from acs_permissions where object_id in
  (select object_id from acs_objects where object_type = 'category_tree');
delete from acs_objects where object_type='category';
delete from acs_objects where object_type='category_tree';


begin
   acs_object_type.drop_type('category', 't');
   acs_object_type.drop_type('category_tree', 't');
end;
/
show errors

delete from acs_permissions
    where privilege in
        ('category_tree_write','category_tree_read',
          'category_tree_grant_permissions','category_admin');

delete from acs_privilege_hierarchy
    where privilege in
        ('category_tree_write','category_tree_read',
          'category_tree_grant_permissions','category_admin');

delete from acs_privilege_hierarchy
    where child_privilege in
        ('category_tree_write','category_tree_read',
          'category_tree_grant_permissions','category_admin');

delete from acs_privileges
    where privilege in
        ('category_tree_write','category_tree_read',
          'category_tree_grant_permissions','category_admin');
/

drop package category_synonym;
drop package category_link;
drop package category_tree;
drop package category;
