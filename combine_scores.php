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


$fp = fopen('score_lock.txt', 'rw+');

/* Activate the LOCK_NB option on an LOCK_EX operation */
if(flock($fp, LOCK_EX | LOCK_NB)) {
  $cur_time = time();
  $file_read = fscanf($fp,"%d");
  list ($old_time) = $file_read;

  if($cur_time - $old_time >= 6){ //Only refresh once every 6 seconds
    fseek($fp,0);
    ftruncate($fp, 0);      // truncate file
    fwrite($fp, "$cur_time");
    fflush($fp);
  
    /*
     * If we got the lock, our job is to combine all the current contrib scores
     */
    $con = mysql_connect("localhost","kiswhs_player","b5k;tJeATa[U");
    if (!$con)
      {
	die('Could not connect: ' . mysql_error());
      }
    
    mysql_select_db("kiswhs_hushsunhush", $con);
    
    $result = mysql_query("SELECT * FROM Score_contrib ORDER BY id");
    $max_id = 0;
    
    $score = 0;
    $count_0 = 0;
    $count_1 = 0;
    
    while($row = mysql_fetch_array($result))
      {
	//echo $row['score'] . " ";
	//echo $row['team'] . "<br />";
	if($row['id'] > $max_id){
	  $max_id = $row['id'];
	}
	if($row['score'] > 0){
	  $score = $score + $row['score'];
	  if($row['team'] == 0){
	    $count_0++;
	    
	  } else {
	    $count_1++;
	    
	  }
	}
      }
    
    if($score > 0){
      mysql_query("INSERT INTO Score (score, num_players_wind, num_players_wave) VALUES ($score, $count_0, $count_1)");
    }
    mysql_query("DELETE FROM Score_contrib WHERE id <= $max_id");

    mysql_close($con);
  }
 }

/* ... */

fclose($fp);




?>