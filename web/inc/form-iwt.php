<?php
$opt2s=$opt3s=$opt5s="";

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

$form_annotation = "
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
   <input type='text' list='projects' name='project' value='$project'></input>
   <datalist id='projects'>
   <option>Illegal Wildlife Trade</option>
   <option>Species distribution models</option>
   <option>Other...</option>
   </datalist>
      </td></tr>
  </table>

<INPUT TYPE='submit' NAME='anotar'/>
</FORM></div>";

?>
