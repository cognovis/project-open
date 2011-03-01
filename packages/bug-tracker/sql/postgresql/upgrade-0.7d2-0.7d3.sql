
-- Added resolution code to bt_bug_actions

alter table bt_bug_actions add column
  resolution                    varchar(50)
                                constraint bt_bugs_resolution_ck
                                check (resolution is null or 
                                       resolution in ('fixed','bydesign','wontfix','postponed','duplicate','norepro'));
