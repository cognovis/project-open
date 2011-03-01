alter table bt_severity_codes add column 
  default_p                     char(1) not null
                                constraint bt_severity_codes_default_p_ck
                                check (default_p in ('t','f'))
                                default 'f';

update bt_severity_codes set default_p = 't' where sort_order = 3;

alter table bt_priority_codes add column
  default_p                     char(1) not null
                                constraint bt_priority_codes_default_p_ck
                                check (default_p in ('t','f'))
                                default 'f';

update bt_priority_codes set default_p = 't' where sort_order = 2;

