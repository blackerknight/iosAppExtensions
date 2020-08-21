//
//  SampleHandler.swift
//  SimpleAppBroadCastUploadExtension
//
//  Created by eduardo mancilla on 19/08/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import ReplayKit
import VideoToolbox
import Photos
import os

class SampleHandler: RPBroadcastSampleHandler {
    var videoOutputFullFileName: String?
    var isRecordingVideo: Bool = false
    var videoWriterInput: AVAssetWriterInput?
    var audioWriterInput: AVAssetWriterInput?
    var videoWriter: AVAssetWriter?
    var lastSampleTime: CMTime?
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        os_log("iniciado el broad cast", type: .debug)
        os_log(.debug, "Logger", "abcdef")
        
        //        if (setupInfo != nil) {
        //            session.broadcastDescription.name = setupInfo["name"]
        //        } else {
        //            session.broadcastDescription.iOSScreenBroadcast = true
        //        }
        
//        let fileManager = FileManager.default
//        var documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//        self.videoOutputFullFileName = documentsPath + "test_capture_video.mp4"
        
        self.videoOutputFullFileName = self.getDocumentsDirectory().appendingPathComponent("test_capture_video.mp4").path
        
        if let videoOutputFullFileName = videoOutputFullFileName {
//            NSLog("el nombre de la ruta del video es: \(videoOutputFullFileName)")
            os_log("el nombre de la ruta del video es: %@", type: .debug, videoOutputFullFileName)
        } else {
            os_log("ERROR:The video output file name is nil", type: .debug)
            return
        }
        
        os_log("this is what i will see")
        
        self.isRecordingVideo = true
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.videoOutputFullFileName!) {
            NSLog("WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file")
            do {
                try fileManager.removeItem(atPath: self.videoOutputFullFileName!)
            } catch let error as NSError {
                NSLog("WARN:::Cannot delete existing file: \(self.videoOutputFullFileName!), error: \(error.debugDescription)")
            }
            
        } else {
            NSLog("DEBUG:::The file \(self.videoOutputFullFileName!) doesn't exist")
        }
        
        let screen = UIScreen.main
        let screenBounds = screen.bounds.size
        let videoCompressionPropertys = [
            AVVideoAverageBitRateKey: screenBounds.width * screenBounds.height * 10.1
        ]
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: screenBounds.width,
            AVVideoHeightKey: screenBounds.height,
            AVVideoCompressionPropertiesKey: videoCompressionPropertys
        ]
        
        self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        
        guard let videoWriterInput = self.videoWriterInput else {
            NSLog("ERROR:::No video writer input")
            return
        }
        
        videoWriterInput.expectsMediaDataInRealTime = true
        
        // Add the audio input
        var acl = AudioChannelLayout()
        memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        let audioOutputSettings: [String: Any] =
            [ AVFormatIDKey: kAudioFormatMPEG4AAC,
              AVSampleRateKey : 44100,
              AVNumberOfChannelsKey : 1,
              AVEncoderBitRateKey : 64000,
              AVChannelLayoutKey : Data(bytes: &acl, count: MemoryLayout<AudioChannelLayout>.size)]
        
        audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        
        guard let audioWriterInput = self.audioWriterInput else {
            NSLog("ERROR:::No audio writer input")
            return
        }
        
        audioWriterInput.expectsMediaDataInRealTime = true
        
        do {
            self.videoWriter = try AVAssetWriter(outputURL: URL(fileURLWithPath: self.videoOutputFullFileName!), fileType: AVFileType.mp4)
        } catch let error as NSError {
            NSLog("ERROR:::::>>>>>>>>>>>>>Cannot init videoWriter, error:\(error.localizedDescription)")
        }
        
        guard let videoWriter = self.videoWriter else {
            NSLog("ERROR:::No video writer")
            return
        }
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        } else {
            NSLog("ERROR:::Cannot add videoWriterInput into videoWriter")
        }
        
        //Add audio input
        if videoWriter.canAdd(audioWriterInput) {
            videoWriter.add(audioWriterInput)
        } else {
            NSLog("ERROR:::Cannot add audioWriterInput into videoWriter")
        }
        
        if videoWriter.status != AVAssetWriter.Status.writing {
            NSLog("DEBUG::::::::::::::::The videoWriter status is not writing, and will start writing the video.")
            
            let hasStartedWriting = videoWriter.startWriting()
            if hasStartedWriting {
                videoWriter.startSession(atSourceTime: self.lastSampleTime!)
                NSLog("DEBUG:::Have started writting on videoWriter, session at source time: \(self.lastSampleTime)")
                NSLog("\(videoWriter.status.rawValue)")
            } else {
                NSLog("WARN:::Fail to start writing on videoWriter")
            }
        } else {
            NSLog("WARN:::The videoWriter.status is writing now, so cannot start writing action on videoWriter")
        }
        
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        NSLog("pausado el broad cast")
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        NSLog("resumido el broad cast")
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        NSLog("finalizado el broad cast")
        
        processVideoFinish()
        
//        print("DEBUG::: Starting to process recorder final...")
//        print("DEBUG::: videoWriter status: \(self.videoWriter!.status.rawValue)")
//        self.isRecordingVideo = false
//
//        guard let videoWriterInput = self.videoWriterInput else {
//            print("ERROR:::No video writer input")
//            return
//        }
//        guard let videoWriter = self.videoWriter else {
//            print("ERROR:::No video writer")
//            return
//        }
//
//        guard let audioWriterInput = self.audioWriterInput else {
//            print("ERROR:::No audio writer input")
//            return
//        }
//
//        videoWriterInput.markAsFinished()
//        audioWriterInput.markAsFinished()
//        videoWriter.finishWriting {
//            if videoWriter.status == AVAssetWriter.Status.completed {
//                print("DEBUG:::The videoWriter status is completed")
//
//                let fileManager = FileManager.default
//                if fileManager.fileExists(atPath: self.videoOutputFullFileName!) {
//                    print("DEBUG:::The file: \(self.videoOutputFullFileName ?? "") has been saved in documents folder, and is ready to be moved to camera roll")
//
//
//                    let sharedFileURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.jp.awalker.co.Hotter")
//                    guard let documentsPath = sharedFileURL?.path else {
//                        print("ERROR:::No shared file URL path")
//                        return
//                    }
//                    //                    let finalFilename = documentsPath.stringByAppendingPathComponent(str: "test_capture_video.mp4")
//                    let finalFilename = documentsPath + "test_capture_video.mp4"
//
//                    //Check whether file exists
//                    if fileManager.fileExists(atPath: finalFilename) {
//                        print("WARN:::The file: \(finalFilename) exists, will delete the existing file")
//                        do {
//                            try fileManager.removeItem(atPath: finalFilename)
//                        } catch let error as NSError {
//                            print("WARN:::Cannot delete existing file: \(finalFilename), error: \(error.debugDescription)")
//                        }
//                    } else {
//                        print("DEBUG:::The file \(self.videoOutputFullFileName!) doesn't exist")
//                    }
//
//                    do {
//                        try fileManager.copyItem(at: URL(fileURLWithPath: self.videoOutputFullFileName!), to: URL(fileURLWithPath: finalFilename))
//                    }
//                    catch let error as NSError {
//                        print("ERROR:::\(error.debugDescription)")
//                    }
//
//                    PHPhotoLibrary.shared().performChanges({
//                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: finalFilename))
//                    }) { completed, error in
//                        if completed {
//                            print("Video \(self.videoOutputFullFileName ?? "") has been moved to camera roll")
//                        }
//
//                        if error != nil {
//                            print ("ERROR:::Cannot move the video \(self.videoOutputFullFileName ?? "") to camera roll, error: \(error!.localizedDescription)")
//                        }
//                    }
//
//                } else {
//                    print("ERROR:::The file: \(self.videoOutputFullFileName ?? "") doesn't exist, so can't move this file camera roll")
//                }
//            } else {
//                print("WARN:::The videoWriter status is not completed, stauts: \(videoWriter.status)")
//            }
//        }
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            captureOutput(sampleBuffer)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
    
    private func captureOutput(_ sampleBuffer: CMSampleBuffer) {
        self.lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Append the sampleBuffer into videoWriterInput
        if self.isRecordingVideo {
            if self.videoWriterInput!.isReadyForMoreMediaData {
                if self.videoWriter!.status == AVAssetWriter.Status.writing {
                    let whetherAppendSampleBuffer = self.videoWriterInput!.append(sampleBuffer)
                    NSLog(">>>>>>>>>>>>>The time::: \(self.lastSampleTime!.value)/\(self.lastSampleTime!.timescale)")
                    if whetherAppendSampleBuffer {
                        NSLog("DEBUG::: Append sample buffer successfully")
                    } else {
                        NSLog("WARN::: Append sample buffer failed")
                    }
                } else {
                    NSLog("WARN:::The videoWriter status is not writing")
                }
            } else {
                NSLog("WARN:::Cannot append sample buffer into videoWriterInput")
            }
        }
    }
    
    
    private func processVideoFinish() {
        NSLog("DEBUG::: Starting to process recorder final...")
        NSLog("DEBUG::: videoWriter status: \(self.videoWriter!.status.rawValue)")
        self.isRecordingVideo = false
        
        guard let videoWriterInput = self.videoWriterInput else {
            NSLog("ERROR:::No video writer input")
            return
        }
        guard let videoWriter = self.videoWriter else {
            NSLog("ERROR:::No video writer")
            return
        }
        
        guard let audioWriterInput = self.audioWriterInput else {
            NSLog("ERROR:::No audio writer input")
            return
        }
        
        var finishedWriting = false
        videoWriter.finishWriting {
            NSLog("DEBUG:::The videoWriter finished writing.")
            if videoWriter.status == .completed {
                NSLog("DEBUG:::The videoWriter status is completed")
                
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: self.videoOutputFullFileName!) {
                    NSLog("DEBUG:::The file: \(self.videoOutputFullFileName ?? "") has been saved in documents folder, and is ready to be moved to camera roll")
                    
                    let sharedFileURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.blacker.extension")
                    guard let documentsPath = sharedFileURL?.path else {
                        NSLog("ERROR:::No shared file URL path")
                        finishedWriting = true
                        return
                    }
                    let finalFilename = documentsPath + "/test_capture_video.mp4"

                    //Check whether file exists
                    if fileManager.fileExists(atPath: finalFilename) {
                        NSLog("WARN:::The file: \(finalFilename) exists, will delete the existing file")
                        do {
                            try fileManager.removeItem(atPath: finalFilename)
                        } catch let error as NSError {
                            NSLog("WARN:::Cannot delete existing file: \(finalFilename), error: \(error.debugDescription)")
                        }
                    } else {
                        NSLog("DEBUG:::The file \(self.videoOutputFullFileName!) doesn't exist")
                    }

                    do {
                        try fileManager.copyItem(at: URL(fileURLWithPath: self.videoOutputFullFileName!), to: URL(fileURLWithPath: finalFilename))
                    }
                    catch let error as NSError {
                        NSLog("ERROR:::\(error.debugDescription)")
                    }

                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "xxx")
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: finalFilename))
                    }) { completed, error in
                        if completed {
                            NSLog("Video \(self.videoOutputFullFileName ?? "") has been moved to camera roll")
                        }

                        if error != nil {
                            NSLog("ERROR:::Cannot move the video \(self.videoOutputFullFileName ?? "") to camera roll, error: \(error!.localizedDescription)")
                        }

                        finishedWriting = true
                    }
                    
                } else {
                    NSLog("ERROR:::The file: \(self.videoOutputFullFileName ?? "") doesn't exist, so can't move this file camera roll")
                    finishedWriting = true
                }
            } else {
                NSLog("WARN:::The videoWriter status is not completed, status: \(videoWriter.status)")
                finishedWriting = true
            }
        }
        
        while finishedWriting == false {
            NSLog("DEBUG:::Waiting to finish writing...")
        }
    }
}
