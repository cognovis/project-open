-- Fixing type -> status

drop view im_material_status;
drop view im_material_status_active;


create or replace view im_material_status as
select  category_id as material_status_id,
        category as material_status
from im_categories
where category_type = 'Intranet Material Status';


create or replace view im_material_status_active as
select  category_id as material_status_id,
        category as material_status
from im_categories
where   category_type = 'Intranet Material Status'
        and category_id not in (9102);


