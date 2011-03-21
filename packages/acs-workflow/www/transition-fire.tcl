# packages /packages/acs-workflow/www/transition-fire.tcl

ad_page_contract {
  Fire a transition.

  @author rhs@mit.edu
  @creation-date 2000-07-25
  @cvs-id $Id: transition-fire.tcl,v 1.2 2008/06/24 17:26:24 cvs Exp $
} {
  case_id:integer,notnull
  transition_key
} 

wf_message_transition_fire $case_id $transition_key
ad_returnredirect ""

