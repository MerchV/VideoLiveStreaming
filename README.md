# VideoLiveStreaming
Demonstrates live video streaming from iPhone to server using Apple HLS format. It is extremely rudimentary and in no sense is it ready for production. Notably it is lacking audio and the orientation is wrong and there are delays and pauses.

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

You should modify it to make sure that arbitrary files cannot be put to your server such as a revised PHP file. This file should expect files called master.m3u8 and master0.ts, master1.ts, etc. This PHP file goes on your server, e.g., http://example.com/put.php. 

Your server doesn't need anything special other than a way to accept HTTP PUT (or HTTP POST if you want to revise ViewController.swift). You don't need ffserver; you don't need Apple's media streaming tools. 

Once you've started capturing from your iPhone, after about 30 seconds, open VLC to the playlist file on your endpoint (e.g., http://example.com/master.m3u8). 

The Xcode project includes https://github.com/OpenWatch/FFmpegWrapper and https://github.com/chrisballinger/FFmpeg-iOS already built. 

