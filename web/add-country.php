<?php
include("inc/hello.php");
?>

<h1>Revision bibliografica</h1>


<h2>Anotaciones</h2>

<?php
##$qry = "select \"TI\",\"AB\" from psit.bibtex where \"AB\" ilike '%nest poach%' limit 2";
$qry = "select action,contribution,count(*) from psit.annotate_ref group by action,contribution ";

 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }
 $total = $actions = $contributions = array();
 while ($row = pg_fetch_assoc($result)) {
  #        echo "<p><b>".$row["TI"]."</b>: ".$row["AB"]."</p>";
  $total[$row["action"]][$row["contribution"]] += $row["count"];

  array_push($actions,$row["action"]);
  array_push($contributions,$row["contribution"]);
   }
   $actions = array_unique($actions);
   $contributions = array_unique($contributions);

     $tab .= "<tr><th>Actions</th>";
   foreach($contributions as $cc) {
       $tab .= "<th>".$cc."</th>";
   }
   $tab .="</tr>";

   while(list($n,$aa) = each($actions)) {
     $tab .= "<tr><th>".$aa."</th>";

     foreach($contributions as $cc) {
       $tab .= "<td align='center' bgcolor='#B7B6C5'><a href='list-by-annotation.php?action=$aa&contribution=$cc'>".$total[$aa][$cc]."</a></td>";
     }
     $tab .= "<tr>";

   }
   echo "<table>$tab</table>";

?>

By country
<?php
$prg = " WITH tab1 as ( select unnest(country_list) as cty FROM psit.annotate_ref) SELECT \"Name\",cty,count(*) from tab1 left join psit.countries ON cty=\"Alpha_2\" group by \"Name\",cty order by count DESC";

 $result = pg_query($dbconn, $prg);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $li3 .= "<li><a href='list-by-country.php?ISO2=$row[cty]'>$row[Name] ($row[cty])</a>: $row[count] references</li>";

   }
echo "<ol>$li3</ol>"
?>

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
