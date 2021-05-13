<?php
include("../inc/hello.php");
$project="Species distribution models";
?>

<?php
$qry = "SELECT \"TI\",\"DE\",\"UT\",\"DI\",analysis_type,model_type
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

 while ($row = pg_fetch_assoc($result)) {
          $tab .= "<TR bgcolor='#A4F3D8'><TD ><b>".$row["TI"]."</b></br>".$row["DE"]."</TD><TD>  <a  href='/litrev/web/show-reference.php?UT=".$row["UT"]."&project=$project'>Review</a> / <a target='_blank' href='http://doi.org/".$row["DI"]."'>DOI link</a></TD><TD >".$row["analysis_type"]."</TD><TD >".$row["model_type"]."</TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='45%'>TI</TH><TD></TD><TH width='25%'>Analysis</TH><TH width='25%'>Models</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
