<?php

/**
 * Retrieve the most recent version of the song from the server.
 *
 * Input: Channel number (0 for wind, 1 for waves)
 * Output: Timestamp num_notes channel note1_start note1_end
 *         note2_start note2_end note3_start ... note8_end
 * 
 * Author: Bo Brinkman
 * Date  : 2012-03-25
 * 
 * Released under a Creative Commons 3.0 Unported license. 
 *  (See http://creativecommons.org/licenses/by/3.0/)
 * This means you are free to share, remix, and make commercial use 
 *  of this work as long as you give attribution.
 * 
 * Note that this code is based on the example at 
 * http://www.w3schools.com/php/php_mysql_select.asp
 **/

$con = mysql_connect("localhost","kiswhs_player","b5k;tJeATa[U");
if (!$con)
  {
  die('Could not connect: ' . mysql_error());
  }

mysql_select_db("kiswhs_hushsunhush", $con);

$channel = htmlspecialchars($_GET["channel"]);
if($channel == null || ($channel != 1 && $channel != 0)){
  $channel = 0;
 }

$result = mysql_query("SELECT *, UNIX_TIMESTAMP(time) AS time FROM Song WHERE channel=".$channel." ORDER BY id DESC LIMIT 1");

while($row = mysql_fetch_array($result))
  {
    echo $row['time'] . " ";
    echo $row['num_notes'] . " ";
    echo $row['channel']. " ";
    echo $row['note1_start']. " ";
    echo $row['note1_end']. " ";
    echo $row['note2_start']. " ";
    echo $row['note2_end']. " ";
    echo $row['note3_start']. " ";
    echo $row['note3_end']. " ";
    echo $row['note4_start']. " ";
    echo $row['note4_end']. " ";
    echo $row['note5_start']. " ";
    echo $row['note5_end']. " ";
    echo $row['note6_start']. " ";
    echo $row['note6_end']. " ";
    echo $row['note7_start']. " ";
    echo $row['note7_end']. " ";
    echo $row['note8_start']. " ";
    echo $row['note8_end']. " ";
  }

mysql_close($con);

?>