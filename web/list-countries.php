<?php
include("inc/hello.php");
?>


<?php
$qry = "select \"Alpha_2\",\"Name\",count(distinct ref_id) from psit.countries l left join psit.country_ref r ON l.\"Alpha_2\"=iso2 WHERE country_role NOT IN ('False positive','Error') group by \"Alpha_2\",\"Name\" order by count DESC";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $tab .= "<TR><TH bgcolor='$clr'>".$row["Name"]."
          (".$row["Alpha_2"].")</TH>
        <TD bgcolor='$clr'><a href='list-by-country.php?ISO2=".$row["Alpha_2"]."'>".$row["count"]."</a></TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='40%'>Country</TH><TH>References</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
