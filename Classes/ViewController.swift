//
//  ViewController.swift
//
//  Created by mvisoiu on 2015-04-14.
//

import UIKit
import AVFoundation
import CoreMedia

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var avAssetWriter: AVAssetWriter!
    var avAssetWriterInput: AVAssetWriterInput!
    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var device: AVCaptureDevice!
    var output: AVCaptureVideoDataOutput!
    var currentIndex: Int!
    var maxTimer: NSTimer!
    var ffmpegWrapper: FFmpegWrapper!

    ///////////////////////////////////
    // SET YOUR SERVER ENDPOINT HERE //
    ///////////////////////////////////
    let endpointUrlString = "" // e.g., "http://example.com/put.php"  - See the GitHub readme for the PHP file.

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(count(self.endpointUrlString) > 0, "### You didn't provide your server endpoint URL string on line 26 ###")

        if let cachesDirectoryUrl = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).last as? NSURL {
            var error: NSError?
            if let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(cachesDirectoryUrl.path!, error: &error) {
                for cacheFile in contents {
                    let fileToDelete = cachesDirectoryUrl.URLByAppendingPathComponent(cacheFile as! String)
                    var removeError: NSError
                    NSFileManager.defaultManager().removeItemAtURL(fileToDelete, error: nil)

                }
                
            }
            
        }
        if let documentDirectoryUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as? NSURL {
            var error: NSError?
            if let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentDirectoryUrl.path!, error: &error) {
                for documentFile in contents {
                    let fileToDelete = documentDirectoryUrl.URLByAppendingPathComponent(documentFile as! String)
                    var removeError: NSError
                    NSFileManager.defaultManager().removeItemAtURL(fileToDelete, error: nil)
                    
                }
                
            }
            
        }
        

        
        
        ffmpegWrapper = FFmpegWrapper()

        maxTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "timer:", userInfo: nil, repeats: true)
        
        currentIndex = 0
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetMedium
        device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as! AVCaptureDeviceInput
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let preview = AVCaptureVideoPreviewLayer.layerWithSession(session) as! AVCaptureVideoPreviewLayer
        preview.frame = self.view.bounds
        self.view.layer.addSublayer(preview)
        
        output = AVCaptureVideoDataOutput()
        if session.canAddOutput(output) {
            let queue = dispatch_queue_create("MyQueue", DISPATCH_QUEUE_SERIAL);
            output.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
            session.addOutput(output)
        }
        
        
        let cacheDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).last as? NSURL
        let saveFileURL = cacheDirectoryURL?.URLByAppendingPathComponent("capture\(currentIndex).mp4")
        if NSFileManager.defaultManager().fileExistsAtPath(saveFileURL!.path!) {
            NSFileManager.defaultManager().removeItemAtURL(saveFileURL!, error: nil)
        }
        
        
        avAssetWriter = AVAssetWriter(URL: saveFileURL, fileType: AVFileTypeQuickTimeMovie, error: nil)
        avAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: [AVVideoCodecKey:AVVideoCodecH264, AVVideoWidthKey: 240, AVVideoHeightKey: 240])
        avAssetWriterInput.expectsMediaDataInRealTime = true
        avAssetWriter.addInput(avAssetWriterInput)
        avAssetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(10, 600)
        
        avAssetWriter.startWriting()
        avAssetWriter.startSessionAtSourceTime(CMTimeMakeWithSeconds(10, 600))
        session.startRunning()


    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        if avAssetWriterInput.readyForMoreMediaData {
            var appended = avAssetWriterInput.appendSampleBuffer(sampleBuffer)
            let status = avAssetWriter.status
            let error = avAssetWriter.error
            switch status {
            case .Unknown:
                println("Unknown")
                let a = 1
            case .Writing:
                println("Writing")
                let a = 1
            case .Completed:
                println("Completed")
                let a = 1
            case .Failed:
                println("Failed")
                let a = 1
            case .Cancelled:
                println("Cancelled")
                let a = 1
            default:
                let a = 1
            }
        }
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        println(__FUNCTION__)
    }

    // MARK: - timer
    
    func timer(myTimer: NSTimer) {
        println(__FUNCTION__)
        if avAssetWriter.status == .Writing {
            avAssetWriterInput.markAsFinished()
            let outputUrl = avAssetWriter.outputURL
            println("\(outputUrl)")
            avAssetWriter.finishWritingWithCompletionHandler { () -> Void in
                let documentsDirectoryUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as? NSURL
                let tsFileUrl = documentsDirectoryUrl?.URLByAppendingPathComponent("master\(self.currentIndex).ts")
                self.ffmpegWrapper.convertInputPath(outputUrl.path, outputPath: tsFileUrl?.path, options: nil, progressBlock: { (a: UInt, b: UInt64, c: UInt64) -> Void in
                        println("a: \(a), \(b), \(c)")
                    }, completionBlock: { (succeeded: Bool, b: NSError!) -> Void in
                        println("Bool: \(succeeded)\n Error: \(b)")
                        if succeeded {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                var urlString = "\(self.endpointUrlString)?filename=master\(self.currentIndex).ts"
                                let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
                                request.HTTPMethod = "PUT"
                                let tsData = NSData(contentsOfURL: tsFileUrl!)
                                request.HTTPBody = tsData
                                if nil != tsData {
                                    
                                    NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: tsData, completionHandler: { (responseData: NSData!, response: NSURLResponse!, responseError: NSError!) -> Void in
                                        if responseData != nil {
                                            let responseString = NSString(data: responseData, encoding: NSUTF8StringEncoding)
                                            if responseString != nil {
                                                println(responseString)
                                            }
                                        }
                                        if responseError != nil {
                                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                println("\(responseError.localizedDescription)")
                                            })
                                        } else {
                                            var m3u8String = "#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXT-X-VERSION:3\n#EXT-X-MEDIA-SEQUENCE:\(self.currentIndex)\n"

                                            if self.currentIndex - 2 >= 0 {
                                                m3u8String += "#EXTINT:10.0,\n"
                                                m3u8String += "master\(self.currentIndex-2).ts\n"
                                            }
                                            
                                            if self.currentIndex - 1 >= 0 {
                                                m3u8String += "#EXTINT:10.0,\n"
                                                m3u8String += "master\(self.currentIndex-1).ts\n"
                                            }
                                            
                                            m3u8String += "#EXTINT:10.0,\n"
                                            m3u8String += "master\(self.currentIndex).ts\n"


                                            var playlistUrlString = "\(self.endpointUrlString)?filename=master.m3u8"
                                            let playlistRequest = NSMutableURLRequest(URL: NSURL(string: playlistUrlString)!)
                                            playlistRequest.HTTPMethod = "PUT"
                                            let playlistData = m3u8String.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                                            playlistRequest.HTTPBody = playlistData
                                            
                                            NSURLSession.sharedSession().uploadTaskWithRequest(playlistRequest, fromData: playlistData, completionHandler: { (playlistResponseData: NSData!, playlistResponse: NSURLResponse!, playlistError: NSError!) -> Void in
                                                if responseData != nil {
                                                    let responseString = NSString(data: responseData, encoding: NSUTF8StringEncoding)
                                                    if responseString != nil {
                                                        println(responseString)
                                                    }
                                                }
                                                if responseError != nil {
                                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                        println("\(responseError.localizedDescription)")
                                                    })
                                                } else {
                                                    self.currentIndex = self.currentIndex + 1
                                                    
                                                    
                                                    let cacheDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).last as? NSURL
                                                    let saveFileURL = cacheDirectoryURL?.URLByAppendingPathComponent("capture\(self.currentIndex).mp4")
                                                    if NSFileManager.defaultManager().fileExistsAtPath(saveFileURL!.path!) {
                                                        NSFileManager.defaultManager().removeItemAtURL(saveFileURL!, error: nil)
                                                    }
                                                    
                                                    
                                                    self.avAssetWriter = AVAssetWriter(URL: saveFileURL, fileType: AVFileTypeQuickTimeMovie, error: nil)
                                                    self.avAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: [AVVideoCodecKey:AVVideoCodecH264, AVVideoWidthKey: 240, AVVideoHeightKey: 240])
                                                    self.avAssetWriterInput.expectsMediaDataInRealTime = true
                                                    self.avAssetWriter.addInput(self.avAssetWriterInput)
                                                    self.avAssetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(5, 600)
                                                    
                                                    self.avAssetWriter.startWriting()
                                                    self.avAssetWriter.startSessionAtSourceTime(CMTimeMakeWithSeconds(5, 600))
                                                    self.session.startRunning()
                                                }
                                            }).resume()
                                        }
                                    }).resume()
                                } else {
                                    println("No data")
                                }
                            })
                        }
                        
                })
                
            }
        }
    }

}

