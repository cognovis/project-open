ad_library {
    initialization for spam module
    @author Bill Schneider (bschneid@arsdigita.com)
    @creation-date December 13, 2000
    @cvs-id $Id$
}

# Default interval is 15 minutes.
ad_schedule_proc -thread t 900 spam_sweeper

