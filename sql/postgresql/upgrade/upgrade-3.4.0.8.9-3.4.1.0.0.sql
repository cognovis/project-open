-- upgrade-3.4.0.8.9-3.4.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-forum/sql/postgresql/upgrade/upgrade-3.4.0.8.9-3.4.1.0.0.sql','');

-- Fixing the index column for forum topics.
-- This is important for the intranet-rest interface
-- which relies on this type of meta-information
update acs_object_types
set id_column = 'topic_id'
where object_type = 'im_forum_topic';
