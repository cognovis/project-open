<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-freelance-rfqs/tcl/intranet-freelance-rfqs-procs-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 8c8ca7fd-e2e0-49a3-87c6-4566e4b921ea -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_freelance_info_component.freelance_info_query">
    <querytext>
        select  pe.first_names||' '||pe.last_name as user_name,
                p.email,
                f.*,
                u.user_id,
                im_category_from_id (f.payment_method_id) as payment_method,
                im_category_from_id (f.rec_status_id) as rec_status,
                im_category_from_id (f.rec_test_result_id) as rec_test_result
        from    users u
              LEFT JOIN
                im_freelancers f USING (user_id),
                parties p,
                persons pe
        where   pe.person_id = u.user_id
                and p.party_id = u.user_id
                and u.user_id = :user_id

    </querytext>
  </fullquery>


  <fullquery name="im_freelance_skill_component.column_list">
    <querytext>

select
        sk.skill_id,
        im_category_from_id(sk.skill_id) as skill,
        c.category_id as skill_type_id,
        im_category_from_id(c.category_id) as skill_type,
        im_category_from_id(sk.claimed_experience_id) as claimed,
        im_category_from_id(sk.confirmed_experience_id) as confirmed,
        sk.claimed_experience_id,
        sk.confirmed_experience_id
from
        (select c.*
         from im_categories c
         where c.category_type = 'Intranet Skill Type'
         order by c.category_id
        ) c
      LEFT JOIN
        (select *
         from im_freelance_skills
         where user_id = :user_id
         order by skill_type_id
        ) sk ON sk.skill_type_id = c.category_id
order by
        c.category_id

    </querytext>
  </fullquery>



  <fullquery name="im_freelance_skill_component.skill_body_html">
    <querytext>

select
        sk.skill_id,
        im_category_from_id(sk.skill_id) as skill,
        c.category_id as skill_type_id,
        im_category_from_id(c.category_id) as skill_type,
        im_category_from_id(sk.claimed_experience_id) as claimed,
        im_category_from_id(sk.confirmed_experience_id) as confirmed,
        sk.claimed_experience_id,
        sk.confirmed_experience_id
from
        (select c.*
         from im_categories c
         where c.category_type = 'Intranet Skill Type'
         order by c.category_id
        ) c
      LEFT JOIN
        (select *
         from im_freelance_skills
         where user_id = :user_id
         order by skill_type_id
        ) sk ON sk.skill_type_id = c.category_id
order by
        c.category_id

    </querytext>
  </fullquery>


</queryset>
