ad_library {

    Initialization for im_mail_import

    @creation-date 9 August 2005
    @cvs-id $Id$

}

# Initialize the semaphore
nsv_set im_mail_import check_mails_p 0

# Check every few minutes for new mails
ad_schedule_proc -thread t 60 im_mail_import::scan_mails

