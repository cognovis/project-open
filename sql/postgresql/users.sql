

-- Get everything about a user
select
        u.*,
        $freelance_select
        c.*,
	emp.*,
        pe.*,
        pa.*
from
        users u
        $freelance_pg_join
      LEFT JOIN
        persons pe ON u.user_id = pe.person_id
      LEFT JOIN
        parties pa ON u.user_id = pa.party_id
      LEFT JOIN
        users_contact c USING (user_id)
      LEFT JOIN
        im_employees emp ON u.user_id = emp.employee_id
      LEFT JOIN
        country_codes ha_cc ON c.ha_country_code = ha_cc.iso
      LEFT JOIN
        country_codes wa_cc ON c.wa_country_code = wa_cc.iso
where
        u.user_id = :freelance_id
