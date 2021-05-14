
ALTER TABLE  psit.bibtex
    ADD CONSTRAINT ref_id PRIMARY KEY ("UT");
ALTER TABLE  psit.birdlife
    ADD CONSTRAINT spp_id PRIMARY KEY (scientific_name);
ALTER TABLE  psit.countries
    ADD CONSTRAINT alpha2 PRIMARY KEY ("Alpha_2");

CREATE TABLE IF NOT EXISTS psit.actions (
  trade_chain varchar(100),
  aims varchar(100),
  action_type varchar(100),
  action varchar(100),
  PRIMARY KEY (action)
);

CREATE TYPE contribution_type AS ENUM ('basic knowledge' , 'implementation', 'monitoring');

CREATE TABLE IF NOT EXISTS psit.annotate_ref (
  ref_id varchar(255),
  contribution contribution_type,
  action varchar(100),
  data_type text[],
  country_list text[],
  species_list text[],
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id,contribution,action)
);
ALTER TABLE psit.annotate_ref  ADD CONSTRAINT annotate_ref_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE psit.annotate_ref  ADD CONSTRAINT annotate_ref_action_fkey FOREIGN KEY(action) REFERENCES psit.actions(action) ON DELETE CASCADE ON UPDATE CASCADE;

-- ALTER TABLE psit.annotate_ref ADD COLUMN data_type2 text[];
-- update psit.annotate_ref set data_type=REPLACE(data_type,'{','');
-- update psit.annotate_ref set data_type=REPLACE(data_type,'}','');
--
-- update psit.annotate_ref set data_type2[1]=data_type
-- where data_type not like '%,%';
--
-- update psit.annotate_ref set data_type2[1]='interview'
-- where data_type like 'interview,%';
-- update psit.annotate_ref set data_type2[1]='official report'
-- where data_type like 'oficial report,%';
--
-- update psit.annotate_ref set data_type2[2]='cites'
-- where data_type like '%,cites%';
-- update psit.annotate_ref set data_type2[3]='cites'
-- where data_type like '%,%,cites%';
--
-- update psit.annotate_ref set data_type2[2]='review literature'
-- where data_type like '%,review literature%';
-- update psit.annotate_ref set data_type2[2]='field survey'
-- where data_type like '%,field survey%';
-- select data_type,data_type2 from psit.annotate_ref where data_type like '%,%';
--
-- ALTER TABLE psit.annotate_ref DROP COLUMN data_type;
-- ALTER TABLE psit.annotate_ref RENAME COLUMN data_type2 TO data_type;


--
-- CREATE TABLE IF NOT EXISTS psit.filtro1 (
--   keyword varchar(255),
--   status varchar(10),
--   reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
--   reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   PRIMARY KEY (keyword)
-- );


CREATE TABLE IF NOT EXISTS psit.filtro1 (
  ref_id varchar(255),
  title text[],
  abstract text[],
  keyword text[],
  project varchar(30) DEFAULT 'Illegal Wildlife Trade',
  reviewed_by varchar(100) DEFAULT 'Rsaurio',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project,ref_id)
);
ALTER TABLE psit.filtro1  ADD CONSTRAINT filtro1_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TYPE razones_rechazo AS ENUM (
  'rejected off topic illegal trade' ,
  'rejected off topic parrots' ,
  'rejected illegal trade circunstancial' ,
  'rejected opinion',
  'rejected overview',
  'included in review',
  'not available');

ALTER TYPE razones_rechazo ADD VALUE 'rejected off topic';
ALTER TYPE razones_rechazo ADD VALUE 'rejected off topic (not related to project)';
ALTER TYPE razones_rechazo ADD VALUE 'rejected off topic (not related to taxon)';
ALTER TYPE razones_rechazo ADD VALUE 'rejected on topic but circunstancial';

CREATE TABLE IF NOT EXISTS psit.filtro2 (
  ref_id varchar(255),
  status razones_rechazo,
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id)
);
ALTER TABLE psit.filtro2  ADD CONSTRAINT filtro2_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;
 ALTER TABLE psit.filtro2 ADD COLUMN project varchar(30) DEFAULT 'Illegal Wildlife Trade';

-- To recreate a primary key constraint, without blocking updates while the index is rebuilt:
 CREATE UNIQUE INDEX CONCURRENTLY filtro2_id_temp_idx ON psit.filtro2 (ref_id,project);
 ALTER TABLE psit.filtro2 DROP CONSTRAINT filtro2_pkey,
     ADD CONSTRAINT filtro2_pkey PRIMARY KEY USING INDEX filtro2_id_temp_idx;

CREATE TABLE IF NOT EXISTS psit.species_ref (
  ref_id varchar(255),
  scientific_name varchar(255),
  individuals integer,
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id,scientific_name)
);
ALTER TABLE psit.species_ref  ADD CONSTRAINT species_ref_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE psit.species_ref  ADD CONSTRAINT species_ref_spp_fkey FOREIGN KEY(scientific_name) REFERENCES psit.birdlife(scientific_name) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS psit.country_ref (
  ref_id varchar(255),
  ISO2 varchar(255),
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id,ISO2)
);
ALTER TABLE psit.country_ref  ADD CONSTRAINT country_ref_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE psit.country_ref  ADD CONSTRAINT country_ref_spp_fkey FOREIGN KEY(ISO2) REFERENCES psit.countries("Alpha_2") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE psit.country_ref  ADD COLUMN country_role varchar(100) DEFAULT 'In text';


with tab1 AS (select unnest(country_list) as cc,ref_id,reviewed_by from psit.annotate_ref) INSERT INTO psit.country_ref (ref_id,iso2,reviewed_by,country_role,reviewed_date) (SELECT distinct ref_id,cc,reviewed_by,'Study location',CURRENT_TIMESTAMP(0) FROM tab1 where cc NOT IN ('various','global','quitar argentina')) ON CONFLICT ON CONSTRAINt country_ref_pkey DO UPDATE SET reviewed_by=EXCLUDED.reviewed_by, country_role=EXCLUDED.country_role, reviewed_date=EXCLUDED.reviewed_date;


-- new project: species distribution modelling

CREATE TABLE IF NOT EXISTS psit.distmodel_ref (
  ref_id varchar(255),
  analysis_type text[],
  model_type text[],
  data_source text[],
  topics text[],
  country_list text[],
  species_list text[],
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id)
);
ALTER TABLE psit.distmodel_ref  ADD CONSTRAINT annotate_ref_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE psit.distmodel_ref
ADD COLUMN topic text[],
ADD COLUMN general_application text[],
ADD COLUMN specific_issue text[],
ADD COLUMN paradigm text[],
ADD COLUMN species_range text[];
ALTER TABLE psit.distmodel_ref DROP COLUMN topic;

CREATE TABLE IF NOT EXISTS psit.added_refs (
  ref_id varchar(255),
  ref_code text,
  doi text,
  ref_cite text,
  PRIMARY KEY (ref_code)
);
ALTER TABLE psit.added_refs  ADD CONSTRAINT added_ref_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;




CREATE TABLE IF NOT EXISTS psit.citation_rels (
  from_document text,
  relationship text,
  to_document text,
  UNIQUE (from_document,relationship,to_document)
);
