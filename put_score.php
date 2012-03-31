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

$score = htmlspecialchars($_GET["score"]);
if($score == null || $score < 0 && $score > 20){
  $score = 0;
}
$team = htmlspecialchars($_GET["team"]);
if($team == null || ($team != 1 && $team != 0)){
  $team = 0;
 }

$query = "INSERT INTO Score_contrib (score, team) VALUES ($score, $team)";
$result = mysql_query($query);

mysql_close($con);

//If all goes well, check and see if it is time to combine scores
include_once "combine_scores.php";

?>