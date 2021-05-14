<?php
$colopts = array();
$columns = array('topics', 'general_application', 'specific_issue', 'paradigm', 'species_range', 'analysis_type', 'data_source', 'model_type');

foreach ($columns as $key) {
  $colopts[$key] = "";
  $qry = "select unnest($key),count(*) from psit.distmodel_ref group by unnest order by count";
  $result = pg_query($dbconn, $qry);
  if (!$result) { echo "An error occurred.\n"; exit;}
  while ($rw2 = pg_fetch_row($result)) { $colopts[$key] .= "<input type='checkbox' value='$rw2[0]' name='".$key."[]' multiple>$rw2[0] ($rw2[1]) / ";}
}


$form_filtro3 = "
<h3>Annotation</h3>
<div style='background-color: #DDAAAA; width:800px;'>
<FORM ACTION='show-reference.php' METHOD='POST'>
Annotate reference: <br/>
Use the format <emph>{value1,value2,...}</emph> for multiple values.

<input type='hidden' name='UT' value='".$refid."'></input>
<table>
<tr><td>Topics</td><td><input type='text' name='topics' size='50'></input></td><td style='font-size:10;'>$colopts[topics]</td></tr>

<tr><td>General application</td><td><input type='text' name='general_application' size='50' placeholder='{...,...,...}'></input></td><td style='font-size:10;'>$colopts[general_application]</td></tr>
<tr><td>Specific issue</td><td><input type='text' name='specific_issue' size='50' placeholder='{...,...,...}'></input></td><td style='font-size:10;'>$colopts[specific_issue]</td></tr>
<tr><td>Paradigm</td><td><input type='text' name='paradigm' size='50' placeholder='{ENM,OM,RSF}'></input></td><td style='font-size:10;'>$colopts[paradigm]</td></tr>
<tr><td>Species range</td><td><input type='text' name='species_range' size='50' placeholder='{...,...,...}'></input></td><td style='font-size:10;'>$colopts[species_range]</td></tr>


<tr><td>Analysis type</td><td><input type='text' name='analysis_type' size='50' placeholder='{spatial prediction, hypothesis test,...}'></input></td><td style='font-size:10;'>$colopts[analysis_type]</td></tr>
<tr><td>Model type</td><td><input type='text' name='model_type' size='50' placeholder='{maxent,GARP,MARK,...}'></input></td><td style='font-size:10;'>$colopts[model_type]</td></tr>
<tr><td>Data sources</td><td><input type='text' name='data_source' size='50'placeholder='{field-work,natural history collections,...}' ></input></td><td style='font-size:10;'>$colopts[data_source]</td></tr>

<tr><td>
Country comments
</td><td>
 <input type='text' name='country_list'  size='50'></input>
</td></tr>
<tr><td>
Species comments
</td><td>
 <input type='text' name='species_list'  size='50'></input>
</td></tr>

  <tr><td>
Revisado por
  </td><td>
<input type='text' list='reviewers' name='reviewed_by' size='40'></input>
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
   <input type='text' list='projects' name='project' value='$project'  size='40'></input>
   <datalist id='projects'>
   <option>Illegal Wildlife Trade</option>
   <option>Species distribution models</option>
   <option>Other...</option>
   </datalist>
      </td></tr>
  </table>

<INPUT TYPE='submit' NAME='Add annotation'/>
</FORM></div>";

?>
