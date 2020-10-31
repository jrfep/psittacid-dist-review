<?php
include("inc/hello.php");
?>


<?php

$refid = $_REQUEST["UT"];
$project = $_REQUEST["project"];
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
  $qry = "INSERT INTO psit.filtro2 (ref_id,".implode($columns,", ").",reviewed_date) values ('".$refid."',".implode($values,", ").",CURRENT_TIMESTAMP(0)) ON CONFLICT DO NOTHING ";
  $res = pg_query($dbconn, $qry);
   if ($res) {
     print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
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
      print "<BR/><font color='#DD8B8B'>POST data is successfully logged</font><BR/>\n";
   } else {
      print "<BR/><font color='#DD8B8B'>User must have sent wrong inputs<BR/><BR/>$qry</font><BR/><BR/>\n";
   }
  #echo $qry;
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
$qry = "select \"TI\",\"DE\",\"AB\",\"DI\", abstract,title,keyword,f.reviewed_by,project as rev1 FROM psit.bibtex b
  LEFT JOIN psit.filtro1 f ON b.\"UT\"=f.ref_id
WHERE \"UT\" = '$refid' ";


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
$qry = "select \"TI\",\"DE\",\"AB\",\"DI\", contribution, action, status, data_type, country_list, species_list, project, f.reviewed_by as rev1, a.reviewed_by as rev2 FROM psit.bibtex b
LEFT JOIN  psit.annotate_ref a ON b.\"UT\"=a.ref_id
  LEFT JOIN psit.filtro2 f ON b.\"UT\"=f.ref_id
WHERE \"UT\" ilike '%$refid%'";


 $result = pg_query($dbconn, $qry);
 if (!$result) {
   echo "An error occurred.\n";
   exit;
 }

 while ($row = pg_fetch_assoc($result))  {

if ($row["status"]!='') {
  echo "<h3>Filtro 2</h3>
    <div style='background-color: #AAAADD; width:300px;'><p> Classified as <b>".$row["status"]."</b> by ".$row["rev1"]."</p></div>";

  if ($row["status"]=='included in review') {
    if ($row["action"]!='') {
        echo "  <h3>Annotation</h3>

        <div style='background-color: #AAAADD; width:800px;'>
        <TABLE>
        <tr><th> Data type</th><td>".$row["data_type"]."</td></tr>
        <tr><th> Action</th><td>".$row["action"]."</td></tr>
        <tr><th> Contribution</th><td>".$row["contribution"]."</td></tr>
        <tr><th> Comments to country list</th><td>".$row["country_list"]."</td></tr>
        <tr><th> Comments to species list</th><td>".$row["species_list"]."</td></tr>
        <tr><th> Reviewed by</th><td>".$row["rev2"]."</td></tr>
        <tr><th> Project</th><td>".$row["project"]."</td></tr>
        </TABLE>
<a href='edit-annotation.php?refid=$refid&origcontribution=".$row["contribution"]."&origaction=".$row["action"]."'>EDIT this entry</a>
        </div>";

      } else {

        $optcontrib = array('basic knowledge' , 'implementation', 'monitoring');

        foreach(array_values($optcontrib) as $val) {
          $opt2s .= "<option value='$val'>$val</option>";
        }


        $opttypes = array('interview','literature review','official report', 'field survey', 'cites', 'seizure', 'internet');


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

        echo "
        <h3>Annotation</h3>
        <div style='background-color: #DDAAAA; width:800px;'>
        <FORM ACTION='show-reference.php' METHOD='POST'>
        Anotar referencia <br/>
        <input type='hidden' name='UT' value='".$refid."'></input>


        <table>
        <tr><td>
        Contribution

        </td><td>
        <select name='contribution'>
               $opt2s
               </select>
        </td></tr>
        <tr><td>
Action
        </td><td>
        <select name='action'>
        $opt3s
        </select>
        </td></tr>

        <tr><td>
      Country comments <br/> use comma (',') for multiple entries
        </td><td>
         <input type='text' name='country_list'></input>
        </td></tr>
        <tr><td>
      Species comments <br/> use comma (',') for multiple entries
        </td><td>
         <input type='text' name='species_list'></input>
        </td></tr>

          <tr><td>
          Data type (select multiple)
          </td><td>
          <select name='data_type[]' multiple>
          $opt5s
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
           <input type='text' list='projects' name='project' value='Illegal Wildlife Trade'></input>
           <datalist id='projects'>
           <option>Illegal Wildlife Trade</option>
           <option>Species Distribution Models</option>
           <option>Other...</option>
           </datalist>
              </td></tr>
          </table>

        <INPUT TYPE='submit' NAME='anotar'/>
        </FORM></div>";
      }

  }
} else {
  $optfiltro = array('rejected off topic illegal trade' , 'rejected off topic parrots' , 'rejected illegal trade circunstancial' , 'rejected opinion','rejected overview','included in review','not available');
  foreach(array_values($optfiltro) as $val) {
    $opts .= "<option value='$val'>$val</option>";
  }
  echo "<h3>Filtro 2</h3>
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
 <input type='text' list='projects' name='project' value='Illegal Wildlife Trade'></input>
 <datalist id='projects'>
 <option>Illegal Wildlife Trade</option>
 <option>Species Distribution Models</option>
 <option>Other...</option>
 </datalist>

  </td></tr>
  </table>

<INPUT TYPE='submit' NAME='filtrar'/>
  </FORM>
  </div>";

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
   $spplist .= "<li>".$row["scientific_name"]." (".$row["english_name"].") anotado por ".$row["reviewed_by"]." [<a href='edit-species.php?refid=$refid&spp=".$row["scientific_name"]."'>EDIT</a>]</li>";
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
