-- packages/acs-events/sql/recurrence-create.sql
--
-- Support for temporal recurrences
--
-- $Id: recurrence-create.sql,v 1.3 2003/09/30 12:10:02 mohanp Exp $

-- These columns describe how an event recurs.  The are modeled on the Palm DateBook.
-- The interval_type 'custom' indicates that the PL/SQL function referenced in
-- custom_func should be used to generate the recurrences.

-- Sequence for recurrence tables

create sequence recurrence_seq start with 1;

create table recurrence_interval_types (
    interval_type   integer
                    constraint recurrence_interval_type_pk primary key,
    interval_name   varchar2(50) not null
                    constraint rit_interval_name_un unique
);

set feedback off;
  
insert into recurrence_interval_types values (1,'day');
insert into recurrence_interval_types values (2,'week');
insert into recurrence_interval_types values (3,'month_by_date');
insert into recurrence_interval_types values (4,'month_by_day');
insert into recurrence_interval_types values (5,'last_of_month');
insert into recurrence_interval_types values (6,'year');
insert into recurrence_interval_types values (7,'custom');

set feedback on;

create table recurrences (
    recurrence_id        integer
                         constraint recurrences_pk primary key,
    --
    -- Indicate the interval type for recurrence (see above)
    --
    interval_type           constraint recurs_interval_type_fk
                            references recurrence_interval_types not null,
    --
    -- Indicates how many of the given intervals between recurrences.
        -- Must be a positive number!
    --
    every_nth_interval   integer
                         constraint recurs_every_nth_interval_ck
                         check(every_nth_interval > 0),
    --
    -- If recurring on a weekly basis (interval_type = 'week')
    -- indicates which days of the week the event recurs on.
    -- This is represented as a space separated list of numbers
    -- corresponding to days of the week, where 0 corresponds to
    -- Sunday, 1 to Monday, and so on.  Null indicates no days are set.  
    -- So for example, '1' indicates recur on Mondays, '3 5' indicates
    -- recur on Wednesday and Friday.
    --
    days_of_week         varchar2(20),
    --
    -- Indicates when this event should stop recurring.  Null indicates
    -- recur indefinitely.
    --
    recur_until          date,
    --
    -- Recurring events can be only partially populated if fully populating
    -- the events would require inserting too many instances.  This
    -- column indicates up to what date this event has recurred.  This
    -- allows further instances to be added if the user attempts to view
    -- a date beyond db_populated_until.  If recur_until is not null, 
    -- then this column will always be prior to or the same as recur_until.
    -- This column will be null until some recurrences have been added.
    --
    db_populated_until   date,
    --
    -- This column holds the name of a PL/SQL function that will be called
    -- to generate dates of recurrences if interval_type is 'custom'
    --
    custom_func          varchar2(255)
);

-- This is important to prevent locking on update of master table.
-- See  http://www.arsdigita.com/bboard/q-and-a-fetch-msg.tcl?msg_id=000KOh
create index recurrences_interval_type_idx on recurrences(interval_type);

comment on table recurrences is '
    Desribes how an event recurs.
';

comment on column recurrences.interval_type is '
    One of day, week, month_by_date, month_by_day, last_of_month, year, custom.
';

comment on column recurrences.every_nth_interval is '
    Indicates how many of the given intervals between recurrences.
';

comment on column recurrences.days_of_week is '
    For weekly recurrences, stores which days of the week the event recurs on.
';

comment on column recurrences.recur_until is '
    Indicates when this event should stop recurring.  Null indicates
    recur indefinitely.
';
        
comment on column recurrences.db_populated_until is '
    Indicates the date of the last recurrence added. Used to determine if more
    recurrences need to be added.
';

comment on column recurrences.custom_func is '
    Stores the name of a PL/SQL function that can be called to generate dates
    for special recurrences.
';

-- Recurrence API
--
-- Currently supports only new and delete methods.
--

create or replace package recurrence
as
    function new (
         -- Creates a new recurrence
         -- @author W. Scott Meeks
         -- @param interval_type        Sets interval_type of new recurrence
         -- @param every_nth_interval   Sets every_nth_interval of new recurrence
         -- @param days_of_week         optional If provided, sets days_of_week
         --                                  of new recurrence
         -- @param recur_until          optional If provided, sets recur_until
         --                                  of new recurrence
         -- @param custom_func          optional If provided, set name of 
         --                                  custom recurrence function
         -- @return id of new recurrence
         --
         interval_type          in recurrence_interval_types.interval_name%TYPE,
         every_nth_interval     in recurrences.every_nth_interval%TYPE,
         days_of_week           in recurrences.days_of_week%TYPE default null,
         recur_until            in recurrences.recur_until%TYPE default null,
         custom_func            in recurrences.custom_func%TYPE default null
    ) return recurrences.recurrence_id%TYPE;

    procedure del (
         -- Deletes the recurrence
         -- @author W. Scott Meeks
         -- @param recurrence_id id of recurrence to delete
         --
         recurrence_id          in recurrences.recurrence_id%TYPE
    );
  
end recurrence;
/
show errors

create or replace package body recurrence
as
    function new (
         interval_type          in recurrence_interval_types.interval_name%TYPE,
         every_nth_interval     in recurrences.every_nth_interval%TYPE,
         days_of_week           in recurrences.days_of_week%TYPE default null,
         recur_until            in recurrences.recur_until%TYPE default null,
         custom_func            in recurrences.custom_func%TYPE default null
    ) return recurrences.recurrence_id%TYPE
    is
        recurrence_id recurrences.recurrence_id%TYPE;
        interval_type_id recurrence_interval_types.interval_type%TYPE;
    begin
        select recurrence_seq.nextval into recurrence_id from dual;
        
        select interval_type
        into   interval_type_id 
        from   recurrence_interval_types
        where  interval_name = new.interval_type;
        
        insert into recurrences
            (recurrence_id, 
             interval_type, 
             every_nth_interval, 
             days_of_week,
             recur_until, 
             custom_func)
        values
            (recurrence_id, 
             interval_type_id, 
             every_nth_interval, 
             days_of_week,
             recur_until, 
             custom_func);
         
        return recurrence_id;
    end new;

    -- Note: this will fail if there are any events_with this recurrence
    procedure del (
         recurrence_id in recurrences.recurrence_id%TYPE
    )
    is
    begin
        delete from recurrences
        where  recurrence_id = recurrence.del.recurrence_id;
    end del;

end recurrence;
/
show errors
