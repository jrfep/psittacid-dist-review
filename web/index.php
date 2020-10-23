<?php
include("inc/hello.php");
?>

<h1>Revision bibliografica</h1>
<?php
$qry = "select \"TI\",\"AB\" from psit.bibtex where \"AB\" ilike '%nest poach%' limit 2";

 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          echo "<p><b>".$row["TI"]."</b>: ".$row["AB"]."</p>";

   #       echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
?>


<?php
include("inc/bye.php");
?>
