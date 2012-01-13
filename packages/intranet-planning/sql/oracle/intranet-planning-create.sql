-- /packages/intranet-planning/sql/oracle/intranet-planning-create.sql
--
-- Copyright (C) 1999-2004 various parties
-- The code is based on ArsDigita ACS 3.4
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author        unknown@arsdigita.com
-- @author        frank.bergmann@project-open.com


-- use im_emploee_percentage_time to find out when and how
-- much an employee worked or will work.

-- to figure out "how many people worked in the block
-- starting with start_block, take the sum the percentage_time/100
-- of the rows with that start_block


create table im_employee_percentage_time ( 
	start_block 	date references im_start_blocks, 
	user_id 	integer references users, 
	percentage_time integer, 
	note 		varchar(4000), 
	primary key (start_block, user_id) 
); 

-- need to quickly find percentage_time for a given start_block/user_id
create unique index im_employee_perc_time_idx on 
im_employee_percentage_time (start_block, user_id, percentage_time);

--- im_allocations is used to do predictions and tracking based on
--- percentage of time/project. 

-- im_allocations does not have a separate audit
-- table because we want to take a snapshot of allocation 
-- at a chosed times.


create sequence im_allocations_id_seq;

create table im_allocations (
			--- allocation_id is not the primary key becase
			--- an allocation may be over several blocks of
			--- time. We store a row per block.
			--- To answer the question "what is the allocation for
			--- this time block, query the most recent allocation
			--- for either that allocation_id or user_id.
	allocation_id	integer not null,
	project_id	integer not null references im_projects,
			-- this may be null because we will rows we need to store
			-- rows that are currently not allocated (future hire or
			-- decision is not made)
	user_id		integer	references users,
			-- Allocations are divided up into blocks of time.
			-- Valid dates for start_block must be separated
			-- by the block unit.	For example, if your block unit
			-- was a week, valid start_block dates may be "Sundays"
			-- If the start_blocks don't align, reports get very diff.
	start_block	date references im_start_blocks,
	percentage_time	integer not null,
			--- is this allocation too small to track?
			--- in that case, we will set percentage_time to 0
			-- and mark too_small_to_give_percentage_p = "t"
	too_small_to_give_percentage_p	char(1) default 'f' 
			check (too_small_to_give_percentage_p in ('t','f')), 
	note		varchar(1000),
	last_modified		date not null,
	last_modifying_user	not null references users,
	modified_ip_address	varchar(20) not null
);
create index im_all_alloc_id_idx on im_allocations(allocation_id);
create index im_all_project_id_idx on im_allocations(project_id);
create index im_all_user_id_idx on im_allocations(user_id);
create index im_all_last_mod_idx on im_allocations(last_modified);


create table im_allocations_audit (
	allocation_id	integer not null,
	project_id	integer not null references im_projects,
	user_id		integer	references users,
	-- Allocations are divided up into blocks of time.
	-- Valid dates for start_block must be separated
	-- by the block unit.	For example, if your block unit
	-- was a week, valid start_block dates may be "Sundays"
	-- If the start_blocks don't align, reports get very difficult.
	start_block	date references im_start_blocks,
	percentage_time	integer not null,
	note		varchar(1000),
	last_modified		date not null,
	last_modifying_user	not null references users,
	modified_ip_address	varchar(20) not null
);



--- we will put a row into the im_allocations_audit table if
--- a) another row is added with the same allocation_id and start_block
--- b) another row is added with the same user_id, project_id and start_block

create or replace trigger im_allocations_audit_tr
before update or delete on im_allocations
for each row
begin
insert into im_allocations_audit (
	allocation_id, project_id, user_id, 
	start_block, percentage_time, note, 
	last_modified, last_modifying_user, 
	modified_ip_address
) values (
	:old.allocation_id, :old.project_id, :old.user_id,
	:old.start_block, :old.percentage_time,:old.note, 
	:old.last_modified, :old.last_modifying_user, 
	:old.modified_ip_address
);
end;
/
show errors


create or replace function get_start_week (v_start_date IN date)
return date
IS
	v_date_round date;
	v_date_next_sun date;
	v_date_check date;
BEGIN
	select round(v_start_date, 'day') 
	into v_date_round from dual;

	select trunc(next_day(v_start_date, 'sunday'),'day') 
	into v_date_next_sun from dual;
	
	IF v_date_round < v_date_next_sun THEN
		-- we have the beginning of the week
		return v_date_round;
	END IF;

	v_date_check := v_start_date - 3;
	select round(v_date_check, 'day') into v_date_round from dual;
	IF v_date_round = v_date_next_sun THEN
		--the day is saturday, so we need to subtract one more day
		v_date_check := v_date_check - 1;
		select round(v_date_check, 'day') into v_date_round from dual;
	END IF;
	
	return v_date_round;
END get_start_week;
/
show errors




