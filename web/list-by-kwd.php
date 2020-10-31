<?php
include("inc/hello.php");
?>


<?php
$kwd = $_REQUEST["DE"];
$project = $_REQUEST["project"];

if (isset($_REQUEST["delete"]) & $kwd != '' & $project != '') {
  $columns = array('title','abstract','keyword');
  foreach ($columns as $cc) {
    $qry = "update psit.filtro1 SET $cc=array_remove($cc,'$kwd') where $cc is not null AND project='$project'";
    ##echo "$qry<br/>";
    $res = pg_query($dbconn, $qry);
     if ($res) {
       print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
    } else {
       print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
     }
  }

  $qry = "delete from psit.filtro1 where array_dims(title) is null and array_dims(abstract) is null and array_dims(keyword) is null and project='$project'";
  $res = pg_query($dbconn, $qry);
   if ($res) {
     print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
  } else {
     print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
}

$qry = "select \"TI\",\"DE\",\"UT\",status,action,contribution,abstract,keyword,title from psit.filtro1 f1
LEFT JOIN psit.bibtex b
ON b.\"UT\"=f1.ref_id
LEFT JOIN psit.annotate_ref a
  ON f1.ref_id=a.ref_id
  LEFT JOIN psit.filtro2 f2
  ON f1.ref_id=f2.ref_id
WHERE '$kwd' = ANY(title) OR '$kwd' = ANY(abstract) OR '$kwd' = ANY(keyword)  ";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
   $clr = '#99FFDD';
          $tab .= "
          <TR style='background-color:$clr'>
          <TH>".$row["TI"]."</TH>
          <TD style='font-size:10px'>::".$row["title"]."<br/>:: ".$row["abstract"]."<br/>:: ".$row["keyword"]."</TD>
          <TD>".$row["status"]."</TD>
          <TD>".$row["action"]."/".$row["contribution"]."</TD>
          <TD>  <a  href='show-reference.php?UT=".$row["UT"]."&project=$project'>Show</a></TD>
          </TR>";

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }
   echo "<TABLE>
   <TR>
   <TH width='45%'>Titulo</TH>
   <TH width='25%'>Filtro 1</TH>
   <TH>Filtro 2</TH>
   <TH>Anotaciones</TH>
   <TH></TH>
   </TR>
   $tab
   </TABLE>";

   echo "<BR/><BR/><P>[<a href='".$_SERVER["PHP_SELF"]."?".$_SERVER['QUERY_STRING']."&delete'>REMOVE SEARCH TERM ''$kwd'' </a>] from project $project </P>";

?>

<?php
include("inc/bye.php");
?>
