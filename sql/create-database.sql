
ALTER TABLE  psit.bibtex
    ADD CONSTRAINT ref_id PRIMARY KEY ("UT");

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
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id,contribution,action)
);
ALTER TABLE psit.annotate_ref  ADD CONSTRAINT annotate_ref_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE psit.annotate_ref  ADD CONSTRAINT annotate_ref_action_fkey FOREIGN KEY(action) REFERENCES psit.actions(action) ON DELETE CASCADE ON UPDATE CASCADE;


CREATE TABLE IF NOT EXISTS psit.filtro1 (
  keyword varchar(255),
  status varchar(10),
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (keyword)
);




CREATE TYPE razones_rechazo AS ENUM ('rejected off topic illegal trade' , 'rejected off topic parrots' , 'rejected illegal trade circunstancial' , 'rejected opinion','rejected overview','included in review','not available');

CREATE TABLE IF NOT EXISTS psit.filtro2 (
  ref_id varchar(255),
  status razones_rechazo,
  reviewed_by varchar(100) DEFAULT 'Ada Sanchez',
  reviewed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ref_id)
);
ALTER TABLE psit.filtro2  ADD CONSTRAINT filtro2_code_fkey FOREIGN KEY(ref_id) REFERENCES psit.bibtex("UT") ON DELETE CASCADE ON UPDATE CASCADE;
