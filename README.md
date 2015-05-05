# VideoLiveStreaming
Demonstrates live video streaming from iPhone to server. It is extremely rudimentary and in no sense is it ready for production. Notably it is lacking audio and the orientation is wrong and there are delays and pauses.

Most of the action happens in Classes/ViewController.swift. First, set your endpoint. This can be a PHP file on your publicly-visible web host. 

Your PHP file can look like this:

<?php
$putdata = fopen("php://input", "r");
$fp = fopen($_GET['filename'], "w");
while ($data = fread($putdata, 1024))
  fwrite($fp, $data);
fclose($fp);
fclose($putdata);
?>

You should modify it to make sure that arbitrary files cannot be put to your server such as a revised PHP file. This file should expect files called master.m3u8 and master0.ts, master1.ts, etc.
