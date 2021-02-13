
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



$dbhost = $_SERVER['RDS_HOSTNAME'];
$dbport = $_SERVER['RDS_PORT'];
$dbname = $_SERVER['RDS_DB_NAME'];
$charset = 'UTF8' ;

//$dsn = "mysql:host={$dbhost};port={$dbport};dbname={$dbname};charset={$charset}";
$username = $_SERVER['RDS_USERNAME'];
$password = $_SERVER['RDS_PASSWORD'];

//$pdo = new PDO($dsn, $username, $password);

$dbconn = pg_connect("host=$dbhost port=$dbport dbname=$dbname user=$username password=$password options='--client_encoding=$charset'")
   or die("Could not connect");


#$dbconn = pg_connect("host=terra.ad.unsw.edu.au dbname=litrev user=jferrer password=$clavepasajera options='--client_encoding=UTF8'")


   ## print "Connected successfully<br/>";
   if (   $project == 'Illegal Wildlife Trade') {
     $head ="<h1>Revision bibliografica ''$project''</h1>
     <A HREF='index.php'>HOME</A> /
     <a href='list-countries.php'>Countries</a> /
     <a href='list-species.php'>Species</a>";

   }

echo $head;

#echo "GO TO: <a href='http://lit-rev-app.eba-ibdrhxhz.ap-southeast-2.elasticbeanstalk.com/psit/index.php'>test website</a>";

?>
