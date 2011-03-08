# Display the site contributions
# If user_id set it will be limited by that user otherwise all users.
# if limit set then only limit items will be displayed.
# if root_node_id exists then only return things under root node.
set root_node_id [ad_conn node_id]

if {![info exists user_id]} {
    set user_id {}
}
if {![info exists category]} {
    set category {}
}
if {[info exists supress]} {
    foreach key $supress { 
        set hide($key) 1
    }
}

if {[info exists limit]
    && [regexp {^[0-9]+$} $limit]} { 
    set limit " limit $limit"
} else { 
    set limit {}
}

if {![info exists format]} {
    set format table
}

if {[info exists root_node_id]} {
    set packages [subsite::util::packages -node_id $root_node_id]
} else {
    set packages {}
}

lappend elements object_title {
    label {Title}
    display_template {<a href="/o/@content.object_id@">@content.title@</a>}
}

if {![info exists hide(pretty_name)]} { 
    lappend elements pretty_name {
        label {Type}
        display_template {<a href="/o/@content.object_id@">@content.object_type@</a>}
    }
}

lappend elements last_modified {
    label {Last update}
    display_template "@content.last_modified;noquote@"
    html {align right}
}

# lappend elements new {
#    label {New}
#    display_template "@content.new;noquote@"
#    html {align right}
#}

if {$user_id eq ""} {
    lappend elements name {
        label {Created by}
        display_template {<a href="@content.user_url@" title="Member page">@content.name@</a>}
    }
}

template::list::create \
    -name content \
    -multirow content \
    -key object_id \
    -elements $elements \
    -selected_format $format \
    -filters {
        user_id {}
    } \
    -formats {
        table { 
            label Table
            layout table
        }
        list { 
            label List
            layout list
            template {
                <div style="padding: 0 0 1em 0;"><listelement name="object_title"> \[<listelement name="pretty_name">\] - <listelement name="new"><br>
                <span style="color: \#ccc;">by <listelement name="name">, <listelement name="last_modified"></span></div>
            }
        } 
    } \
    -orderby {
        object_title {
            orderby lower(o.title)
        }
        pretty_name {
            orderby lower(t.pretty_name)
        }
        last_modified {
            orderby_asc {o.last_modified desc}
            orderby_desc {o.last_modified asc}
        }
        name {
            orderby_asc "lower(u.last_name),lower(u.first_names)"
            orderby_desc "lower(u.last_name) desc,lower(u.first_names) desc"
        }
    }

set now [clock_to_ansi [clock seconds]]

set restrict {}

if {$user_id ne ""} {
    append restrict "\nand o.creation_user = :user_id"
}

if {$category ne ""} {
    append restrict "\nand exists (select 1 from category_object_map c where c.object_id = o.object_id and c.category_id = :category)"
}

if {$packages ne ""} {
    append restrict "\nand o.package_id in ([join $packages ,])"
}

# JCDXXX: TODO: need to get the dimension to display, need to find the right CoP, permissions
db_multirow -extend {url_one user_url new} content content "
    SELECT o.title, o.object_id, o.title, t.pretty_name as object_type, to_char(o.last_modified,'YYYY-MM-DD HH24:MI:SS') as last_modified, u.user_id, u.first_names || ' ' || u.last_name as name
      FROM acs_object_types t, acs_objects o
           left outer join cr_items i on (o.object_id = i.item_id)
           left outer join acs_users_all u on (u.user_id = o.creation_user)
     WHERE t.object_type = case when o.object_type = 'content_item' then i.content_type else o.object_type end
       and o.object_type in ('content_item','pinds_blog_entry','forums_forum','forums_message',
           'cal_item','bt_bug','bt_patch', 'news', 'faq', 'faq_q_and_a', 'bookshelf_book', 'job_posting','survey')
       and (o.object_type != 'content_item' or i.content_type in ('content_extlink','file_storage_object','pa_album','pa_photo','static_page','news','job', 'content_revision'))
       $restrict
   [template::list::orderby_clause -orderby -name "content"]$limit" {

       # TODO: JCDXXX - make this work in general.
       if {($object_id % 3) == 0} {
           set new {<span class="new" style="color: red">NEW</span>}
       } else { 
           set new {}
       }

       # TODO: JCDXXX - make this work in general.
       regsub {/www/cop1/static} $title {} title

       set last_modified [regsub -all { } [util::age_pretty -hours_limit 0 -mode_2_fmt "%X %a" -mode_3_fmt "%x" -timestamp_ansi $last_modified -sysdate_ansi $now] {\&nbsp;}]
       set user_url [acs_community_member_url -user_id $user_id]
       if {[catch {set url_one [acs_sc_call -error FtsContentProvider url [list $object_id] $object_type]} errMsg]} {
           global errorCode
           set url_one $errorCode
       }
   }