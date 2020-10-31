<?php
include("inc/hello.php");
?>


<?php
$refid = $_REQUEST["refid"];
$spp = $_REQUEST["spp"];
?>



<?php

if (isset($_REQUEST["editinfo"])) {

foreach ($_POST as $key => $value) {
      if (in_array($key, array("reviewed_by","individuals"))) {
         if ($value!="") {
            $columns[]= "$key='$value'";
         }
      }
   }
  $qry = "UPDATE psit.species_ref set ".implode($columns,", ").", reviewed_date=CURRENT_TIMESTAMP(0) WHERE ref_id='$refid' AND sscientific_name='$spp' ";
  $res = pg_query($dbconn, $qry);
   if ($res) {
     print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
  } else {
     print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
}

?>



<?php

$qry = "select * from psit.species_ref where ref_id='$refid' and scientific_name='$spp'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

while ($row = pg_fetch_assoc($result)) {
 while(list($name,$value) = each($row)) {
   $cells .= "<tr bgcolor='#B5D6B6'>
   <th>$name</TH>";
   switch($name) {
     case "scientific_name":
     $element="<input type='hidden' name='spp' value='$spp'></input>
     <input type='text' name='$name' value='$value'></input>";
     break;
     case "reviewed_date":
     $element=$value;
     break;
     case "ref_id":
     $element="<input type='hidden' name='refid' value='$refid'>
     <a href='show-reference.php?UT=$refid'>$refid</a></input>";
     break;
     default:
     $element="<input type='text' name='$name' value='$value'></input>";

   }
   $cells .= "<TD>$element</td>";
   $cells .= "</tr>";
  }
}



echo "
$qry
<FORM ACTION='edit-species.php' METHOD='POST'>
<TABLE>

$cells
</TABLE>
<INPUT TYPE='submit' NAME='editinfo'/>
</FORM>
";


?>

<?php
include("inc/bye.php");
?>
