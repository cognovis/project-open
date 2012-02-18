-- /packages/intranet-fs/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-fs/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');



SELECT apm_package_type__update_type (
       'intranet-fs',		     -- package_key
       null,		   	     -- pretty_name
       null,		   	     -- pretty_plural
       null,		  	     -- package_uri
       'apm_application',  	     -- package_type
       null,			     -- initial_install_p
       null,			     -- singleton_p
       null,			     -- implements_subsite_p
       null,			     -- inherit_templates_p
       null,			     -- spec_file_path
       null			     -- spec_file_mtime
);
      