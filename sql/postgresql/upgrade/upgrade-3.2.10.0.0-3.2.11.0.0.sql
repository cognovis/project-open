-- upgrade-3.2.10.0.0-3.2.11.0.0.sql



create or replace function persons_tsearch ()
returns trigger as '
declare
        v_string        varchar;
begin
        select  coalesce(pa.email, '''') || '' '' ||
                coalesce(pa.url, '''') || '' '' ||
                coalesce(pe.first_names, '''') || '' '' ||
                coalesce(pe.last_name, '''') || '' '' ||
                coalesce(u.username, '''') || '' '' ||
                coalesce(u.screen_name, '''') || '' '' ||

                coalesce(home_phone, '''') || '' '' ||
                coalesce(work_phone, '''') || '' '' ||
                coalesce(cell_phone, '''') || '' '' ||
                coalesce(pager, '''') || '' '' ||
                coalesce(fax, '''') || '' '' ||
                coalesce(aim_screen_name, '''') || '' '' ||
                coalesce(msn_screen_name, '''') || '' '' ||
                coalesce(icq_number, '''') || '' '' ||

                coalesce(ha_line1, '''') || '' '' ||
                coalesce(ha_line2, '''') || '' '' ||
                coalesce(ha_city, '''') || '' '' ||
                coalesce(ha_state, '''') || '' '' ||
                coalesce(ha_postal_code, '''') || '' '' ||

                coalesce(wa_line1, '''') || '' '' ||
                coalesce(wa_line2, '''') || '' '' ||
                coalesce(wa_city, '''') || '' '' ||
                coalesce(wa_state, '''') || '' '' ||
                coalesce(wa_postal_code, '''') || '' '' ||

                coalesce(note, '''') || '' '' ||
                coalesce(current_information, '''') || '' '' ||

                coalesce(ha_cc.country_name, '''') || '' '' ||
                coalesce(wa_cc.country_name, '''')

        into    v_string
        from
                parties pa,
                persons pe
                LEFT OUTER JOIN users u ON (pe.person_id = u.user_id)
                LEFT OUTER JOIN users_contact uc ON (pe.person_id = uc.user_id)
                LEFT OUTER JOIN country_codes ha_cc ON (uc.ha_country_code = ha_cc.iso)
                LEFT OUTER JOIN country_codes wa_cc ON (uc.wa_country_code = wa_cc.iso)
        where
                pe.person_id  = new.person_id
                and pe.person_id = pa.party_id
        ;

        perform im_search_update(new.person_id, ''user'', new.person_id, v_string);
        return new;
end;' language 'plpgsql';


