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

$num_notes = htmlspecialchars($_GET["num_notes"]);
if($num_notes == null || $num_notes < 0 || $num_notes > 8){
  $num_notes = 0;
}
$channel = htmlspecialchars($_GET["channel"]);
if($channel == null || ($channel != 1 && $channel != 0)){
  $channel = 0;
 }

$note1_start = htmlspecialchars($_GET["note1_start"]);
if($note1_start == null || $note1_start < 0 || $note1_start > 179){
  $note1_start = 0;
}
$note1_end = htmlspecialchars($_GET["note1_end"]);
if($note1_end == null || $note1_end < 0 || $note1_end > 179){
  $note1_end = 0;
  if($note1_end < $note1_start){
    $note1_start = 0;
    $note1_end = 45;
  }
}

$note2_start = htmlspecialchars($_GET["note2_start"]);
if($note2_start == null || $note2_start < 0 || $note2_start > 179){
  $note2_start = 0;
}
$note2_end = htmlspecialchars($_GET["note2_end"]);
if($note2_end == null || $note2_end < 0 || $note2_end > 179){
  $note2_end = 0;
  if($note2_end < $note2_start){
    $note2_start = 0;
    $note2_end = 45;
  }
}

$note3_start = htmlspecialchars($_GET["note3_start"]);
if($note3_start == null || $note3_start < 0 || $note3_start > 179){
  $note3_start = 0;
}
$note3_end = htmlspecialchars($_GET["note3_end"]);
if($note3_end == null || $note3_end < 0 || $note3_end > 179){
  $note3_end = 0;
  if($note3_end < $note3_start){
    $note3_start = 0;
    $note3_end = 45;
  }
}

$note4_start = htmlspecialchars($_GET["note4_start"]);
if($note4_start == null || $note4_start < 0 || $note4_start > 179){
  $note4_start = 0;
}
$note4_end = htmlspecialchars($_GET["note4_end"]);
if($note4_end == null || $note4_end < 0 || $note4_end > 179){
  $note4_end = 0;
  if($note4_end < $note4_start){
    $note4_start = 0;
    $note4_end = 45;
  }
}

$note5_start = htmlspecialchars($_GET["note5_start"]);
if($note5_start == null || $note5_start < 0 || $note5_start > 179){
  $note5_start = 0;
}
$note5_end = htmlspecialchars($_GET["note5_end"]);
if($note5_end == null || $note5_end < 0 || $note5_end > 179){
  $note5_end = 0;
  if($note5_end < $note5_start){
    $note5_start = 0;
    $note5_end = 45;
  }
}

$note6_start = htmlspecialchars($_GET["note6_start"]);
if($note6_start == null || $note6_start < 0 || $note6_start > 179){
  $note6_start = 0;
}
$note6_end = htmlspecialchars($_GET["note6_end"]);
if($note6_end == null || $note6_end < 0 || $note6_end > 179){
  $note6_end = 0;
  if($note6_end < $note6_start){
    $note6_start = 0;
    $note6_end = 45;
  }
}

$note7_start = htmlspecialchars($_GET["note7_start"]);
if($note7_start == null || $note7_start < 0 || $note7_start > 179){
  $note7_start = 0;
}
$note7_end = htmlspecialchars($_GET["note7_end"]);
if($note7_end == null || $note7_end < 0 || $note7_end > 179){
  $note7_end = 0;
  if($note7_end < $note7_start){
    $note7_start = 0;
    $note7_end = 45;
  }
}

$note8_start = htmlspecialchars($_GET["note8_start"]);
if($note8_start == null || $note8_start < 0 || $note8_start > 179){
  $note8_start = 0;
}
$note8_end = htmlspecialchars($_GET["note8_end"]);
if($note8_end == null || $note8_end < 0 || $note8_end > 179){
  $note8_end = 0;
  if($note8_end < $note8_start){
    $note8_start = 0;
    $note8_end = 45;
  }
}

$query = "INSERT INTO Contributed (num_notes, channel, note1_start, note1_end," . 
  " note2_start, note2_end, note3_start, note3_end, note4_start, note4_end," .
  " note5_start, note5_end, note6_start, note6_end, note7_start, note7_end," .
  " note8_start, note8_end) VALUES " .
  "($num_notes, $channel, $note1_start, $note1_end," . 
  " $note2_start, $note2_end, $note3_start, $note3_end, $note4_start, $note4_end," .
  " $note5_start, $note5_end, $note6_start, $note6_end, $note7_start, $note7_end," .
  " $note8_start, $note8_end)";

$result = mysql_query($query);

mysql_close($con);

//If all goes well, check and see if it is time to combine scores
//include_once "combine_songs.php";

?>