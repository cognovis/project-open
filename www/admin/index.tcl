# /packages/calendar/www/admin/index.tcl

ad_page_contract {
    Main Calendar Admin Page. 

    @author Gary Jin (gjin@arsdigita.com)
    @creation-date Dec 14, 2000
    @cvs-id $Id$
}

# find out the user_id 
set user_id [ad_conn user_id]

set package_id [ad_conn package_id]
set page_title [_ calendar.lt_Calendar_Administrati]
set context [list]

db_multirow calendars select_calendars {
    select c.calendar_name, 
           c.calendar_id, 
           c.private_p,
           (select count(*) from cal_items i where i.on_which_calendar = c.calendar_id) as num_items
    from   calendars c
    where  (c.private_p = 'f' and c.package_id = :package_id) or (c.private_p = 't' and c.owner_id = :user_id)
    order  by c.private_p asc, upper(c.calendar_name)
}

template::list::create \
    -name "calendars" \
    -multirow "calendars" \
    -actions [list [_ calendar.lt_Create_a_new_calendar] "calendar-edit"] \
    -elements {
        edit {
            label ""
            display_template {
                <img src="/shared/images/Edit16.gif" height="16" width="16" alt="Edit" style="border:0">
            }
            link_url_eval {[export_vars -base calendar-edit { calendar_id }]}
            sub_class narrow
        }
        calendar_name {
            label {[_ calendar.Calendar_Name]}
            link_url_eval {[export_vars -base calendar-edit { calendar_id }]}
        }
        type {
            label {Type}
            display_eval {[ad_decode $private_p "t" "Personal" "Shared"]}
        }
        num_items {
            label "Items"
            display_eval {[lc_numeric $num_items]}
            html { align right }
        }
        permissions {
            label {Permissions}
            display_template {Permissions}
            link_url_eval {[export_vars -base permissions { { object_id $calendar_id } }]}
            html { align center }
        }
        delete {
            label ""
            display_template {
                <if @calendars.num_items@ eq 0>
                  <img src="/shared/images/Delete16.gif" height="16" width="16" alt="Delete" style="border:0">
                </if>
            }
            link_url_eval {[export_vars -base calendar-delete { calendar_id }]}
            sub_class narrow
        }        
    }

set permissions_url [export_vars -base permissions { { object_id {[ad_conn package_id]} } }]
