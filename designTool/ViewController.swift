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
    @IBOutlet weak var zipFilePath: NSTextField!
    @IBOutlet weak var timeInterval: NSTextField!
    @IBOutlet weak var maskupTriggerType: NSTextField!
    @IBOutlet weak var maskupDiverse: NSButton!
    @IBOutlet weak var zOrder: NSTextField!
    @IBOutlet weak var input: NSTextField!
    @IBOutlet weak var type: NSComboBox!
    @IBOutlet weak var addItemButton: NSButton!
    @IBOutlet weak var timeInterval2d: NSTextField!
    @IBOutlet weak var TriggerType2d: NSTextField!
    
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
    var itemSet:[itemInfo] = [];
    
    struct itemInfo {
        var path:String = ""
        var input:String = ""
        var type:String = ""
        var zOrder:Int = 0
        func itemInfo(){
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.debugInfoLabel.documentView?.insertText("")
        
        zOrder.integerValue = Int(arc4random_uniform(1000))
        // Do any additional setup after loading the view.
    }

    @IBAction func addItem(_ sender: Any) {
        if !zipFilePath.stringValue.isEmpty{
            var info = itemInfo()
            info.path = zipFilePath.stringValue
            info.input = input.stringValue
            info.type = type.stringValue
            info.zOrder = zOrder.integerValue
            
            itemSet.insert(info, at: 0)
            
            //clear
            zipFilePath.stringValue = ""
            input.stringValue = ""
            type.selectItem(at: 0)
            zOrder.integerValue = zOrder.integerValue + 1
            
            debugInfoLabel.documentView?.insertText("插入一条记录type:\(info.type),zorder:\(info.zOrder)\n")
        }
    }
    // MARK: -  UI
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
                zipFilePath.stringValue = path
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
        
        //插入item
        if itemSet.count == 0 {
            var info = itemInfo()
            info.path = zipFilePath.stringValue
            info.input = input.stringValue
            info.type = type.stringValue
            info.zOrder = zOrder.integerValue
            
            itemSet.insert(info, at: 0)
        }
        
        //插入所有的item
        for item in itemSet {
            if(item.type == "2DSticker"){
                //创建贴纸目录
                let dirName:String = "2Dsticker".appendingFormat("%d", item.zOrder)
                createDirectory(path: homePath.appendingFormat("/%@",dirName))
                //解压文件
                unzipFile(sourceURL: URL(fileURLWithPath: item.path), destURL: URL(fileURLWithPath:homePath.appendingFormat("/%@",dirName)))
                //添加资源到sticker2d.json
                addresTo2dStickerJson(dirName: dirName)
                //加入配置文件
                addConfigItem(Path:dirName,type: item.type,zorder: item.zOrder,input: item.input)
            }else if(item.type == "maskup"){
                //解压文件
                unzipFile(sourceURL: URL(fileURLWithPath: item.path), destURL: URL(fileURLWithPath: homePath))
                //创建+添加资源到Maskup.Json
                addresToMaskupJson(path: item.path);
                //添加到config.json
                let Path = URL(fileURLWithPath: URL(fileURLWithPath:item.path).lastPathComponent).deletingPathExtension().relativePath
                addConfigItem(Path:Path,type: item.type,zorder: item.zOrder,input: item.input)
            }else if(item.type == "filter" || item.type == "sequence"){
                //解压zip包
                unzipFile(sourceURL: URL(fileURLWithPath:item.path), destURL: URL(fileURLWithPath: homePath))
                //添加到config.json
                let Path = URL(fileURLWithPath: URL(fileURLWithPath:item.path).lastPathComponent).deletingPathExtension().relativePath
                addConfigItem(Path:Path,type: item.type,zorder: item.zOrder,input: item.input)
            }
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
    
    func createmaskUpJson(){
        do {
            maskupJson["resource"] = [];
            let fileManager = FileManager.default
            try fileManager.createFile(atPath: maskupWorkPath.appendingFormat("/maskup.json"), contents: maskupJson.rawData(), attributes: nil)
        } catch  {
            debugInfoLabel.documentView?.insertText("创建maskupJson文件失败,error:\(error)")
        }
    }
    
    func addresTo2dStickerJson(dirName:String) -> Void {
        do {
            //找到路径
            sticker2dWorkPath = homePath.appendingFormat("/%@",dirName)
            //添加触发类型
            let timeval:Int = timeInterval2d.integerValue
            let trigval:Int = TriggerType2d.integerValue
            if timeval != 0 || trigval != 0{
                var trigger:JSON = JSON()
                trigger["imageInterval"] = JSON(integerLiteral: timeInterval2d.integerValue)
                trigger["triggerType"] = JSON(integerLiteral: TriggerType2d.integerValue)
                stickerJson["trigger"] = trigger
            }
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
            }
            try fileManager.createFile(atPath: sticker2dWorkPath.appendingFormat("/sticker.json"), contents: stickerJson.rawData(), attributes: nil)
        } catch  {
            debugInfoLabel.documentView?.insertText("插入sticker2d文件失败,error:\(error)")
        }
    }
    
    func addresToMaskupJson(path:String){
        do {
            //找到美妆的路径名
            let name:String = URL(fileURLWithPath: URL(fileURLWithPath:path).lastPathComponent).deletingPathExtension().relativePath
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
    
//    func addConfigItem(Path:String,type:String,zorder:Int){
//        do{
//            //写入config.Json
//            var oneLink:JSON = JSON()
//            oneLink["type"] = JSON(stringLiteral: type)
//            oneLink["path"] = JSON(stringLiteral: Path)
//            oneLink["zorder"] = JSON(integerLiteral: zorder)
//            let links:JSON = [oneLink]
//            try configJson["effect"]["Link"].merge(with: links)
//            try configJson.rawData().write(to: URL(fileURLWithPath: homePath.appendingFormat("/%@", configJsonName)))
//        }catch{
//            debugInfoLabel.documentView?.insertText("添加配置文件失败 error:\(error)")
//        }
//    }
    
    func addConfigItem(Path:String,type:String,zorder:Int,input:String) -> Void {
        do {
            var oneLink:JSON = JSON()
            oneLink["type"] = JSON(stringLiteral: type)
            oneLink["path"] = JSON(stringLiteral: Path)
            oneLink["zorder"] = JSON(integerLiteral: zorder)
            if !input.isEmpty {
                let StringArray = input.components(separatedBy:",")
                var array:[Int] = [];
                for sItem in StringArray {
                    let item:Int = Int(sItem)!
                    array.insert(item, at: 0)
                }
                oneLink["input"] = JSON(array)
            }
            let links:JSON = [oneLink]
            try configJson["effect"]["Link"].merge(with: links)
            try configJson.rawData().write(to: URL(fileURLWithPath: homePath.appendingFormat("/%@", configJsonName)))
        } catch  {
            debugInfoLabel.documentView?.insertText("添加带input的配置文件失败 error:\(error)")
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

