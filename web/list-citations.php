<?php
include("inc/hello.php");
?>


<?php
$key=$_REQUEST["key"];

$qry = "SELECT from_document,\"TI\",f1.reviewed_date rd1, f2.reviewed_date rd2, f2.status, f3.reviewed_date rd3
  FROM psit.citation_rels
  LEFT JOIN psit.bibtex ON from_document=\"UT\"
  LEFT JOIN psit.filtro1 f1 ON from_document=f1.ref_id
  LEFT JOIN psit.filtro2 f2 ON from_document=f2.ref_id
  LEFT JOIN psit.distmodel_ref f3 ON from_document=f3.ref_id
  WHERE to_document='$key' AND relationship='UT cites SR'
  AND f1.project='$project' AND f2.project='$project'
";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred. $qry\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $tab .= "<TR><TH>".$row["TI"]."</TH>
          <TD>".$row["rd1"]."</TD>
          <TD>".$row["status"]." (".$row["rd2"].")</TD>
          <TD>".$row["rd3"]."</TD>
          <TD><a href='show-reference.php_UT=".$row["from_document"]."&project=$project'>Show</a></TD></TR>";

   }
   echo "<TABLE><TR><TH>Reference</TH><TH colspan='3'>Filters</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
