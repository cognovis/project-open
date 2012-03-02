-- 
-- packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-03-02
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');

create or replace function im_dynfield_attribute__new_only_dynfield (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, varchar, char(1), char(1)
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_acs_attribute_id	alias for $7;
	p_widget_name		alias for $8;
	p_deprecated_p		alias for $9;
	p_already_existed_p	alias for $10;

	v_attribute_id		integer;
BEGIN
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = p_acs_attribute_id;
	IF v_attribute_id IS NULL THEN
   	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);


	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, p_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);
	END IF;
	return v_attribute_id;
end;' language 'plpgsql';

create or replace function im_dynfield_attribute__new_only_dynfield (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, varchar, char(1), char(1), integer, varchar, char(1), char(1)
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_acs_attribute_id	alias for $7;
	p_widget_name		alias for $8;
	p_deprecated_p		alias for $9;
	p_already_existed_p	alias for $10;
	p_pos_y			alias for $11;
	p_label_style		alias for $12;
	p_also_hard_coded_p	alias for $13;
	p_include_in_search_p	alias for $14;

	v_count			integer;
        v_attribute_id          integer;
	v_type_category 	varchar;

	row			RECORD;
BEGIN
	SELECT attribute_id INTO v_attribute_id FROM im_dynfield_attributes WHERE acs_attribute_id = p_acs_attribute_id;
	IF v_attribute_id IS NULL THEN
	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, also_hard_coded_p,
		deprecated_p, already_existed_p, include_in_search_p
	) values (
		v_attribute_id, p_acs_attribute_id, p_widget_name, p_also_hard_coded_p,
		p_deprecated_p, p_already_existed_p, p_include_in_search_p
	);

	insert into im_dynfield_layout (
		attribute_id, page_url, pos_y, label_style
	) values (
		v_attribute_id, ''default'', p_pos_y, p_label_style
	);
	END IF;
	
	-- set all im_dynfield_type_attribute_map to "edit"
	select type_category_type into v_type_category from acs_object_types
	where object_type = p_object_type;
	FOR row IN
		select  category_id
		from	im_categories
		where	category_type = v_type_category
	LOOP
		select  count(*) into v_count from im_dynfield_type_attribute_map
		where	object_type_id = row.category_id and attribute_id = v_attribute_id;
		IF 0 = v_count THEN
				insert into im_dynfield_type_attribute_map (
					attribute_id, object_type_id, display_mode
				) values (
					v_attribute_id, row.category_id, ''edit''
				);
		END IF;
	END LOOP;

	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Employees''), ''read'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Employees''), ''write'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Customers''), ''read'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Customers''), ''write'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Freelancers''), ''read'');
	PERFORM acs_permission__grant_permission(v_attribute_id, (select group_id from groups where group_name=''Freelancers''), ''write'');

	return v_attribute_id;
end;' language 'plpgsql';


