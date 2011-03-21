drop function category_synonym__convert_string (varchar);
drop function category_synonym__get_similarity (integer, integer, bigint);
drop function category_synonym__search (varchar, varchar);
drop function category_synonym__reindex (integer, varchar, varchar);
drop function category_synonym__new (varchar, varchar, integer, integer);
drop function category_synonym__del (integer);
drop function category_synonym__edit (integer, varchar, varchar);
drop function category_synonym__edit_cat_trans_trg () cascade;
drop function category_synonym__new_cat_trans_trg () cascade;

drop table category_search_results;
drop table category_search_index;
drop table category_search;
drop table category_synonym_index;
drop table category_synonyms;
drop sequence category_search_id_seq;
drop sequence category_synonyms_id_seq;

-----
-- Synonyms
-----

create table category_synonyms (
	synonym_id	integer not null
			constraint category_synonyms_pk primary key,
	category_id	integer not null
			constraint category_synonyms_cat_fk
			references categories on delete cascade,
	locale		varchar(5) not null
			constraint category_synonyms_locale_fk
			references ad_locales on delete cascade,
	name		varchar(100) not null,
	synonym_p	char(1) default 't'
			constraint category_synonyms_synonym_p_ck
			check (synonym_p in ('t','f'))
);

-- to get all synonyms in given locale
create index category_synonyms_locale_ix on category_synonyms(category_id, locale);
-- to sort synonyms by name
create index category_synonyms_name_ix on category_synonyms(category_id, name);

create sequence category_synonyms_id_seq;

comment on table category_synonyms is '
  Stores multilingual synonyms of the categories.
';
comment on column category_synonyms.synonym_id is '
  Primary key.
';
comment on column category_synonyms.category_id is '
  Category the synonyms are refering to.
';
comment on column category_synonyms.locale is '
  Language of the synonym.
';
comment on column category_synonyms.name is '
  Actual synonym of the category in given language.
';
comment on column category_synonyms.synonym_p is '
  Marks if the entry is a synonym to be edited by user or is a copy
  of a category translation and cannot be edited directly.
';

create table category_synonym_index (
        -- category synonyms split up in 3-grams to be used by fuzzy search
        synonym_id	integer not null
                	constraint category_synonym_index_fk
                	references category_synonyms on delete cascade,
        trigram		char(3) not null
);

-- to get all synonyms of given 3-gram
create index category_syn_index_trigram_ix on category_synonym_index(trigram);
-- to delete all 3-grams of given synonym
create index category_syn_index_synonym_ix on category_synonym_index(synonym_id);

comment on table category_synonym_index is '
  Stores the synonym cut down in portions of 3 characters
  to be used in search.
';
comment on column category_synonym_index.synonym_id is '
  Id of the synonym refered to.
';
comment on column category_synonym_index.trigram is '
  3 character part of the synonym.
';

create table category_search (
        query_id	integer not null
                	constraint category_search_id_pk primary key,
        search_text	varchar(200) not null,
	locale		varchar(5) not null
			constraint category_search_locale_fk
			references ad_locales on delete cascade,
        queried_count	integer default 1 not null,
        last_queried	timestamptz default current_timestamp not null,
        constraint category_search_query_un
	unique (search_text, locale)
);

-- to delete old queries
create index category_search_date_ix on category_search(last_queried);

create sequence category_search_id_seq;

comment on table category_search is '
  Stores users multilingual search texts for category synonyms.
';
comment on column category_search.query_id is '
  Primary key.
';
comment on column category_search.locale is '
  Language of the search text.
';
comment on column category_search.search_text is '
  Actual search text in given language.
';
comment on column category_search.queried_count is '
  Counts how often this search text has been used by users.
';
comment on column category_search.last_queried is '
  Date of last usage of this search text.
  A sweeper will delete search texts not used for a while.
';

create table category_search_index (
        query_id	integer not null
                	constraint category_search_index_fk
                	references category_search on delete cascade,
        trigram		char(3) not null
);

-- to get all search texts of given 3-gram
create index category_search_ind_trigram_ix on category_search_index(trigram);
-- to delete all 3-grams of given search text
create index category_search_ind_query_ix on category_search_index(query_id);

comment on table category_search_index is '
  Stores the search text cut down in portions of 3 characters
  to be used in search.
';
comment on column category_search_index.query_id is '
  Id of the search text refered to.
';
comment on column category_search_index.trigram is '
  3 character part of the search text.
';

create table category_search_results (
        query_id	integer not null
                	constraint category_results_query_fk
                	references category_search on delete cascade,
        synonym_id	integer not null
                	constraint category_results_synonym_fk
                	references category_synonyms on delete cascade,
        similarity	integer not null,
	constraint category_search_results_pk
        primary key (query_id, synonym_id)
);

-- to sort all matches found by similarity
create index category_results_similarity_ix on category_search_results (query_id, similarity);

comment on table category_search_results is '
  Stores the result of a users search in synonyms,
  stores matching synonyms and their degree of similarity
  to the search text.
';
comment on column category_search_results.query_id is '
  Id of the search text.
';
comment on column category_search_results.synonym_id is '
  Id of the synonym found.
';
comment on column category_search_results.similarity is '
  Percent of similarity between search text and found synonym.
';

\i ../category-synonym-package.sql

-- insert existing category translations as synonyms
-- and build synonym index
create function inline_0 ()
returns integer as '
declare
  rec_translations record;
  v_synonym_id integer;
begin
  for rec_translations in
    select category_id, name, locale
    from   category_translations
  loop
    v_synonym_id := category_synonym__new (rec_translations.name, rec_translations.locale, rec_translations.category_id, null);
    update category_synonyms set synonym_p = ''f'' where synonym_id = v_synonym_id;
  end loop;
  return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
