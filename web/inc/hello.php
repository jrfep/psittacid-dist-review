
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

$dbconn = pg_connect("host=terra.ad.unsw.edu.au dbname=litrev user=jferrer password=$clavepasajera options='--client_encoding=UTF8'")
   or die("Could not connect");

   ## print "Connected successfully<br/>";
   $project='Illegal Wildlife Trade';
   $head ="<h1>Revision bibliografica ''$project''</h1>
   <A HREF='index.php'>HOME</A> /
   <a href='list-countries.php'>Countries</a> /
   <a href='list-species.php'>Species</a>";

echo $head;


?>
