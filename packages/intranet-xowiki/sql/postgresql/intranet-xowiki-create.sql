-- /packages/intranet-xowiki/sql/postgresql/intranet-xowiki-create.sql

-- Xowiki View Component                                                                                                                              
SELECT im_component_plugin__new (
       null, 
       'acs_object', 
       now(), 
       null, 
       null, 
       null, 
       'Xowiki View Cognovis', 
       'intranet-xowiki', 
       'left', 
       '/intranet/projects/view', 
       null, 
       110, 
       'im_xowiki_view_component -object_id $project_id -return_url $return_url'
);
