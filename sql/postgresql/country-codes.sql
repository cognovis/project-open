
-- How to get the contry name from the country code
        select  cc.country_name
        from    country_codes cc
        where   cc.iso = :address_country_code"
;