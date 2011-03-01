# template ID is passed to included template

set live_revision [db_string get_live_revision ""]

# first count all revisions

set revision_count [db_string get_revision_count ""]

set counter $revision_count

db_multirow -extend revision_number revisions get_revisions "" {
  set revision_number $counter
  incr counter -1
}
