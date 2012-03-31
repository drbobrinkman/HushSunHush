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

$result = mysql_query("SELECT score, num_players_wind, num_players_wave FROM Score ORDER BY id DESC LIMIT 1");

while($row = mysql_fetch_array($result))
  {
    echo $row['score'] . " ";
    echo $row['num_players_wind'] . " ";
    echo $row['num_players_wave'] . " ";
  }

mysql_close($con);

?>