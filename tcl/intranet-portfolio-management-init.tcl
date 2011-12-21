# /packages/intranet-portfolio-management/tcl/intranet-portfolio-management-init.tcl
#
# Copyright (C) 2003-2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.




# Initialize the sweeper semaphore to 0.
# There should be only one thread sweeping at any time, even if the thread should be very slow...
nsv_set intranet_portfolio_management sweeper_p 0

# Update the budget, percent_completed, start_date and end_date of programs every few minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-portfolio-management -parameter PortfolioSweeperInterval -default 119] im_program_portfolio_sweeper

