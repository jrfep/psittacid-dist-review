<?php
include("inc/hello.php");
?>
<h1>Revision bibliografica "Psittaciformes Illegal Trade"</h1>

<A HREF='index.php'>HOME</A>

<?php
$kwd = $_REQUEST["filtro2"];
$qry = "select \"TI\",\"DE\",\"UT\",status,action from psit.bibtex b
LEFT JOIN psit.annotate_ref a
  ON b.\"UT\"=a.ref_id
  LEFT JOIN psit.filtro2 f
ON b.\"UT\"=f.ref_id
WHERE status = '$kwd'
ORDER BY action DESC";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $tab .= "<TR><TD bgcolor='#54B3B8'><b>".$row["TI"]."</b></br>".$row["DE"]."</TD><TD>  <a  href='show-reference.php?UT=".$row["UT"]."'>Show</a></TD><TD bgcolor='#54B3B8'>".$row["status"]."</TD><TD bgcolor='#54B3B8'>".$row["action"]."</TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='75%'>TI</TH><TD></TD><TH>Filtro2</TH><TH>Actions</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
