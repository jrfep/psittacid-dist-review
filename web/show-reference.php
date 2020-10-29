<?php
include("inc/hello.php");
?>
<h1>Revision bibliografica "Psittaciformes Illegal Trade"</h1>

<A HREF='index.php'>HOME</A>


<?php

$refid = $_REQUEST["UT"];
#print_r($_REQUEST);
if (isset($_REQUEST["filtrar"])) {

foreach ($_POST as $key => $value) {
      if (in_array($key, array("status","reviewed_by"))) {
         if ($value!="") {
            $columns[]= $key;
            $values[] = "'$value'";
         }
      }
   }
  $qry = "INSERT INTO psit.filtro2 (ref_id,".implode($columns,", ").",reviewed_date) values ('".$refid."',".implode($values,", ").",CURRENT_TIMESTAMP(0)) ON CONFLICT DO NOTHING ";
  $res = pg_query($dbconn, $qry);
   if ($res) {
      print "<BR/>POST data is successfully logged<BR/>$qry\n";
   } else {
      print "<BR/>User must have sent wrong inputs<BR/>$qry\n";
   }
  #echo $qry;
}

if (isset($_REQUEST["anotar"])) {

foreach ($_POST as $key => $value) {
      if (in_array($key, array("contribution","action"))) {
         if ($value!="") {
            $columns[]= $key;
            $values[] = "'$value'";
         }
      }
      if (in_array($key, array("data_type","country_list"))) {
        #print_r($key);
        #print_r($value);
         if ($value!="") {
            $columns[]= $key;
            $values[] = "'{".implode($value,",")."}'";
         }
      }

   }
  $qry = "INSERT INTO psit.annotate_ref (ref_id,".implode($columns,", ").",reviewed_date) values ('".$refid."',".implode($values,", ").",CURRENT_TIMESTAMP(0)) ON CONFLICT DO NOTHING ";
  $res = pg_query($dbconn, $qry);
   if ($res) {
      print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
   } else {
      print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
  #echo $qry;
}

?>

<?php

$qry = "select \"TI\",\"DE\",\"AB\",\"DI\",contribution,action,status,data_type,country_list,f.reviewed_by as rev1 from psit.bibtex b
LEFT JOIN psit.annotate_ref a
  ON b.\"UT\"=a.ref_id
  LEFT JOIN psit.filtro2 f
  ON b.\"UT\"=f.ref_id
where \"UT\" ilike '%$refid%'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {

$kwds = explode(";",$row["DE"]);
foreach($kwds as $v) {
       $URLS.="<a href='list-by-kwd.php?DE=$v'>$v</a> / ";
     }
          echo "<p><b>".$row["TI"]."</b>
          <br/> keywords ".$URLS."<br/>
          <br/> abstract ".$row["AB"]."<br/>
          <br/>  DOI:<a target='_blank' href='http://dx.doi.org/".$row["DI"]."'>".$row["DI"]."</a></p>
          ";
if ($row["status"]!='') {
  echo "<h3>Filtro 2</h3><p> ".$row["status"]."</p>";

  if ($row["status"]=='included in review') {
    if ($row["action"]!='') {
        echo "  <h3>Annotation</h3>
        <TABLE>
        <tr><th> Data type</th><td>".$row["data_type"]."</td></tr>
        <tr><th> Action</th><td>".$row["action"]."</td></tr>
        <tr><th> Contribution</th><td>".$row["contribution"]."</td></tr>
        <tr><th> Country list</th><td>".$row["country_list"]."</td></tr>
        <tr><th> Reviewed by</th><td>".$row["rev1"]."</td></tr>
        </TABLE>";

      } else {

        $optcontrib = array('basic knowledge' , 'implementation', 'monitoring');

        foreach(array_values($optcontrib) as $val) {
          $opt2s .= "<option value='$val'>$val</option>";
        }


        $opttypes = array('interview','literature review','oficial report', 'field survey', 'cites', 'seizure', 'internet');


        foreach(array_values($opttypes) as $val) {
          $opt5s .= "<option value='$val'>$val</option>";
        }


        $qry = "select * from psit.actions order by trade_chain,aims,action_type";
         $result = pg_query($dbconn, $qry);
         if (!$result) {
           echo "An error occurred.\n";
           exit;
         }

         while ($row = pg_fetch_assoc($result)) {
                  $opt3s.= "<option value='".$row["action"]."'>".$row["action"]." (".$row["trade_chain"]."/".$row["aims"]."/".$row["action_type"].") </option>";

          #        echo "Tenemos ".$row["count"]." referencias en base de datos";
           }
           $qry = "select \"Alpha_2\",\"Name\" from psit.countries order by \"Name\"";
            $result = pg_query($dbconn, $qry);
            if (!$result) {
              echo "An error occurred.\n";
              exit;
            }
            while ($row = pg_fetch_assoc($result)) {
                     $opt4s.= "<option value='".$row["Alpha_2"]."'>".$row["Name"]." </option>";

             #        echo "Tenemos ".$row["count"]." referencias en base de datos";
              }

        echo "<FORM ACTION='show-reference.php' METHOD='POST'>
        Anotar referencia <br/>
        <input type='hidden' name='UT' value='".$refid."'></input>
        Contribution: <select name='contribution'>
        $opt2s
        </select><br/>
        Action:
        <select name='action'>
        $opt3s
        </select><br/>
        <select name='country_list[]' multiple>
        $opt4s
        </select><br/>
        Data type
        <select name='data_type[]' multiple>
        $opt5s
        </select><br/>
        Revisado por <input type='text' name='reviewed_by' value='Ada Sanchez'></input>

        <INPUT TYPE='submit' NAME='anotar'/>
        </FORM>";
      }

  }
} else {
  $optfiltro = array('rejected off topic illegal trade' , 'rejected off topic parrots' , 'rejected illegal trade circunstancial' , 'rejected opinion','rejected overview','included in review','not available');
  foreach(array_values($optfiltro) as $val) {
    $opts .= "<option value='$val'>$val</option>";
  }
  echo "<FORM ACTION='show-reference.php' METHOD='POST'>
  Aplicar filtro 2 <br/>
  <input type='hidden' name='UT' value='".$refid."'></input>
<select name='status'>
$opts
</select></br>
Revisado por <input type='text' name='reviewed_by' value='Ada Sanchez'></input>

<INPUT TYPE='submit' NAME='filtrar'/>
  </FORM>";

}

  #        echo "Tenemos ".$row["count"]." referencias en base de datos";
   }

   ?>

<h2>Lista de especies</h2>

<?php

$qry = "select * from psit.birdlife b LEFT JOIN psit.species_ref r
USING (scientific_name)
where ref_id ilike '%$refid%'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {
   $spplist .= "<li>".$row["scientific_name"]." (".$row["english_name"].") anotado por ".$row["reviewed_by"]."</li>";
}
echo "<ol>$spplist</ol>"
?>


<h2>Lista de paises</h2>

<?php

$qry = "select * from psit.countries b LEFT JOIN psit.country_ref r
ON b.\"Alpha_2\"=r.iso2
where ref_id ilike '%$refid%'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {
   $countrylist .= "<li>".$row["Name"]." (".$row["Alpha_2"].") anotado por ".$row["reviewed_by"]."</li>";
}
echo "<ol>$countrylist</ol>"
?>

<?php
include("inc/bye.php");
?>
