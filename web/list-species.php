<?php
include("inc/hello.php");
?>
<h1>Revision bibliografica "Psittaciformes Illegal Trade"</h1>

<A HREF='index.php'>HOME</A>


<?php
$qry = "select scientific_name,english_name,family,iucn,count(distinct ref_id) from psit.birdlife l left join psit.species_ref r USING (scientific_name) group by scientific_name,english_name,family,iucn order by count DESC";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
   switch($row["iucn"]) {
     case 'EX':
     case 'CR':
     case 'EN':
     case 'EW':
     $clr = '#FF0000';
     break;
     case 'LC':
     case 'NT':
     $clr = '#00FF00';
     break;
     case 'VU':
     $clr = '#FFFF00';
     break;
     default:
     $clr = '#D4B3B8';
   }
          $tab .= "<TR><TH bgcolor='$clr'><i>".$row["scientific_name"]."</i><br/>
          ".$row["english_name"]."</TH>
          <TD bgcolor='$clr'>".$row["family"]."</TD>
          <TD bgcolor='$clr'>".$row["iucn"]."</TD>
          <TD bgcolor='$clr'><a href='list-by-species.php?spp=".$row["scientific_name"]."'>".$row["count"]."</a></TD></TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE><TR><TH width='40%'>Scientific name / English name</TH><TH>Family</TH><TH>IUCN category</TH><TH>References</TH></TR>$tab</TABLE>"
?>

<?php
include("inc/bye.php");
?>
