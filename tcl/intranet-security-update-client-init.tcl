ad_library {
    Initialization for intranet-exchange-rate
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 August, 2011
    @cvs-id $Id$
}



# ---------------------------------------------------------------
# Scheduled Actions
#
# Periodically check for new exchange rates
# ---------------------------------------------------------------


# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_security_update_client sweeper_p 0

# Check for changed files every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateSweeperIntervalSeconds -default 61] im_security_update_exchange_rate_sweeper

