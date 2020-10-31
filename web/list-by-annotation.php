<?php
include("inc/hello.php");
?>

<?php
$kwd1 = $_REQUEST["action"];
$kwd2 = $_REQUEST["contribution"];
$qry = "select \"TI\",\"DE\",\"UT\",status,action from psit.bibtex b
LEFT JOIN psit.annotate_ref a
  ON b.\"UT\"=a.ref_id
  LEFT JOIN psit.filtro2 f
  ON b.\"UT\"=f.ref_id
WHERE action='$kwd1' AND contribution='$kwd2'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $tab .= "<TR><TH bgcolor='#54B3B8'>".$row["TI"]."</TH><TD>  <a  href='show-reference.php?UT=".$row["UT"]."'>Show</a></TD><TD bgcolor='#54B3B8'>".$row["status"]."</TD><TD bgcolor='#54B3B8'>".$row["action"]."</TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='75%'>TI</TH><TD></TD><TH>Filtro2</TH><TH>Actions</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
