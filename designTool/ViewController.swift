//
//  ViewController.swift
//  CameraEeffectDesignTool
//
//  Created by yulin9 on 2018/10/29.
//  Copyright © 2018年 yulin9. All rights reserved.
//

import Cocoa
import Zip
import SwiftyJSON

class ViewController: NSViewController {

    @IBOutlet weak var packageName: NSTextField!
    @IBOutlet weak var cSenseArZipFilePath: NSTextField!
    @IBOutlet weak var maskUpZipFilePath: NSTextField!
    @IBOutlet weak var filterZipFilePath: NSTextFieldCell!
    @IBOutlet weak var timeInterval: NSTextField!
    @IBOutlet weak var maskupTriggerType: NSTextField!
    @IBOutlet weak var maskupDiverse: NSButton!
    
    @IBOutlet weak var debugInfoLabel: NSScrollView!
    var zipFileName:String = "";
    var homeFolder:String = "/Users/Shared";
    var homePath:String = "";
    var configJsonName:String = "config.json";
    var configJson:JSON = JSON();
    var stickerJson:JSON = JSON();
    var maskupJson:JSON = JSON();
    var maskupWorkPath:String = "";
    var sticker2dWorkPath:String = "";
    override func viewDidLoad() {
        super.viewDidLoad()

        self.debugInfoLabel.documentView?.insertText("")
        // Do any additional setup after loading the view.
    }

    // MARK: -  UI
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func browsemaskUpFile(sender: AnyObject) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .zip file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["zip"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                maskUpZipFilePath.stringValue = path
            }
        } else {
            // User clicked on "Cancel"
            return
        }
        
    }
    @IBAction func chooseSenseArZipFile(_ sender: Any) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .zip file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["zip"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                cSenseArZipFilePath.stringValue = path
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func chooseFilter(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .zip file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["zip"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                filterZipFilePath.stringValue = path
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func generate(_ sender: Any) {
        //判断home路径
        if !packageName.stringValue.isEmpty{
            homePath = homeFolder.appendingFormat("/%@", packageName.stringValue)
        }else {
            homePath = homeFolder.appendingFormat("/generate")
        }
        
        //创建根目录和config.json文件
        createDirectory(path: homePath)
        createConfigJson()
        //添加商汤zip包
        if !cSenseArZipFilePath.stringValue.isEmpty{
            //创建贴纸目录
            createDirectory(path: homePath.appendingFormat("/2Dsticker"))
            //解压文件
            unzipFile(sourceURL: URL(fileURLWithPath: cSenseArZipFilePath.stringValue), destURL: URL(fileURLWithPath: homePath))
            //添加资源到sticker2d.json
            addresTo2dStickerJson()
            //添加到config.json
            let senseARZOrder:Int = Int(arc4random_uniform(1000))+1001
            addConfigItem(Path:"2Dsticker",type: "2DSticker",zorder: senseARZOrder)
        }
        //添加滤镜zip包
        if !filterZipFilePath.stringValue.isEmpty{
            //解压zip包
            unzipFile(sourceURL: URL(fileURLWithPath: filterZipFilePath.stringValue), destURL: URL(fileURLWithPath: homePath))
            //添加到config.json
            let Path = URL(fileURLWithPath: URL(fileURLWithPath:filterZipFilePath.stringValue).lastPathComponent).deletingPathExtension().relativePath
            let filterZorder:Int = Int(arc4random_uniform(1000))+1
            addConfigItem(Path:Path,type: "filter",zorder: filterZorder)
        }
        //添加美妆包含多张图片的zip包
        if !maskUpZipFilePath.stringValue.isEmpty {
            //解压文件
            unzipFile(sourceURL: URL(fileURLWithPath: maskUpZipFilePath.stringValue), destURL: URL(fileURLWithPath: homePath))
            //创建+添加资源到Maskup.Json
            addresToMaskupJson();
            //添加到config.json
            let Path = URL(fileURLWithPath: URL(fileURLWithPath:maskUpZipFilePath.stringValue).lastPathComponent).deletingPathExtension().relativePath
            let filterZorder:Int = Int(arc4random_uniform(1000))+2000
            addConfigItem(Path:Path,type: "maskup",zorder: filterZorder)
        }
     
        //打包文件
        zipFile()
    }
    //MARK: - utility
    func createDirectory(path:String){
        let fileManager = FileManager.default
        do{
            var isDirectory: ObjCBool = true
            if(fileManager.fileExists(atPath:path, isDirectory:&isDirectory)){
                try fileManager.removeItem(at: URL(fileURLWithPath: path))
            }
            try fileManager.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: false, attributes: nil)
        }catch{
            debugInfoLabel.documentView?.insertText("创建根目录失败,error:\(error)")
        }
    }
    
    func createConfigJson(){
        do {
            configJson["name"]="effectTeamData"
            configJson["version"]="1.0"
            var effectValue:JSON = JSON();
            effectValue["Link"] = [];
            configJson["effect"]=effectValue
            let fileManager = FileManager.default
            try fileManager.createFile(atPath: homePath.appendingFormat("/%@", configJsonName), contents: configJson.rawData(), attributes: nil)
        } catch  {
            debugInfoLabel.documentView?.insertText("创建配置文件失败,error:\(error)")
        }
    }
    
    func create2dStickerJson(){
        do {
            stickerJson["resource"] = [];
            let fileManager = FileManager.default
            try fileManager.createFile(atPath: homePath.appendingFormat("/2Dsticker/sticker.json"), contents: stickerJson.rawData(), attributes: nil)
        } catch  {
            debugInfoLabel.documentView?.insertText("创建sticker2d文件失败,error:\(error)")
        }
    }
    
    func createmaskUpJson(){
        do {
            maskupJson["resource"] = [];
            let fileManager = FileManager.default
            try fileManager.createFile(atPath: maskupWorkPath.appendingFormat("/maskup.json"), contents: maskupJson.rawData(), attributes: nil)
        } catch  {
            debugInfoLabel.documentView?.insertText("创建maskupJson文件失败,error:\(error)")
        }
    }
    
    func addresTo2dStickerJson() -> Void {
        do {
            //找到路径
            let name:String = URL(fileURLWithPath: URL(fileURLWithPath:cSenseArZipFilePath.stringValue).lastPathComponent).deletingPathExtension().relativePath
            sticker2dWorkPath = homePath.appendingFormat("/%@",name)
            //添加资源
            stickerJson["resource"] = [];
            let fileManager = FileManager.default
            let subPaths:[String] = try fileManager.contentsOfDirectory(atPath: sticker2dWorkPath)
            for subPath in subPaths {
                if subPath == ".DS_Store" {continue;}
                var oneRes:JSON = JSON()
                oneRes["folderName"] = JSON(stringLiteral: subPath)
                let fullNames:[String] = try fileManager.contentsOfDirectory(atPath: sticker2dWorkPath.appendingFormat("/%@",subPath))
                for fullName:String in fullNames{
                    if fullName.hasSuffix("json") {
                        let name = URL(fileURLWithPath:fullName).deletingPathExtension().relativePath
                        oneRes["name"] = JSON(stringLiteral: name)
                        break;
                    }
                }
                let oneRess:JSON = [oneRes]
                try stickerJson["resource"].merge(with: oneRess)
                
                try fileManager.createFile(atPath: sticker2dWorkPath.appendingFormat("/sticker.json"), contents: stickerJson.rawData(), attributes: nil)
            }
        } catch  {
            debugInfoLabel.documentView?.insertText("插入sticker2d文件失败,error:\(error)")
        }
    }
    
    func addresToMaskupJson(){
        do {
            //找到美妆的路径名
            let name:String = URL(fileURLWithPath: URL(fileURLWithPath:maskUpZipFilePath.stringValue).lastPathComponent).deletingPathExtension().relativePath
            maskupWorkPath = homePath.appendingFormat("/%@",name)
            //添加资源
            maskupJson["resource"] = [];
            let fileManager = FileManager.default
            let subPaths:[String] = try fileManager.contentsOfDirectory(atPath: maskupWorkPath)
            for subPath in subPaths {
                if subPath == ".DS_Store" {continue;}
                var oneRes:JSON = JSON()
                oneRes["folderName"] = JSON(stringLiteral: subPath)
                let fullName:[String] = try fileManager.contentsOfDirectory(atPath: maskupWorkPath.appendingFormat("/%@",subPath))
                var index = 0;
                if fullName[index] == ".DS_Store" {index = index+1;}
                let name = URL(fileURLWithPath:fullName[index]).deletingPathExtension().relativePath
                oneRes["name"] = JSON(stringLiteral: name)
                let oneRess:JSON = [oneRes]
                try maskupJson["resource"].merge(with: oneRess)
            }
            //添加触发类型
            let timeval:Int = timeInterval.integerValue
            let trigval:Int = maskupTriggerType.integerValue
            if timeval != 0 || trigval != 0{
                var trigger:JSON = JSON()
                trigger["imageInterval"] = JSON(integerLiteral: timeInterval.integerValue)
                trigger["triggerType"] = JSON(integerLiteral: maskupTriggerType.integerValue)
                maskupJson["trigger"] = trigger
            }
           
            //添加多人头显示不同人脸
            if maskupDiverse.state.rawValue == 1 {
                maskupJson["diverse"] = true
            }
            
            try fileManager.createFile(atPath: maskupWorkPath.appendingFormat("/maskup.json"), contents: maskupJson.rawData(), attributes: nil)
        } catch  {
            debugInfoLabel.documentView?.insertText("插入maskupJson失败,error:\(error)")
        }
        
    }
    
    func addConfigItem(Path:String,type:String,zorder:Int){
        do{
            //写入config.Json
            var oneLink:JSON = JSON()
            oneLink["type"] = JSON(stringLiteral: type)
            oneLink["path"] = JSON(stringLiteral: Path)
            oneLink["zorder"] = JSON(integerLiteral: zorder)
            let links:JSON = [oneLink]
            try configJson["effect"]["Link"].merge(with: links)
            try configJson.rawData().write(to: URL(fileURLWithPath: homePath.appendingFormat("/%@", configJsonName)))
        }catch{
            debugInfoLabel.documentView?.insertText("添加配置文件失败 error:\(error)")
        }
    }
    
    func unzipFile(sourceURL:URL,destURL:URL) -> Void {
        do {
            try Zip.unzipFile(sourceURL,destination:destURL,overwrite: true, password: nil)
            try FileManager.default.removeItem(atPath: destURL.path.appendingFormat("/__MACOSX"))
        } catch  {
            debugInfoLabel.documentView?.insertText("解压文件失败 error:\(error)")
        }
    }
    
    func zipFile(){
        let srcFileName = URL(fileURLWithPath: homePath).lastPathComponent
        let dstPath = URL(fileURLWithPath: homePath).deletingLastPathComponent().path.appendingFormat("/%@.zip",srcFileName)
        do{
            //删除以前的zip文件
            let fileManager = FileManager()
            var isDirectory: ObjCBool = false
            if(fileManager.fileExists(atPath: dstPath, isDirectory:&isDirectory)){
                try fileManager.removeItem(at:URL(fileURLWithPath: dstPath))
            }
            //打包出最新的zip文件
            try Zip.zipFiles(paths: [URL(fileURLWithPath: homePath)], zipFilePath: URL(fileURLWithPath: dstPath), password: nil, progress: nil)
            debugInfoLabel.documentView?.insertText(String.init(format: "压缩成功，下载路径：%@\n", dstPath))
        }catch {
             debugInfoLabel.documentView?.insertText("压缩失败\n")
        }
    }
}

