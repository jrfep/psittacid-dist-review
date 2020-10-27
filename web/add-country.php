<?php
include("inc/hello.php");
?>

<h1>Revision bibliografica</h1>


<?php
$refid = $_REQUEST["UT"];
$qry = "select \"Alpha_2\",\"Name\" from psit.countries";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $opts .= "<OPTION value='".$row["Alpha_2"]."'>".$row["Name"]."</OPTION>";

   }
echo "<form><label for='ISO2'>Choose countries:</label>
<select name='ISO2' id='ISO2' multiple>$opts</select></form>";

?>

<?php
include("inc/bye.php");
?>
