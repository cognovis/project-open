-- upgrade-3.4.0.2.0-3.4.0.3.0.sql

-- Creation
alter table im_tickets add
ticket_creation_date            timestamptz;

-- First human reaction from provider side
alter table im_tickets add
ticket_reaction_date            timestamptz;

-- Confirmation that this is an issue
alter table im_tickets add
ticket_confirmation_date        timestamptz;

-- Provider says ticket is done
alter table im_tickets add
ticket_done_date                timestamptz;

-- Customer confirms ticket is done
alter table im_tickets add
ticket_signoff_date             timestamptz;


