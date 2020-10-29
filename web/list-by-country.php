<?php
include("inc/hello.php");
?>
<h1>Revision bibliografica "Psittaciformes Illegal Trade"</h1>

<A HREF='index.php'>HOME</A>


<?php
$kwd = $_REQUEST["ISO2"];
$qry = "select \"TI\",\"DE\",\"UT\",country_role,status,action from psit.bibtex b
LEFT JOIN psit.annotate_ref a
  ON b.\"UT\"=a.ref_id
  LEFT JOIN psit.filtro2 f
  ON b.\"UT\"=f.ref_id
  LEFT JOIN psit.country_ref s
  ON b.\"UT\"=s.ref_id
WHERE '$kwd'=ANY(country_list) OR iso2='$kwd'
ORDER by country_role DESC";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
   switch($row["country_role"]) {
     case "Study location":
     $clr = "#54B3B8";
     break;
     default:
     $clr = "#DDB8B8";
   }
          $tab .= "<TR style='background-color: $clr'><TH >".$row["TI"]."</TH><TD>  <a  href='show-reference.php?UT=".$row["UT"]."'>Show</a></TD><TD >".$row["country_role"]."</TD><TD >".$row["status"]."</TD><TD >".$row["action"]."</TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='75%'>TI</TH><TD></TD><TH>Filtro2</TH><TH>Actions</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
