<?php
include("inc/hello.php");
?>

<?php
$refid = $_REQUEST["refid"];
$action = $_REQUEST["origaction"];
$contrib = $_REQUEST["origcontribution"];
?>



<?php

if (isset($_REQUEST["editinfo"])) {

foreach ($_POST as $key => $value) {
      if (in_array($key, array("contribution","action","reviewed_by","country_list","species_list","data_type"))) {
         if ($value!="") {
            $columns[]= "$key='$value'";
         }
      }
   }
  $qry = "UPDATE psit.annotate_ref set ".implode($columns,", ").", reviewed_date=CURRENT_TIMESTAMP(0) WHERE ref_id='$refid' AND action='$action' AND contribution='$contrib'";
  $res = pg_query($dbconn, $qry);
   if ($res) {
     print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
  } else {
     print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
}

?>



<?php

$qry = "select * from psit.annotate_ref where ref_id='$refid' and contribution='$contrib' and action='$action'";


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
<FORM ACTION='edit-annotation.php' METHOD='POST'>
<input type='hidden' name='origaction' value='$action'>
<input type='hidden' name='origcontribution' value='$contrib'>
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
