<?php
include("inc/hello.php");
?>

<h1>Revision bibliografica "Psittaciformes Illegal Trade"</h1>
<?php
##$qry = "select \"TI\",\"AB\" from psit.bibtex where \"AB\" ilike '%nest poach%' limit 2";
$qry = "select count(*) from psit.bibtex ";

 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
  #        echo "<p><b>".$row["TI"]."</b>: ".$row["AB"]."</p>";

          echo "<p>Tenemos ".$row["count"]." referencias en base de datos</p>";
   }

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
          $tab .= "<td align='center' bgcolor='#B7B6C5'>".$total[$aa][$cc]."</td>";
        }
        $tab .= "<tr>";

      }
      echo "<table>$tab</table>";
?>

<h2>Filtro 1</h2>
<?php
$qry = "select keyword from psit.filtro1 where status='YES' ";

 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $li .= "<li><a href='list-by-kwd.php?DE=$row[keyword]'>$row[keyword]</a></li>";
   }
echo "<ol>$li</ol>"
?>

<h2>Filtro 2</h2>
<?php

$qry = "select status,count(*) from psit.filtro2 group by status ";

 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $li2 .= "<li><a href='list-by-status.php?filtro2=$row[status]'>$row[status]</a>: $row[count] referencias</li>";
   }
echo "<ol>$li2</ol>"
?>


<?php
include("inc/bye.php");
?>
