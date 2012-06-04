--
-- Upgrade script
--
-- Adds deputy feature
--
-- Peter Marklund (peter@collaboraid.biz)
--
-- $Id$

---------------------------------
-- Deputies
---------------------------------

-- When a user is away, for example on vacation, he
-- can hand over his workflow roles to some other user - a deputy
create table workflow_deputies (
  user_id             integer
		      constraint workflow_deputies_pk
		      primary key
		      constraint workflow_deputies_uid_fk
		      references users(user_id),
  deputy_user_id      integer
		      constraint workflow_deputies_duid_fk
		      references users(user_id),
  start_date	      date
		      constraint workflow_deputies_sdate_nn
		      not null,
  end_date	      date
		      constraint workflow_deputies_edate_nn
		      not null,
  message	      varchar(4000)
);

-- role-to-user-map with deputies. Does not select users who
-- have deputies, should we do that?
create or replace view workflow_case_role_user_map as
select distinct q.case_id,
       q.role_id,
       q.user_id,
       q.on_behalf_of_user_id
from (
    select rpm.case_id,
           rpm.role_id,
           pmm.member_id as user_id,
           pmm.member_id as on_behalf_of_user_id
    from   workflow_case_role_party_map rpm, 
           party_approved_member_map pmm,
	   users u
    where  rpm.party_id = pmm.party_id
    and    pmm.member_id = u.user_id
    and    not exists (select 1 
                       from workflow_deputies 
                       where user_id = pmm.member_id
                       and sysdate between start_date and end_date)
    union
    select rpm.case_id,
           rpm.role_id,
           dep.deputy_user_id as user_id,
           pmm.member_id as on_behalf_of_user_id
    from   workflow_case_role_party_map rpm, 
           party_approved_member_map pmm,
	   users u,
           workflow_deputies dep
    where  rpm.party_id = pmm.party_id
    and    pmm.member_id = u.user_id
    and    dep.user_id = pmm.member_id
    and    sysdate between dep.start_date and dep.end_date
) q;
