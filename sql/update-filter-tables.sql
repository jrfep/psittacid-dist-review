SELECT count(*) from psit.filtro1 WHERE project='Species distribution models';
INSERT INTO psit.filtro1 (ref_id,abstract, project,reviewed_by,reviewed_date)
select "UT",'{NICHE MODEL}','Species distribution models','Rsaurio',CURRENT_TIMESTAMP(0) from psit.bibtex where "AB" like '%NICHE%MODEL%'
ON CONFLICT DO NOTHING;

INSERT INTO psit.filtro1 (ref_id,abstract, project,reviewed_by,reviewed_date)
select "UT",'{OCCUPANCY MODEL}','Species distribution models','Rsaurio',CURRENT_TIMESTAMP(0) from psit.bibtex where "AB" like '%OCCUPANCY%MODEL%'
ON CONFLICT DO NOTHING;


INSERT INTO psit.filtro1 (ref_id,abstract, project,reviewed_by,reviewed_date)
select "UT",'{RESOURCE SELECTION}','Species distribution models','Rsaurio',CURRENT_TIMESTAMP(0) from psit.bibtex where "AB" like '%RESOURCE%SELECTION%'
ON CONFLICT DO NOTHING;

select * from psit.filtro1  where project like 'Species%' limit 12;


SELECT "UT","TI"
FROM psit.filtro1
LEFT JOIN psit.bibtex ON ref_id="UT"
WHERE project LIKE 'Species%'
AND "AB" LIKE '%PARROTIA%'
LIMIT 12;
;
 -- reject PARROTFISH, SANDFLIES, MACAW PALM, PARROTIA, PHLEBOTO
INSERT INTO psit.filtro2 (ref_id,status, reviewed_by, project,reviewed_date)
SELECT "UT",'rejected off topic', 'R-saurio', 'Species distribution models',CURRENT_TIMESTAMP(0)
FROM psit.filtro1 f1
LEFT JOIN psit.bibtex ON ref_id="UT"
WHERE f1.project LIKE 'Species%'
AND "TI" LIKE '%PARROT%FISH%'
 ON CONFLICT DO NOTHING;


  -- reject PARROTFISH, SANDFLIES, MACAW PALM
 INSERT INTO psit.filtro2 (ref_id,status, reviewed_by, project,reviewed_date)
 SELECT "UT",'rejected off topic', 'R-saurio', 'Species distribution models',CURRENT_TIMESTAMP(0)
 FROM psit.filtro1 f1
 LEFT JOIN psit.bibtex ON ref_id="UT"
 WHERE f1.project LIKE 'Species%'
 AND "AB" LIKE '%PARROTFEATHER%'
  ON CONFLICT DO NOTHING;
