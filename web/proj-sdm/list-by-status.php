<?php
include("../inc/hello.php");
$project="Species distribution models";
?>

<h2>Summary</h2>
<?php
$prg = "SELECT unnest(topics),count(*) FROM  psit.distmodel_ref  GROUP BY unnest ORDER BY count DESC";
$result = pg_query($dbconn, $prg);
if (!$result) {echo "An error occurred. $prg\n";exit;}
while ($row = pg_fetch_assoc($result)) { $topiclist .= "$row[unnest] ($row[count])<br/>";}

$prg = "SELECT unnest(general_application),count(*) FROM  psit.distmodel_ref  GROUP BY unnest ORDER BY count DESC";
$result = pg_query($dbconn, $prg);
if (!$result) {echo "An error occurred. $prg\n";exit;}
while ($row = pg_fetch_assoc($result)) { $genlist .= "$row[unnest] ($row[count])<br/>";}


$prg = "SELECT unnest(specific_issue),count(*) FROM  psit.distmodel_ref  GROUP BY unnest ORDER BY count DESC";
$result = pg_query($dbconn, $prg);
if (!$result) {echo "An error occurred. $prg\n";exit;}
while ($row = pg_fetch_assoc($result)) { $isslist .= "$row[unnest] ($row[count])<br/>";}

$prg = "SELECT unnest(model_type),count(*) FROM  psit.distmodel_ref  GROUP BY unnest ORDER BY count DESC";
$result = pg_query($dbconn, $prg);
if (!$result) {echo "An error occurred. $prg\n";exit;}
while ($row = pg_fetch_assoc($result)) { $modellist .= "$row[unnest] ($row[count])<br/>";}

$prg = "SELECT unnest(paradigm),count(*) FROM  psit.distmodel_ref  GROUP BY unnest ORDER BY count DESC";
$result = pg_query($dbconn, $prg);
if (!$result) {echo "An error occurred. $prg\n";exit;}
while ($row = pg_fetch_assoc($result)) { $modelpara .= "$row[unnest] ($row[count])<br/>";}

$prg = "SELECT unnest(species_range),count(*) FROM  psit.distmodel_ref  GROUP BY unnest ORDER BY count DESC";
$result = pg_query($dbconn, $prg);
if (!$result) {echo "An error occurred. $prg\n";exit;}
while ($row = pg_fetch_assoc($result)) { $rangelist .= "$row[unnest] ($row[count])<br/>";}

echo "
<TABLE style='font-size:14'>
<TR><TH>Issues</TH><TH>Paradigm</TH><TH>Species range</TH><TH>Models</TH></TR>
<TR style='vertical-align: top;' ><TD>$isslist</TD><TD>$modelpara</TD><TD>$rangelist</TD><TD>$modellist</TD></TR>
</TABLE>";
?>

<h2>Articles included in review</h2>

<?php

$qry = "SELECT \"TI\",\"DE\",\"UT\",\"DI\",topics,analysis_type,model_type,specific_issue,species_range
FROM psit.bibtex b
LEFT JOIN psit.distmodel_ref a
  ON b.\"UT\"=a.ref_id
  LEFT JOIN psit.filtro2 f
ON b.\"UT\"=f.ref_id
WHERE status = 'included in review'
AND project='Species distribution models'
ORDER BY model_type,analysis_type ";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

function stripvals($x) {
  $y = str_replace(array('{','}','"'),'',$x);
  $z = str_replace(array(','),' // ',$y);
  return $z;
};
$k = 1 ;
 while ($row = pg_fetch_assoc($result)) {

   $k =+ 1;
          $tab .= "<TR bgcolor='#A4F3D8'><TH>$k</TH><TD ><b>".$row["TI"]."</b></br>".$row["DE"]."</TD><TD>  <a  href='/litrev/web/show-reference.php?UT=".$row["UT"]."&project=$project'>Review</a> / <a target='_blank' href='http://doi.org/".$row["DI"]."'>DOI link</a></TD><TD >Issue: ".stripvals($row["specific_issue"])."</BR>Range: ".stripvals($row["species_range"])."</TD><TD >Paradigm: ".stripvals($row["paradigm"])."<BR/>Method/Model: ".stripvals($row["model_type"])."</TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='45%'>TI</TH><TD></TD><TH width='25%'>Analysis</TH><TH width='25%'>Models</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
