<?php
include("inc/hello.php");
?>


<?php
$tab = "";
$kwd = $_REQUEST["DE"];

if (isset($_REQUEST["delete"]) & $kwd != '' & $project != '') {
  $columns = array('title','abstract','keyword');
  foreach ($columns as $cc) {
    $qry = "update psit.filtro1 SET $cc=array_remove($cc,'$kwd') where $cc is not null AND project='$project'";
    ##echo "$qry<br/>";
    // $res = pg_query($dbconn, $qry);
    //  if ($res) {
    //    print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
    // } else {
    //    print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
    //  }
    print_r($qry);
  }

  $qry = "delete from psit.filtro1 where array_dims(title) is null and array_dims(abstract) is null and array_dims(keyword) is null and project='$project'";
  print_r($qry);
  // $res = pg_query($dbconn, $qry);
  //  if ($res) {
  //    print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
  // } else {
  //    print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
  //  }
}

switch ($project) {
  case "Illegal Wildlife Trade":
  $qry = "select \"TI\",\"DE\",\"UT\",status,action,contribution,abstract,keyword,title from psit.filtro1 f1
  LEFT JOIN psit.bibtex b
  ON b.\"UT\"=f1.ref_id
  LEFT JOIN psit.annotate_ref a
    ON f1.ref_id=a.ref_id
    LEFT JOIN psit.filtro2 f2
    ON f1.ref_id=f2.ref_id
  WHERE ('$kwd' = ANY(title) OR '$kwd' = ANY(abstract) OR '$kwd' = ANY(keyword)) ";
  break;
  case "Species distribution models":
  $qry = "WITH f1 as (SELECT * FROM psit.filtro1 WHERE project='$project'),
  f2 as (SELECT * FROM psit.filtro2 WHERE project='$project')
  select \"TI\",\"DE\",\"UT\",abstract,keyword,title,status,model_type from f1
  LEFT JOIN psit.bibtex b
  ON b.\"UT\"=f1.ref_id
    LEFT JOIN psit.distmodel_ref a
    ON f1.ref_id=a.ref_id
    LEFT JOIN f2
    ON f1.ref_id=f2.ref_id
  WHERE ('$kwd' = ANY(title) OR '$kwd' = ANY(abstract) OR '$kwd' = ANY(keyword))
  ORDER BY status DESC";
  break;

}


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result)) {
   $clr = '#99FFDD';

   switch ($project) {
     case "Illegal Wildlife Trade":
          $tab .= "
          <TR style='background-color:$clr'>
          <TH>".$row["TI"]."</TH>
          <TD style='font-size:10px'>::".$row["title"]."<br/>:: ".$row["abstract"]."<br/>:: ".$row["keyword"]."</TD>
          <TD>".$row["status"]."</TD>
          <TD>".$row["action"]."/".$row["contribution"]."</TD>
          <TD>  <a  href='show-reference.php?UT=".$row["UT"]."&project=$project'>Show</a></TD>
          </TR>";
          break;
          case "Species distribution models":
          $tab .= "
          <TR style='background-color:$clr'>
          <TH>".$row["TI"]."</TH>
          <TD style='font-size:10px'>::".$row["title"]."<br/>:: ".$row["abstract"]."<br/>:: ".$row["keyword"]."</TD>
          <TD>".$row["status"]."</TD>
          <TD>".$row["analysis_type"]."</TD>
          <TD>  <a  href='show-reference.php?UT=".$row["UT"]."&project=$project'>Show</a></TD>
          </TR>";
          break;

        }

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
