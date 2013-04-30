create sequence ad_monitoring_top_df_id start 1;


create table ad_monitoring_df (
    df_id                      integer primary key,
    timestamp                   timestamptz default current_timestamp
);


create sequence ad_monitoring_top_df_item_id start 1;


create table ad_monitoring_top_df_item (
    df_item_id                  integer primary key,
    df_id                      integer not null  references ad_monitoring_df,
    filesystem                 varchar(30) not null, 
    size                       varchar(10) not null,
    used                       varchar(10) not null,
    avail                      varchar(10) not null,
    used_percent               varchar(10) not null,
    mounted                    varchar(30) not null
);
