<?php
include("inc/hello.php");
?>


<?php
$URLS="";
$opts=$opt2s=$opt3s=$opt4s=$opt5s="";
$spplist=$countrylist=$lis="";
$refid = $_REQUEST["UT"];
#print_r($_REQUEST);
if (isset($_REQUEST["filtrar"])) {

foreach ($_POST as $key => $value) {
      if (in_array($key, array("status","project","reviewed_by"))) {
         if ($value!="") {
            $columns[]= $key;
            $values[] = "'$value'";
         }
      }
   }
  $qry = "INSERT INTO psit.filtro2 (ref_id,".implode(", ",$columns).",reviewed_date) values ('".$refid."',".implode(", ",$values).",CURRENT_TIMESTAMP(0)) ON CONFLICT DO NOTHING ";
  $res = pg_query($dbconn, $qry);
   if ($res) {
     print "<BR/><font color='#DD8B8B'>POST data is successfully logged<BR/>$qry<BR/></font>\n";
  } else {
     print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
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
      print "<BR/><font color='#DD8B8B'>POST data is successfully logged: $qry</font><BR/>\n";
   } else {
      print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
  #echo $qry;
}
##print_r($_REQUEST);

if (isset($_REQUEST["Add_annotation"])) {

foreach ($_POST as $key => $value) {
  if (in_array($key, array("model_type", "topics", "data_source", "analysis_type", "species_list", "country_list","reviewed_by")) & $value!="") {
      $columns[]= $key;
      if (is_array($value)) {
        $values[] = "'{".implode(',',$value)."}'";
      } else {
         if ($key == "reviewed_by") {
            $values[] = "'$value'";
         } else {
            $values[] = "'{".str_replace(array('{','}','"'),"",$value)."}'";
         }
      }
    }
   }
  $qry = "INSERT INTO psit.distmodel_ref (ref_id,".implode(", ",$columns).",reviewed_date) values ('".$refid."',".implode(", ",$values).",CURRENT_TIMESTAMP(0)) ON CONFLICT DO NOTHING ";
  $res = pg_query($dbconn, $qry);
   if ($res) {
      print "<BR/><font color='#DD8B8B'>POST data is successfully logged: $qry</font><BR/>\n";
   } else {
      print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
  ##echo $qry;
}


?>

<?php
$qry = "select \"TI\",\"DE\",\"AB\",\"DI\" from psit.bibtex b
where \"UT\" ilike '%$refid%'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {
   $kwds = explode(";",$row["DE"]);
   foreach($kwds as $v) {
          $URLS.="<a href='list-by-DE.php?DE=$v'>$v</a> / ";
        }
             echo "<p><b>".$row["TI"]."</b>
             <br/> keywords ".$URLS."<br/>
             <br/> abstract ".$row["AB"]."<br/>
             <br/>  DOI:<a target='_blank' href='http://dx.doi.org/".$row["DI"]."'>".$row["DI"]."</a></p>
             ";

}
?>

<?php
$qry = "select \"TI\",\"DE\",\"AB\",\"DI\", abstract,title,keyword,f.reviewed_by as rev1,project FROM psit.bibtex b
  LEFT JOIN psit.filtro1 f ON b.\"UT\"=f.ref_id
WHERE \"UT\" = '$refid' AND project='$project'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred. $qry\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {

if ($row["rev1"]!='') {
  if ($row["title"]!="")
    $lis .= "<li>Title: ".$row["title"]."</li>";
    if ($row["abstract"]!="")
    $lis .=     "<li>Abstract: ".$row["abstract"]."</li>";
    if ($row["keyword"]!="")
    $lis .=   "<li>Keywords: ".$row["keyword"]."</li>";

  echo "<h3>Filtro 1</h3>
    <div style='background-color: #AAAADD; width:600px;'><p> Included in filter 1 for project ".$row["project"]." by ".$row["rev1"]." with following search terms:
    <ul>$lis</ul>
    </p></div>";
  } else {
    echo "<h3>Filtro 1</h3>
      <div style='background-color: #DDAAAA; width:600px;'><p> Not included in filter 1 .
      </p></div>";
  }
}
?>

<?php
$status_filtro2 = 'missing';
$optfiltro = array(
  'rejected off topic' ,
  'rejected off topic (not related to project)' ,
  'rejected off topic (not related to taxon)' ,
  'rejected illegal (circunstancial)' ,
  'rejected opinion','rejected overview',
  'included in review','not available');
foreach(array_values($optfiltro) as $val) {
  $opts .= "<option value='$val'>$val</option>";
}
$form_filtro2 = "<h3>Filtro 2</h3>
<div style='background-color: #DDAAAA; width:600px;'>
<FORM ACTION='show-reference.php' METHOD='POST'>
  <input type='hidden' name='UT' value='".$refid."'></input>
<table>
<tr><td>
  Aplicar filtro 2
</td><td>
<select name='status'>
$opts
</select>
</td></tr>
<tr><td>
Revisado por
</td><td>
<input type='text' list='reviewers' name='reviewed_by'></input>
<datalist id='reviewers'>
<option>Ada Sanchez</option>
<option>JRFP</option>
<option>Anonymous</option>
<option>Other...</option>
</datalist>

</td></tr>
<tr><td>
Project
</td><td>
<input type='text' list='projects' name='project' value='$project'></input>
<datalist id='projects'>
<option>Illegal Wildlife Trade</option>
<option>Species distribution models</option>
<option>Other...</option>
</datalist>

</td></tr>
</table>

<INPUT TYPE='submit' NAME='filtrar'/>
</FORM>
</div>";

$qry = "select status, reviewed_by as rev2, reviewed_date  FROM psit.bibtex b
  LEFT JOIN psit.filtro2 f ON b.\"UT\"=f.ref_id
WHERE \"UT\" ilike '%$refid%' AND f.project='$project'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {

    if ($row["status"]!='') {
      $form_filtro2 = "<h3>Filtro 2</h3>
        <div style='background-color: #AAAADD; width:300px;'><p> Classified as <b>".$row["status"]."</b> by ".$row["rev2"]."</p></div>";
        $status_filtro2 = $row["status"];

    }
}
echo $form_filtro2;
?>


<?php
$form_filtro3 = "";

if ($status_filtro2 == 'included in review') {
  switch($project) {
    case "Illegal Wildlife Trade":

      include("inc/form-iwt.php");

      $qry = "SELECT contribution, action, data_type, country_list, species_list, reviewed_by as rev2
      FROM psit.bibtex b
      LEFT JOIN  psit.annotate_ref a ON b.\"UT\"=a.ref_id
      WHERE \"UT\" ilike '%$refid%' ";

      $result = pg_query($dbconn, $qry);
      if (!$result) { echo "An error occurred $qry.\n"; exit;}
      while ($row = pg_fetch_assoc($result))  {
              $form_filtro3 = "  <h3>Annotation</h3>

              <div style='background-color: #AAAADD; width:800px;'>
              <TABLE>
              <tr><th> Data type</th><td>".$row["data_type"]."</td></tr>
              <tr><th> Action</th><td>".$row["action"]."</td></tr>
              <tr><th> Contribution</th><td>".$row["contribution"]."</td></tr>
              <tr><th> Comments to country list</th><td>".$row["country_list"]."</td></tr>
              <tr><th> Comments to species list</th><td>".$row["species_list"]."</td></tr>
              <tr><th> Reviewed by</th><td>".$row["rev2"]."</td></tr>
              </TABLE>
      <a href='edit-annotation.php?refid=$refid&origcontribution=".$row["contribution"]."&origaction=".$row["action"]."'>EDIT this entry</a>
              </div>";

          }
    break;
    case "Species distribution models";
    include("inc/form-sdm.php");

    $qry = "SELECT analysis_type,model_type,data_source,topics, country_list, species_list, reviewed_by as rev2
    FROM psit.distmodel_ref
    WHERE ref_id ilike '%$refid%' ";

    $result = pg_query($dbconn, $qry);
    if (!$result) { echo "An error occurred $qry.\n"; exit;}
    while ($row = pg_fetch_assoc($result))  {
            $form_filtro3 = "  <h3>Annotation</h3>
            <div style='background-color: #AAAADD; width:800px;'>
            <TABLE>";
            foreach($row as $key => $val) {
              $vals = str_replace(array('{','}','"'),'',$val);
              $form_filtro3 .= "<tr><th> $key</th><td>".str_replace(array(','),' // ',$vals)."</td></tr>";
            }
            $form_filtro3 .= "

            </TABLE>
    <a href='edit-annotation.php?refid=$refid&project=$project'>EDIT this entry</a>
            </div>";

        }

    break;
  }

}

echo $form_filtro3;
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
   $spplist .= "<li><i><a href='list-by-species.php?spp=".$row["scientific_name"]."'>".$row["scientific_name"]."</a></i> (".$row["english_name"].") anotado por ".$row["reviewed_by"]." [<a href='edit-species.php?refid=$refid&spp=".$row["scientific_name"]."'>EDIT</a>]</li>";
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
   $countrylist .= "<li>".$row["Name"]." (<a href='list-by-country.php?ISO2=".$row["Alpha_2"]."'>".$row["Alpha_2"]."</a>). ".$row["country_role"].", reviewed by ".$row["reviewed_by"]." [<a href='edit-country.php?refid=$refid&iso2=".$row["Alpha_2"]."'>EDIT</a>]</li>";
}
echo "<ol>$countrylist</ol>"

// <tr><td>
// Country (select multiple)
// </td><td>
// <select name='country_list[]' multiple>
// $opt4s
// </select>
// </td></tr>

?>

<?php
include("inc/bye.php");
?>
