-- /packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d10-0.5d11.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d10-0.5d11.sql','');


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_attribute_id	integer;
	v_min_n_values	integer;
	v_count		integer;
	v_required_p	char;
	
BEGIN
	-- Task
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_name'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;


	-- Task Nr.
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_nr'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;


	-- Project
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''parent_id''; 

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Task Status
        	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_status_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Task Type
        	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''project_type_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Unit of Measure
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''uom_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Cost Center
       	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''cost_center_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Material ID
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''material_id'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''none'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''none'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Planned Units
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''planned_units'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

 
	-- Billable Units
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''billable_units'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Percent Completed
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''percent_completed'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Start Date
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''start_date'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''display'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''display'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- End Date
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''end_date'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;

	-- Description
	SELECT ida.attribute_id INTO v_attribute_id FROM im_dynfield_attributes ida, acs_attributes aa WHERE aa.attribute_id = ida.acs_attribute_id AND object_type = ''im_timesheet_task'' AND aa.attribute_name = ''description'';

	SELECT aa.min_n_values INTO v_min_n_values FROM acs_attributes aa, im_dynfield_attributes ida WHERE ida.attribute_id = v_attribute_id AND aa.attribute_id = ida.acs_attribute_id;


	IF v_attribute_id IS NOT NULL THEN
	   SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = 100;
	   IF v_count = 0 THEN
	      IF v_min_n_values > 0 THEN
	      	 v_required_p = ''t'';
	      ELSE
		 v_required_p = ''f'';
	      END IF;

	      INSERT INTO im_dynfield_type_attribute_map
	      	     (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
	      VALUES
		     (v_attribute_id, 100,''edit'',null,null,null,v_required_p);
	   ELSE
	      UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'' WHERE attribute_id = v_attribute_id AND object_type_id = 100;
           END IF;
	END IF;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();