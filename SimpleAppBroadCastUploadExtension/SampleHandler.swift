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
import BBPortal

class SampleHandler: RPBroadcastSampleHandler {
    private var videoOutputFullFileName: String?
    private var isRecordingVideo: Bool = false
    private var videoWriterInput: AVAssetWriterInput?
    private var videoWriter: AVAssetWriter?
    private var lastSampleTime: CMTime?
    private var portal: BBPortalProtocol!
    private let fileUtil = UtilFile()
    
    override func broadcastAnnotated(withApplicationInfo applicationInfo: [AnyHashable: Any]) {
        NSLog("broadcastAnnotated: \(applicationInfo)")
    }
    
    private func validatefiles() {
        let groupDefaults = UserDefaults(suiteName: Shared.Constantes.groupName)
        guard let videoName = groupDefaults?.value(forKey: Shared.Constantes.Key.videoName) as? String else {
            NSLog("no existe la clave video_name")
            return
        }
        
        guard let urlFolder = fileUtil.getSharedFolder(namefile: Shared.Constantes.Names.folderShared) else { return }
        let fileUrl = urlFolder.appendingPathComponent(videoName)
        self.videoOutputFullFileName = fileUrl.path
        
        if fileUtil.fileExists(atPath: self.videoOutputFullFileName!) {
            fileUtil.removeItem(atPath: self.videoOutputFullFileName!)
        } else {
            fileUtil.createDirectory(atPath: urlFolder.path)
        }
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        portal = BBPortal(withGroupIdentifier: Shared.Constantes.groupName, andPortalID: "id.for.this.portal")
        portal.send(data: ["key": "What ever data you want"]) {
            (error) in

            if let anError = error {
                NSLog("Send failed with error: ", anError)
            }
        }
        
        validatefiles()
        self.isRecordingVideo = true
        DispatchQueue.main.async {
            let screenBounds = UIScreen.main.bounds.size
            let videoCompressionPropertys = [ AVVideoAverageBitRateKey: screenBounds.width * screenBounds.height * 10.1 ]
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: screenBounds.width,
                AVVideoHeightKey: screenBounds.height,
                AVVideoCompressionPropertiesKey: videoCompressionPropertys
            ]
            
            self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            
            guard let videoWriterInput = self.videoWriterInput else { return }
            videoWriterInput.expectsMediaDataInRealTime = true
            do {
                self.videoWriter = try AVAssetWriter(outputURL: URL(fileURLWithPath: self.videoOutputFullFileName!), fileType: AVFileType.mp4)
            } catch let error as NSError {
                NSLog("ERROR:::::>>>>>>>>>>>>>Cannot init videoWriter, error:\(error.localizedDescription)")
            }
            guard let videoWriter = self.videoWriter else { return }
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
            } else {
                NSLog("ERROR:::Cannot add videoWriterInput into videoWriter")
            }
            
            if videoWriter.status != AVAssetWriter.Status.writing {
                let hasStartedWriting = videoWriter.startWriting()
                if !hasStartedWriting {
                    NSLog("WARN:::Fail to start writing on videoWriter")
                }
            } else {
                NSLog("WARN:::The videoWriter.status is writing now, so cannot start writing action on videoWriter")
            }
        }
    }
    
    override func broadcastPaused() {
        
    }
    
    override func broadcastResumed() {
        
    }
    
    override func broadcastFinished() {
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
    
    private func canWrite() -> Bool {
        return isRecordingVideo && videoWriter != nil && videoWriter?.status == .writing
    }
    
    private func captureOutput(_ sampleBuffer: CMSampleBuffer) {
        guard let videoWriter = self.videoWriter else {
            os_log("ERROR:::No video writer")
            return
        }
        
        if canWrite(), self.lastSampleTime == nil {
            self.lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: self.lastSampleTime!)
        }
        
        self.lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if self.isRecordingVideo {
            if self.videoWriterInput!.isReadyForMoreMediaData {
                if videoWriter.status == AVAssetWriter.Status.writing {
                    let whetherAppendSampleBuffer = self.videoWriterInput!.append(sampleBuffer)
                    if whetherAppendSampleBuffer {
//                        os_log("DEBUG::: Append sample buffer successfully")
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
    
    private func processVideoFinish() {
        self.isRecordingVideo = false
        guard let videoWriter = self.videoWriter else {
            os_log("ERROR:::No video writer")
            return
        }
        
        videoWriter.finishWriting { }
        repeat {
            NSLog("DEBUG:::Waiting to finish writing...")
            usleep(useconds_t(100 * 1000))
        } while(videoWriter.status == .writing)
        
        NSLog("DEBUG::: completed")
    }
}
