
<html>
<body>
<?php
$filename = "/Users/jferrer/.pgpass.php";
if (file_exists($filename)) {
  include($filename);
}
$filename = "/home/jferrer/.pgpass.php";
if (file_exists($filename)) {
  include($filename);
}
## This is the composer part...
## require __DIR__ . '/../vendor/autoload.php';

function trimq($a) {
  return trim($a,'""');
}


if (isset($claveaws)) {
   $dbconn = pg_connect("host=$dbhost2 port=$dbport dbname=$dbname2 user=$username password=$claveaws2 options='--client_encoding=$charset'")
      or die("Could not connect to external server from localhost");
      $webhost="<h1>(TERRA)</h1>";

} else {
   $dbhost = $_SERVER['RDS_HOSTNAME'];
   $dbport = $_SERVER['RDS_PORT'];
   $dbname = $_SERVER['RDS_DB_NAME'];
   $charset = 'UTF8' ;
   $username = $_SERVER['RDS_USERNAME'];
   $password = $_SERVER['RDS_PASSWORD'];

   $dbconn = pg_connect("host=$dbhost port=$dbport dbname=$dbname user=$username password=$password options='--client_encoding=$charset'")
      or die("Could not connect in beanstalk");
   $webhost="";

}


#$dbconn = pg_connect("host=terra.ad.unsw.edu.au dbname=litrev user=jferrer password=$clavepasajera options='--client_encoding=UTF8'")
if (isset($_REQUEST["project"])) {
  $project = $_REQUEST["project"];
     ## print "Connected successfully<br/>";
         $head ="<h1>Revision bibliografica ''$project''</h1>
         <A HREF='index.php'>All projects</A> /
         <A HREF='project-home.php?project=$project'>This project</A> /
         <a href='list-countries.php?project=$project'>Countries</a> /
       <a href='list-species.php?project=$project'>Species</a>";


  echo $head;
}

#echo "GO TO: <a href='http://lit-rev-app.eba-ibdrhxhz.ap-southeast-2.elasticbeanstalk.com/psit/index.php'>test website</a>";

?>
