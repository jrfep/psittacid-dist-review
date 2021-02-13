<?php
include("inc/hello.php");
?>

<?php

  $qry1 = "select count(distinct b.\"UT\") as referencias FROM psit.bibtex b";
  $qry2 ="select count(distinct f1.ref_id) as filtro1 FROM psit.filtro1 f1 WHERE project='$project'";
  $qry3 ="select count(distinct f2.ref_id) as filtro2 FROM psit.filtro2 f2 WHERE project='$project'";
  $qry4 ="select count(distinct a.ref_id) as anotadas FROM psit.annotate_ref a";
  $res1 = pg_query($dbconn, $qry1); if (!$res1) { echo "An error occurred.\n"; exit;}
  $res2 = pg_query($dbconn, $qry2); if (!$res2) { echo "An error occurred.\n"; exit;}
  $res3 = pg_query($dbconn, $qry3); if (!$res3) { echo "An error occurred.\n"; exit;}
  $res4 = pg_query($dbconn, $qry4); if (!$res4) { echo "An error occurred.\n"; exit;}

  $row1 = pg_fetch_assoc($res1);
  $row2 = pg_fetch_assoc($res2);
  $row3 = pg_fetch_assoc($res3);
  $row4 = pg_fetch_assoc($res4);

    echo "<p>Tenemos ".$row1["referencias"]." referencias en base de datos </p>";
    echo "<p> ".$row2["filtro1"]." seleccionadas por el Filtro 1 </p>";
    echo "<p> ".$row3["filtro2"]." seleccionadas por el Filtro 2 </p>";
    echo "<p> y ".$row4["anotadas"]." con datos de trafico anotados </p>";



?>

<h2>Filtro 1</h2>
<?php

$qry = "WITH tab1 AS (
  SELECT unnest(title) AS kwd, count(distinct f1.ref_id) AS titulo_f1, count(distinct f2.ref_id) AS titulo_f2 FROM psit.filtro1 f1 LEFT JOIN psit.filtro2 f2 ON f1.ref_id=f2.ref_id WHERE f1.project='$project'  GROUP BY kwd
),
tab2 AS (
  SELECT unnest(keyword) AS kwd, count(distinct f1.ref_id) AS keyword_f1, count(distinct f2.ref_id) AS keyword_f2 FROM psit.filtro1 f1 LEFT JOIN psit.filtro2 f2 ON f1.ref_id=f2.ref_id WHERE f1.project='$project'  GROUP BY kwd
),
tab3 AS (
    SELECT unnest(abstract) AS kwd, count(distinct f1.ref_id) AS abstract_f1, count(distinct f2.ref_id) AS abstract_f2 FROM psit.filtro1 f1 LEFT JOIN psit.filtro2 f2  ON f1.ref_id=f2.ref_id WHERE f1.project='$project'  GROUP BY kwd
  )
SELECT kwd,titulo_f1,titulo_f2,abstract_f1,abstract_f2,keyword_f1,keyword_f2
FROM tab1
FULL JOIN tab2 USING(kwd)
FULL JOIN tab3 USING(kwd)";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
    $clr = array('#FF9999','#FF9999','#FF9999');
   if ($row["titulo_f2"]==$row['titulo_f1']) { $clr[0] = '#99FF99';}
   if ($row['keyword_f2']==$row['keyword_f1']) { $clr[1] = '#99FF99';}
   if ($row["abstract_f2"]==$row['abstract_f1']) { $clr[2] = '#99FF99';}
         $li .= "<tr>
          <th><a href='list-by-kwd.php?DE=$row[kwd]&project=$project'>$row[kwd]</a></th>
          <td style='background-color: $clr[0]'>$row[titulo_f2]/$row[titulo_f1]</td>
          <td style='background-color: $clr[1]'>$row[keyword_f2]/$row[keyword_f1]</td>
          <td style='background-color: $clr[2]'>$row[abstract_f2]/$row[abstract_f1]</td>
          </tr>";

   }
echo "<table>
<tr>
<th>Search terms</th>
<td>Title</td>
<td>Keyword</td>
<td>Abstract</td>
</tr>
$li
</table>"
?>

<h2>Filtro 2</h2>
<?php

$qry = "select status,count(*) from psit.filtro2 WHERE project='$project' group by status ";

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
