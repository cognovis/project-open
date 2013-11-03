-- upgrade-4.0.5.0.2-4.0.5.0.3.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.5.0.3-4.0.5.0.4.sql','');

create or replace function inline_0 () returns integer as $body$
        DECLARE
                v_max_column_id     integer;
		v_count		    integer;
        BEGIN
		-- avoid creating the col twice 
		select count(*) into v_count from im_view_columns where column_name = '"Member State"' and view_id = 11;
		IF v_count != 0  THEN
		   raise notice 'ERROR: Not creating column "member_state", already exists (/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.5.0.3-4.0.5.0.4.sql)';
		   return 1;
		END IF; 

		-- get column_id 
		select max(column_id) into v_max_column_id from im_view_columns;
		v_max_column_id := v_max_column_id +1;

		insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
		extra_select, extra_where, sort_order, visible_for) values (v_max_column_id,11,NULL,'"Member State"',
		'[ _ intranet-core.MemberState_$member_state]','','',3,'expr $write+0');

               	return 1;
	EXCEPTION when others then 
		raise notice 'ERROR: Was not able to create column "member_state" (/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.5.0.3-4.0.5.0.4.sql)';
		raise notice '% %', SQLERRM, SQLSTATE;
		return 0;
	END;
$body$ language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


-- This is a critical user attribute - make sure the keys are available, eventhough the catalogs have not neen imported yet
create or replace function inline_0 () returns integer as $body$
        DECLARE
                foo     integer;
        BEGIN
                SELECT im_lang_add_message('en_US','intranet-core','MemberState_approved','Active') into foo;
                SELECT im_lang_add_message('en_US','intranet-core','MemberState_banned','Deleted') into foo;
                return 1;
        EXCEPTION when others then
                raise notice 'ERROR: Was not able to create message keys MemberState_approved / MemberState_banned (/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.5.0.3-4.0.5.0.4.sql)';
                raise notice '% %', SQLERRM, SQLSTATE;
                return 0;
        END;
$body$ language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();


