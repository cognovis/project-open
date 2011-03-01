set page_title "Add Comment"

request create -params {
  item_id -datatype integer 
}

set item_title [db_string get_title ""]

form create add_comment -elements "
  journal_id -datatype integer -widget hidden
  object_id -datatype integer -widget hidden -value $item_id
  item_title -datatype text -widget inform -value $item_title \
      -label {Item Title}
  msg -datatype text -widget textarea -html { rows 10 cols 40 } \
      -label {Message}
"

if { [form is_request add_comment] } {
    set journal_id [db_string get_journal_id ""]
    element set_properties add_comment journal_id -value $journal_id
}

if { [form is_valid add_comment] } {

  form get_values add_comment journal_id object_id msg

  set user_id [User::getID]
  set ip_address [ns_conn peeraddr]

  db_transaction {
      set journal_id [db_exec_plsql new_entry "
    begin
      :1 := journal_entry.new(
                             journal_id => :journal_id,
                             object_id => :object_id,
                             action => 'comment',
                             action_pretty => 'Comment',
                             creation_user => :user_id,
                             creation_ip  => :ip_address,
                             msg => :msg );
    end;"]

  }

  set query "
  select
    rel_id, relation_tag, 
    i.item_id, i.name, trim(r.title) as title, t.pretty_name, 
    to_char(o.creation_date, 'MM/DD/YY HH24:MM') last_modified
  from
    cr_items i, acs_object_types t, acs_objects o, cr_revisions r,
    cr_child_rels c
  where
    i.parent_id = :item_id
  and
    o.object_id = :item_id
  and
    i.content_type = t.object_type
  and
    r.revision_id = NVL(i.live_revision, i.latest_revision)
  and
    c.parent_id = i.parent_id
  and
    c.child_id = i.item_id
  order by
    t.pretty_name, title"

#template::query children multirow $query




  template::forward "index?item_id=$object_id"
}
