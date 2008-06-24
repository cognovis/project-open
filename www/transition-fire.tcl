# packages /packages/acs-workflow/www/transition-fire.tcl

ad_page_contract {
  Fire a transition.

  @author rhs@mit.edu
  @creation-date 2000-07-25
  @cvs-id $Id$
} {
  case_id:integer,notnull
  transition_key
} 

wf_message_transition_fire $case_id $transition_key
ad_returnredirect ""

