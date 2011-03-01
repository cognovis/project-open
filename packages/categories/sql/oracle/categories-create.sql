--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

begin
          -- create the object types
 
        acs_object_type.create_type (
                supertype       =>      'acs_object',
                object_type     =>      'category_tree',
                pretty_name     =>      'Category Tree',
                pretty_plural   =>      'Category Trees',
                table_name      =>      'category_trees',
                id_column       =>      'tree_id',
                name_method     =>      'category_tree.name'
        );
        acs_object_type.create_type (
                supertype       =>      'acs_object',
                object_type     =>      'category',
                pretty_name     =>      'Category',
                pretty_plural   =>      'Categories',
                table_name      =>      'categories',
                id_column       =>      'category_id',
                name_method     =>      'category.name'
        );
end;
/
show errors

create table category_trees (
       tree_id			integer primary key constraint cat_trees_tree_id_fk references acs_objects on delete cascade,
       site_wide_p		char(1) default 't' constraint cat_trees_site_wide_p_ck check (site_wide_p in ('t','f'))
);

comment on table category_trees is '
  This is general data for each category tree.
';
comment on column category_trees.tree_id is '
  ID of a tree.
';
comment on column category_trees.site_wide_p is '
  Declares if a tree is site-wide or local (only usable by users/groups
  that have permissions).
';

create table category_tree_translations (
       tree_id			integer constraint cat_tree_trans_tree_id_fk references category_trees on delete cascade,
       locale		        varchar2(5) not null constraint cat_tree_trans_locale_fk references ad_locales,
       name			varchar2(50) not null,
       description		varchar2(1000),
       primary key (tree_id, locale)
);

comment on table category_tree_translations is '
  Translations for names and descriptions of trees in different languages.
';
comment on column category_tree_translations.tree_id  is '
  ID of a tree (see category_trees).
';
comment on column category_tree_translations.locale is '
  ACS-Lang style locale if language ad country.
';
comment on column category_tree_translations.name is '
  Name of the tree in the specified language.
';
comment on column category_tree_translations.description is '
  Description of the tree in the specified language.
';

create table categories (
       category_id		    integer primary key constraint cat_category_id_fk references acs_objects on delete cascade,
       tree_id			    integer constraint cat_tree_id_fk references category_trees on delete cascade,
       parent_id		    integer constraint cat_parent_id_fk references categories,
       deprecated_p		    char(1) default 'f' constraint cat_deprecated_p_ck check (deprecated_p in ('t','f')),
       left_ind			    integer,
       right_ind		    integer
);

create unique index categories_left_ix on categories(tree_id, left_ind);
create unique index categories_parent_ix on categories(parent_id, category_id);
analyze table categories compute statistics;

comment on table categories is '
  Information about the categories in the tree structure.
';
comment on column categories.category_id is '
  ID of a category.
';
comment on column categories.tree_id is '
  ID of a tree (see category_trees).
';
comment on column categories.parent_id is '
  Points to a parent category in the tree or null (if topmost category).
';
comment on column categories.deprecated_p is '
  Marks categories to be no longer supported.
';
comment on column categories.left_ind is '
  Left index in nested set structure of a tree.
';
comment on column categories.right_ind is '
  Right index in nested set structure of a tree.
';

create table category_translations (
       category_id	    integer constraint cat_trans_category_id_fk references categories on delete cascade,
       locale		    varchar2(5) not null constraint cat_trans_locale_fk references ad_locales,
       name		    varchar2(200),
       description	    varchar2(4000),
       primary key (category_id, locale)
);

comment on table category_translations is '
  Translations for names and descriptions of categories in different languages.
';
comment on column category_translations.category_id is '
  ID of a category (see categories).
';
comment on column category_translations.locale is '
  ACS-Lang style locale if language ad country.
';
comment on column category_translations.name is '
  Name of the category in the specified language.
';
comment on column category_translations.description is '
  Description of the category in the specified language.
';

create table category_tree_map (
	tree_id			integer constraint cat_tree_map_tree_id_fk references category_trees on delete cascade,
	object_id		integer constraint cat_tree_map_object_id_fk references acs_objects on delete cascade,
	subtree_category_id	integer default null constraint cat_tree_map_subtree_id_fk references categories,
	assign_single_p		char(1) default 'f' constraint cat_tree_map_single_p_ck check (assign_single_p in ('t','f')),
	require_category_p	char(1) default 'f' constraint cat_tree_map_categ_p_ck check (require_category_p in ('t','f')),
	widget                  varchar2(20),
	primary key (object_id, tree_id)
) organization index;

create unique index cat_tree_map_ix on category_tree_map(tree_id, object_id);

comment on table category_tree_map is '
  Maps trees to objects (usually package instances) so that
  other objects can be categorized.
';
comment on column category_tree_map.tree_id is '
  ID of the mapped tree (see category_trees).
';
comment on column category_tree_map.object_id is '
  ID of the mapped object (usually an apm_package if trees are to be used
  in a whole package instance, i.e. file-storage).
';
comment on column category_tree_map.subtree_category_id is '
  If a subtree is mapped, then this is the ID of the category on top
  of the subtree, null otherwise.
';
comment on column category_tree_map.assign_single_p is '
  Are the users allowed to assign multiple or only a single category
  to objects?
';
comment on column category_tree_map.require_category_p is '
  Do the users have to assign at least one category to objects?
';
comment on column category_tree_map.widget is '
  What widget do we want to use for this cateogry?
';

create table category_object_map (
       category_id		     integer constraint cat_object_map_category_id_fk references categories on delete cascade,
       object_id		     integer constraint cat_object_map_object_id_fk references acs_objects on delete cascade,
       primary key (category_id, object_id)
) organization index;

create unique index cat_object_map_ix on category_object_map(object_id, category_id);

comment on table category_object_map is '
  Maps categories to objects and thus categorizes and object.
';
comment on column category_object_map.category_id is '
  ID of the mapped category (see categories).
';
comment on column category_object_map.object_id is '
  ID of the mapped object.
';

create global temporary table category_temp (
	category_id	integer
) on commit delete rows;

comment on table category_temp is '
  Used mainly for multi-dimensional browsing to use only bind vars
  in queries
';

create or replace view category_object_map_tree as
  select c.category_id,
         c.tree_id,
         m.object_id
  from   category_object_map m,
         categories c
  where  c.category_id = m.category_id;

-----
-- category links
-----

create table category_links (
	link_id			integer not null
				constraint category_links_pk primary key,
	from_category_id	integer not null
				constraint category_links_from_fk
				references categories on delete cascade,
	to_category_id		integer not null
				constraint category_links_to_fk
				references categories on delete cascade,
	constraint category_links_un
	unique (from_category_id, to_category_id)
);

create unique index category_links_rev_ix on category_links (to_category_id, from_category_id);

create sequence category_links_id_seq;

comment on table category_links is '
  Stores directed graph of linked categories. If category A
  and category B are linked, then any categorization on A
  will result in an additional categorization in B.
';
comment on column category_links.link_id is '
  Primary key.
';
comment on column category_links.from_category_id is '
  Category the link is coming from. Any categorization in this
  category will trigger a categorization in the other category.
';
comment on column category_links.to_category_id is '
  Category the link is coming to. Any categorization in the other
  category will trigger a categorization in this category.
';


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
        last_queried	date default sysdate not null,
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



@@category-tree-package.sql
@@category-package.sql
@@category-link-package.sql
@@category-synonym-package.sql

@@categories-permissions.sql

@@categories-init.sql
