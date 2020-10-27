<?php
include("inc/hello.php");
?>

<h1>Revision bibliografica</h1>


<?php
$refid = $_REQUEST["UT"];
$qry = "select * from psit.bibtex where \"UT\" ilike '%$refid%'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          echo "<p><b>".$row["TI"]."</b>
          <br/> keywords ".$row["DE"]."<br/>
           DOI:<a target='_blank' href='http://dx.doi.org/".$row["DI"]."'>".$row["DI"]."</a></p>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
?>

<?php
include("inc/bye.php");
?>
