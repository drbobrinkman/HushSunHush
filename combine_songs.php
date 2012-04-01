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


$fp = fopen('songs_lock.txt', 'rw+');

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
    
    $result = mysql_query("SELECT * FROM Contributed WHERE channel=0 ORDER BY id");
    $counts = array(
		    1 => 0,
		    2 => 0,
		    3 => 0,
		    4 => 0,
		    5 => 0,
		    6 => 0,
		    7 => 0,
		    8 => 0);
    $max_count = 0;
    $max_val = 0;
    $max_id = 0;
    echo mysql_error();

    while($row = mysql_fetch_array($result))
      {
	if($row['id'] > $max_id){
	  $max_id = $row['id'];
	}

	$num = $row['num_notes'];
	if($num != 0){
	  $counts[$num]++;
	  if($counts[$num] > $max_count){
	    $max_count = $counts[$num];
	    $max_val = $num;
	  }
	}
      }

    //var_dump($counts);
    echo mysql_error();

    //Start over at beginning
    mysql_data_seek($result,0);

    echo mysql_error();

    $starts = array(
		    1 => 0,
		    2 => 0,
		    3 => 0,
		    4 => 0,
		    5 => 0,
		    6 => 0,
		    7 => 0,
		    8 => 0);
    $ends = array(
		    1 => 0,
		    2 => 0,
		    3 => 0,
		    4 => 0,
		    5 => 0,
		    6 => 0,
		    7 => 0,
		    8 => 0);
    while($row = mysql_fetch_array($result))
      {
	if($row['num_notes'] == $max_val){
	  $starts[1] += $row['note1_start'];
	  $starts[2] += $row['note2_start'];
	  $starts[3] += $row['note3_start'];
	  $starts[4] += $row['note4_start'];
	  $starts[5] += $row['note5_start'];
	  $starts[6] += $row['note6_start'];
	  $starts[7] += $row['note7_start'];
	  $starts[8] += $row['note8_start'];

	  $ends[1] += $row['note1_end'];
	  $ends[2] += $row['note2_end'];
	  $ends[3] += $row['note3_end'];
	  $ends[4] += $row['note4_end'];
	  $ends[5] += $row['note5_end'];
	  $ends[6] += $row['note6_end'];
	  $ends[7] += $row['note7_end'];
	  $ends[8] += $row['note8_end'];
	}
      }

    echo mysql_error();

    $starts[1] = $starts[1] / $max_count;
    $starts[2] = $starts[2] / $max_count;
    $starts[3] = $starts[3] / $max_count;
    $starts[4] = $starts[4] / $max_count;
    $starts[5] = $starts[5] / $max_count;
    $starts[6] = $starts[6] / $max_count;
    $starts[7] = $starts[7] / $max_count;
    $starts[8] = $starts[8] / $max_count;

    $ends[1] = $ends[1] / $max_count;
    $ends[2] = $ends[2] / $max_count;
    $ends[3] = $ends[3] / $max_count;
    $ends[4] = $ends[4] / $max_count;
    $ends[5] = $ends[5] / $max_count;
    $ends[6] = $ends[6] / $max_count;
    $ends[7] = $ends[7] / $max_count;
    $ends[8] = $ends[8] / $max_count;

    if($starts[1] > $ends[1]) $ends[1] = $starts[1];
    if($starts[2] > $ends[2]) $ends[2] = $starts[2];
    if($starts[3] > $ends[3]) $ends[3] = $starts[3];
    if($starts[4] > $ends[4]) $ends[4] = $starts[4];
    if($starts[5] > $ends[5]) $ends[5] = $starts[5];    
    if($starts[6] > $ends[6]) $ends[6] = $starts[6];
    if($starts[7] > $ends[7]) $ends[7] = $starts[7];
    if($starts[8] > $ends[8]) $ends[8] = $starts[8];



      mysql_query("INSERT INTO Song (num_notes, channel, note1_start, note1_end, ".
		  "note2_start, note2_end, note3_start, note3_end, note4_start, note4_end, ".
		  "note5_start, note5_end, note6_start, note6_end, note7_start, note7_end, ".
		  "note8_start, note8_end".
		  ") VALUES ($max_val, 0, $starts[1], $ends[1], ".
		  "$starts[2], $ends[2], $starts[3], $ends[3], $starts[4], $ends[4], ".
		  "$starts[5], $ends[5], $starts[6], $ends[6], $starts[7], $ends[7], ".
		  "$starts[8], $ends[8]".
		  ")");

      echo mysql_error();











    $result = mysql_query("SELECT * FROM Contributed WHERE channel=1 ORDER BY id");
    $counts = array(
		    1 => 0,
		    2 => 0,
		    3 => 0,
		    4 => 0,
		    5 => 0,
		    6 => 0,
		    7 => 0,
		    8 => 0);
    $max_count = 0;
    $max_val = 0;
    echo mysql_error();

    while($row = mysql_fetch_array($result))
      {
	if($row['id'] > $max_id){
	  $max_id = $row['id'];
	}

	$num = $row['num_notes'];
	if($num != 0){
	  $counts[$num]++;
	  if($counts[$num] > $max_count){
	    $max_count = $counts[$num];
	    $max_val = $num;
	  }
	}
      }

    //var_dump($counts);
    echo mysql_error();

    //Start over at beginning
    mysql_data_seek($result,0);

    echo mysql_error();

    $starts = array(
		    1 => 0,
		    2 => 0,
		    3 => 0,
		    4 => 0,
		    5 => 0,
		    6 => 0,
		    7 => 0,
		    8 => 0);
    $ends = array(
		    1 => 0,
		    2 => 0,
		    3 => 0,
		    4 => 0,
		    5 => 0,
		    6 => 0,
		    7 => 0,
		    8 => 0);
    while($row = mysql_fetch_array($result))
      {
	if($row['num_notes'] == $max_val){
	  $starts[1] += $row['note1_start'];
	  $starts[2] += $row['note2_start'];
	  $starts[3] += $row['note3_start'];
	  $starts[4] += $row['note4_start'];
	  $starts[5] += $row['note5_start'];
	  $starts[6] += $row['note6_start'];
	  $starts[7] += $row['note7_start'];
	  $starts[8] += $row['note8_start'];

	  $ends[1] += $row['note1_end'];
	  $ends[2] += $row['note2_end'];
	  $ends[3] += $row['note3_end'];
	  $ends[4] += $row['note4_end'];
	  $ends[5] += $row['note5_end'];
	  $ends[6] += $row['note6_end'];
	  $ends[7] += $row['note7_end'];
	  $ends[8] += $row['note8_end'];
	}
      }

    echo mysql_error();

    $starts[1] = $starts[1] / $max_count;
    $starts[2] = $starts[2] / $max_count;
    $starts[3] = $starts[3] / $max_count;
    $starts[4] = $starts[4] / $max_count;
    $starts[5] = $starts[5] / $max_count;
    $starts[6] = $starts[6] / $max_count;
    $starts[7] = $starts[7] / $max_count;
    $starts[8] = $starts[8] / $max_count;

    $ends[1] = $ends[1] / $max_count;
    $ends[2] = $ends[2] / $max_count;
    $ends[3] = $ends[3] / $max_count;
    $ends[4] = $ends[4] / $max_count;
    $ends[5] = $ends[5] / $max_count;
    $ends[6] = $ends[6] / $max_count;
    $ends[7] = $ends[7] / $max_count;
    $ends[8] = $ends[8] / $max_count;

    if($starts[1] > $ends[1]) $ends[1] = $starts[1];
    if($starts[2] > $ends[2]) $ends[2] = $starts[2];
    if($starts[3] > $ends[3]) $ends[3] = $starts[3];
    if($starts[4] > $ends[4]) $ends[4] = $starts[4];
    if($starts[5] > $ends[5]) $ends[5] = $starts[5];    
    if($starts[6] > $ends[6]) $ends[6] = $starts[6];
    if($starts[7] > $ends[7]) $ends[7] = $starts[7];
    if($starts[8] > $ends[8]) $ends[8] = $starts[8];



      mysql_query("INSERT INTO Song (num_notes, channel, note1_start, note1_end, ".
		  "note2_start, note2_end, note3_start, note3_end, note4_start, note4_end, ".
		  "note5_start, note5_end, note6_start, note6_end, note7_start, note7_end, ".
		  "note8_start, note8_end".
		  ") VALUES ($max_val, 1, $starts[1], $ends[1], ".
		  "$starts[2], $ends[2], $starts[3], $ends[3], $starts[4], $ends[4], ".
		  "$starts[5], $ends[5], $starts[6], $ends[6], $starts[7], $ends[7], ".
		  "$starts[8], $ends[8]".
		  ")");

      echo mysql_error();
      //echo $max_id;
    
      mysql_query("DELETE FROM Contributed WHERE id <= $max_id");

    mysql_close($con);
  }
 }

/* ... */

fclose($fp);




?>