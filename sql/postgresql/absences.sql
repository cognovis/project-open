------------------------------------------------------------
-- Absences
------------------------------------------------------------

-- Get everything about a particular absence
select
	a.owner_id,
	a.group_id,
	description,
	contact_info,
	to_char(a.start_date, :date_format) as start_date,
	to_char(a.end_date, :date_format) as end_date,
	im_name_from_user_id(owner_id) as owner_name,
	im_category_from_id(a.absence_type_id) as absence_type
from
	im_user_absences a
where
	a.absence_id = :absence_id;


-- List of absences
select
	a.absence_id,
	a.owner_id,
	a.group_id,
	substring(a.description from 1 for 40) as description,
	substring(a.contact_info from 1 for 40) as contact_info,
	to_char(a.start_date, :date_format) as start_date,
	to_char(a.end_date, :date_format) as end_date,
	im_name_from_user_id(a.owner_id) as owner_name,
	im_category_from_id(a.absence_type_id) as absence_type
from
	im_user_absences a
where
	$where_clause
;


-- Create a new Absence
select im_user_absence__new(...)

-- Update Absence information
UPDATE im_user_absences SET
	owner_id = :owner_id,
	start_date = :start_date,
	end_date = :end_date,
	description = :description,
	contact_info = :contact_info,
	absence_type_id = :absence_type_id
WHERE
	absence_id = :absence_id;


------------------------------------------------------
-- Absences
--
create sequence im_user_absences_id_seq start 1;
create table im_user_absences (
	absence_id		integer
				constraint im_user_absences_pk
				primary key,
	owner_id		integer
				constraint im_user_absences_user_fk
				references users,
	group_id		integer
				constraints im_user_absences_group_fk
				references group,
	start_date		timestamptz
				constraint im_user_absences_start_const not null,
	end_date		timestamptz
				constraint im_user_absences_end_const not null,
	description		text,
	contact_info		text,
	-- should this user receive email during the absence?
	receive_email_p		char(1) default 't'
				constraint im_user_absences_email_const
				check (receive_email_p in ('t','f')),
	last_modified		date,
	absence_type_id		integer
				references im_categories
				constraint im_user_absences_type_const not null
);
