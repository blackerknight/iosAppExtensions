//
//  SampleHandler.swift
//  SimpleAppBroadCastUploadExtension
//
//  Created by eduardo mancilla on 19/08/20.
//  Copyright © 2020 eduardo mancilla. All rights reserved.
//

import os
import Photos
import ReplayKit
import VideoToolbox

class SampleHandler: RPBroadcastSampleHandler {
    var videoOutputFullFileName: String?
    var isRecordingVideo: Bool = false
    var videoWriterInput: AVAssetWriterInput?
//    var audioWriterInput: AVAssetWriterInput?
    var videoWriter: AVAssetWriter?
    var lastSampleTime: CMTime?
    let fileManager = FileManager.default
    
    private func getSharedFolder(namefile: String) -> URL? {
        let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.blacker.extension")?
            .appendingPathComponent(namefile)
        return url
    }
    
    override func broadcastAnnotated(withApplicationInfo applicationInfo: [AnyHashable: Any]) {
        NSLog("broadcastAnnotated: \(applicationInfo)")
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        let groupDefaults = UserDefaults(suiteName: "group.com.blacker.extension")
        guard let videoName = groupDefaults?.value(forKey: "video_name") as? String else {
            NSLog("no existe la clave video_name")
            return
        }
        
        guard let urlFolder = getSharedFolder(namefile: "Records") else { return }
        let fileUrl = urlFolder.appendingPathComponent("\(videoName).mp4")
        self.videoOutputFullFileName = fileUrl.path
        
        if let videoOutputFullFileName = videoOutputFullFileName {
            os_log("el nombre de la ruta del video es: %@", videoOutputFullFileName)
        } else {
            os_log("ERROR:The video output file name is nil")
            return
        }
        
        self.isRecordingVideo = true
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.videoOutputFullFileName!) {
            os_log("WARN:::The file: %@ exists, will delete the existing file", self.videoOutputFullFileName!)
            do {
                try fileManager.removeItem(atPath: self.videoOutputFullFileName!)
            } catch let error as NSError {
                os_log("WARN:::Cannot delete existing file: %@, error: %@", self.videoOutputFullFileName!, error.debugDescription)
            }
        } else {
            os_log("DEBUG:::The file %@ doesn't exist", self.videoOutputFullFileName!)
            NSLog("Se va atratar de crear los folders")
            do {
                try FileManager.default.createDirectory(atPath: urlFolder.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                os_log("WARN:::Cannot create file: %@, error: %@", urlFolder.path, error.debugDescription)
            }
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
        
        do {
            self.videoWriter = try AVAssetWriter(outputURL: URL(fileURLWithPath: self.videoOutputFullFileName!), fileType: AVFileType.mp4)
            NSLog("DEBUG:::::>>>>>>>>>>>>>Init videoWriter")
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
        
        if videoWriter.status != AVAssetWriter.Status.writing {
            NSLog("DEBUG::::::::::::::::The videoWriter status is not writing, and will start writing the video.")
            
            let hasStartedWriting = videoWriter.startWriting()
            if !hasStartedWriting {
                NSLog("WARN:::Fail to start writing on videoWriter")
            }
        } else {
            NSLog("WARN:::The videoWriter.status is writing now, so cannot start writing action on videoWriter")
        }
    }
    
    override func broadcastPaused() {
        os_log("pausado el broad cast")
    }
    
    override func broadcastResumed() {
        os_log("resumido el broad cast")
    }
    
    override func broadcastFinished() {
        os_log("finalizado el broad cast")
        self.processVideoFinish()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video: captureOutput(sampleBuffer)
        case RPSampleBufferType.audioApp: break
        case RPSampleBufferType.audioMic: break
        @unknown default: fatalError("Unknown type of sample buffer")
        }
    }
    
    func canWrite() -> Bool {
        return isRecordingVideo && videoWriter != nil && videoWriter?.status == .writing
    }
    
    private func captureOutput(_ sampleBuffer: CMSampleBuffer) {
        guard let videoWriter = self.videoWriter else {
            os_log("ERROR:::No video writer")
            return
        }
        
        let writable = canWrite()
        if writable, self.lastSampleTime == nil {
            self.lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: self.lastSampleTime!)
        }
        
        self.lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if self.isRecordingVideo {
            if self.videoWriterInput!.isReadyForMoreMediaData {
                if videoWriter.status == AVAssetWriter.Status.writing {
                    let whetherAppendSampleBuffer = self.videoWriterInput!.append(sampleBuffer)
                    if whetherAppendSampleBuffer {
                        os_log("DEBUG::: Append sample buffer successfully")
                    } else {
                        os_log("WARN::: Append sample buffer failed")
                    }
                } else {
                    os_log("WARN:::The videoWriter status is not writing")
                }
            } else {
                os_log("WARN:::Cannot append sample buffer into videoWriterInput")
            }
        }
    }
    
    private func cancelVideoFinish() {
        guard let videoWriter = self.videoWriter else {
            NSLog("ERROR:::No video writer")
            return
        }
        videoWriter.cancelWriting()
        NSLog("DEBUG::: Cancelado video save...")
    }
    
    private func processVideoFinish() {
        self.isRecordingVideo = false
        guard let videoWriter = self.videoWriter else {
            os_log("ERROR:::No video writer")
            return
        }
        
        videoWriter.finishWriting {
            
        }
        
        repeat {
            NSLog("DEBUG:::Waiting to finish writing...")
            usleep(useconds_t(100 * 1000))
        } while(videoWriter.status == .writing)
        
        NSLog("DEBUG::: completed")
        // Check whether file exists
        if fileManager.fileExists(atPath: self.videoOutputFullFileName!) {
            NSLog("DEBUG:::The file: \(self.videoOutputFullFileName!) exists.")
        } else {
            NSLog("DEBUG:::The file \(self.videoOutputFullFileName!) doesn't exist")
        }
    }
}
