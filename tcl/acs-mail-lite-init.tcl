ad_library {

    initialization for acs_mail_lite module

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March, 2002
    @cvs-id $Id$

}

# Initialize global "variables"
nsv_set acs_mail_lite send_mails_p 0
nsv_set acs_mail_lite check_bounce_p 0


# Schedule processing outgoing mails
set sweeper_interval 120
ad_schedule_proc -thread t $sweeper_interval acs_mail_lite::sweeper

# Schedule processing incoming mails
set queue_interval 120
set queue_dir [acs_mail_lite::get_parameter -name BounceMailDir]
ad_schedule_proc -thread t $queue_interval acs_mail_lite::load_mails -queue_dir $queue_dir

# Schedule for replies
set reply_interval 120
ad_schedule_proc -thread t $reply_interval acs_mail_lite::scan_replies

# Schedule checking for bounces
set bounce_interval [acs_mail_lite::get_parameter -name BounceScanQueue -default 120]
ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 25] acs_mail_lite::check_bounces

