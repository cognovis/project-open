ad_library {
    Initialization for intranet-exchange-rate
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 August, 2011
    @cvs-id $Id: intranet-security-update-client-init.tcl,v 1.2 2011/03/09 12:42:11 po34demo Exp $
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
set enabled_p [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateSweeperEnabledP -default 0]
ns_log Notice "intranet-security-update-client-init: enabled_p = $enabled_p"
if {$enabled_p} {
    ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateSweeperIntervalSeconds -default 61] im_security_update_exchange_rate_sweeper
}
