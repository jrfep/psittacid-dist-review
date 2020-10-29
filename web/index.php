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

      $qry = "select count(distinct ref_id) from psit.filtro2 ";

       $result = pg_query($dbconn, $qry);
       if (!$result) {
         echo "An error occurred.\n";
         exit;
       }

       while ($row = pg_fetch_assoc($result)) {
        #        echo "<p><b>".$row["TI"]."</b>: ".$row["AB"]."</p>";

                echo "<p>De las cuales ".$row["count"]." fueron revisadas</p>";
         }


            $qry = "select count(distinct ref_id) from psit.annotate_ref ";

             $result = pg_query($dbconn, $qry);
             if (!$result) {
               echo "An error occurred.\n";
               exit;
             }

             while ($row = pg_fetch_assoc($result)) {
              #        echo "<p><b>".$row["TI"]."</b>: ".$row["AB"]."</p>";

                      echo "<p>Y ".$row["count"]." han sido incluidas y anotadas</p>";
               }

?>

<h2>Filtro 1</h2>
<?php
$qry = "select keyword,count(distinct \"UT\") as nref,count(f2.status) as nfiltered from psit.filtro1 f1
LEFT JOIN psit.bibtex b ON b.\"DE\" LIKE '%' || f1.keyword || '%'
LEFT JOIN psit.filtro2 f2 ON b.\"UT\"=f2.ref_id
  where f1.status='YES'
  GROUP BY keyword
  ORDER BY nref DESC ,nfiltered";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
          $li .= "<li><a href='list-by-kwd.php?DE=$row[keyword]'>$row[keyword]</a>: $row[nref] references, $row[nfiltered] reviewed</li>";

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

<a href='list-countries.php'>All countries</a>
<a href='list-species.php'>All species</a>

<?php
include("inc/bye.php");
?>
