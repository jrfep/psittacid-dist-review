<?php
include("inc/hello.php");
?>
<h1>Revision bibliografica "Psittaciformes Illegal Trade"</h1>

<A HREF='index.php'>HOME</A>


<?php
$kwd = $_REQUEST["DE"];
$project = $_REQUEST["project"];

$qry = "select \"TI\",\"DE\",\"UT\",status,action,contribution,abstract,keyword,title from psit.bibtex b
LEFT JOIN psit.filtro1 f1
ON b.\"UT\"=f1.ref_id
LEFT JOIN psit.annotate_ref a
  ON f1.ref_id=a.ref_id
  LEFT JOIN psit.filtro2 f2
  ON f1.ref_id=f2.ref_id
WHERE \"DE\" ilike '%$kwd%' ";


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
          <TD>  <a  href='show-reference.php?UT=".$row["UT"]."'>Show</a></TD>
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
