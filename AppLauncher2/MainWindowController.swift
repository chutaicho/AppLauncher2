//
//  AppLauncher2
//
//  Created by Takashi
//  http://takashiaoki.com
//
//  Copyright (c) 2015 Takashi Aoki. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate
{
    @IBOutlet weak var arrayController: NSArrayController!
    var _paramViewController: ParamViewController =  ParamViewController()
    
    @IBOutlet weak var _tableView: NSTableView!
    @IBOutlet weak var _indicator: NSProgressIndicator!
    @IBOutlet weak var _delayInfo: NSTextField!

    // MARK: - consts
    let NIB_NAME     = "MainWindowController"
    let UDKEY_PARAMS = "SavedParams"
    let DRAGGED_TYPE = "TableViewDraggedType"
    let REBOOT_DELAY = 1.0
    
    // MARK: - vars
    var _params  : LaunchParams = LaunchParams()
    var _keepRun : Bool         = true;
    var _timer   : NSTimer      = NSTimer()
    var _cDown   : Int          = 0
    
    override var windowNibName: String? { return NIB_NAME }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()

        _tableView.registerForDraggedTypes([NSFilenamesPboardType, DRAGGED_TYPE])
        
        let userD = NSUserDefaults.standardUserDefaults()
        
        //MARK: DEBUG
        //deleteUserDefault()
        
        if let data = userD.objectForKey(UDKEY_PARAMS) as? NSData
        {
            let params = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! LaunchParams
            
            _params.copy(aTarget: params)
            _paramViewController.setParams(_params)
            
            var i = 0
            for entry:AppEntry in params.apps
            {
                // set the application's icon
                entry.fetchIconData()
                self.arrayController.addObject(entry)
                self.rearrangeObject()
                
                NSTimer.scheduledTimerWithTimeInterval(Double(_params.delay) + 1.0 * Double(i), target: self, selector: Selector("launchApp:"), userInfo: ["aPath": entry.path], repeats: false)
                
                i++
            }
            
            cout("params decoded.")
            cout("params apps: " + String(_params.apps.count))
        }
        else
        {
            cout("params undefined.")
        }
        
        let nc = NSWorkspace.sharedWorkspace().notificationCenter
        nc.addObserver(self, selector: "onLaunchNotification:", name: NSWorkspaceDidLaunchApplicationNotification,    object: nil)
        nc.addObserver(self, selector: "onQuitNotification:",   name: NSWorkspaceDidTerminateApplicationNotification, object: nil)
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("timerUpdate"), userInfo: nil, repeats: true)
        
        // MARK: Delay Info
        _cDown = (_params.delay - 1)
        
        if _cDown > 0
        {
            _indicator.startAnimation(self)
            _delayInfo.stringValue = "Start in " + String(_cDown) + " seconds."
        }
        else
        {
            _indicator.hidden = true
            _delayInfo.hidden = true
            _cDown = -1
        }
    }

    // MARK: - IBAction
    @IBAction func quitApplication(sender: NSButton)
    {
        exit()
    }
    @IBAction func paramButtonHandler(sender: NSButton)
    {
        cout("paramButtonHandler")
        self.window!.beginSheet(_paramViewController.window!, completionHandler:{ response in
                
            if response == NSModalResponseOK
            {
                //MARK: save params here!
                let params = self._paramViewController.getParams()
                self._params.copy(aTarget: params)
                self.save()
            }
        })
    }
    @IBAction func addApplication(sender: NSButton)
    {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.directoryURL = NSURL(string: "/Applications")
        
        openPanel.beginWithCompletionHandler
        { (result) -> Void in
            
            if result == NSFileHandlingPanelOKButton
            {
                //Do what you will
                //If there's only one URL, surely 'openPanel.URL'
                //but otherwise a for loop works
                
                let path = openPanel.URL?.path
                let name = openPanel.URL?.URLByDeletingPathExtension?.lastPathComponent
                let extention = openPanel.URL?.pathExtension
                
                if extention != "app"
                {
                    let alert = NSAlert()
                    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                    alert.messageText = "Uh!"
                    alert.informativeText = "Sorry! You can only set an application file."
                    alert.beginSheetModalForWindow(self.window!, completionHandler: nil)
                }
                else
                {
                    let appname = name
                    
                    if !self.isOurApp(aPath: path!, aName: appname!)
                    {
                        let entry: AppEntry = AppEntry()
                        entry.set(aPath: path!, aName: appname!, aHide: false)
                        entry.fetchIconData()
                        
                        self.arrayController.addObject(entry)
                        self.rearrangeObject()
                    }
                }
            }
        }
    }
    @IBAction func removeApplication(sender:NSButton)
    {
        self.arrayController.removeObjectAtArrangedObjectIndex(self.arrayController.selectionIndex)
        self.rearrangeObject()
    }
    
    // MARK: - Event handlers
    func onLaunchNotification(notification: NSNotification?)
    {
        if let info = notification!.userInfo
        {
            let name: String = info["NSApplicationName"] as! String
            let path: String = info["NSApplicationPath"] as! String
            cout("launched: " + path + ", " + name)
            
            var target:AppEntry!
            for entry:AppEntry in _params.apps
            {
                if entry.path == path
                {
                    target = entry
                    break
                }
            }
            
            if target != nil && target.hide
            {
                let ws = NSWorkspace.sharedWorkspace()
                let apps = ws.runningApplications
                
                for app in apps as [NSRunningApplication]
                {
                    if app.localizedName == target.name
                    {
                        app.hide()
                        break
                    }
                }
            }
        }
    }
    func onQuitNotification(notification: NSNotification?)
    {
        if let info = notification!.userInfo
        {
            let path: String = info["NSApplicationPath"] as! String
            
            if isOurApp(aPath: path) && _params.keepRun
            {
                NSTimer.scheduledTimerWithTimeInterval(REBOOT_DELAY, target: self, selector: Selector("launchApp:"), userInfo: ["aPath": path], repeats: false)
            }
        }
    }
    func launchApp(t: NSTimer)
    {
        let userInfo = t.userInfo as! Dictionary<String, AnyObject>
        let path: String = userInfo["aPath"] as! String
        NSWorkspace.sharedWorkspace().launchApplication(path)
    }
    
    //MARK: - public
    func timerUpdate()
    {
        if _cDown > 0
        {
            _delayInfo.stringValue = "Start in " + String(_cDown) + " seconds."
            _cDown--
        }
        else if _cDown == 0
        {
            _indicator.stopAnimation(self)
            _indicator.hidden = true
            _delayInfo.hidden = true
            _cDown = -1
        }
        
        let now = getTimeFromDate(NSDate())
        
        cout("now: " + String(now.hour) + ":" + String(now.minute))
        cout("set: " + String(_params.quitHour) + ":" + String(_params.quitMinute))
        
        if now.hour == _params.quitHour && now.minute == _params.quitMinute && _params.timerEnabled { exit() }
    }
    func exit()
    {
        let ws = NSWorkspace.sharedWorkspace()
        let apps = ws.runningApplications
        
        for app in apps as [NSRunningApplication]
        {
            for entry: AppEntry in _params.apps
            {
                if entry.name == app.localizedName
                {
                    app.terminate()
                    break
                }
            }
        }
        
        NSThread.sleepForTimeInterval(0.25) // sleep a bit before quitting.
        NSApp.terminate(self)
    }
    func save()
    {
        let ud = NSUserDefaults.standardUserDefaults()
        ud.setValue(NSKeyedArchiver.archivedDataWithRootObject(_params), forKey: UDKEY_PARAMS)
        cout("----------> saved.")
    }
    
    //MARK: - private
    private func rearrangeObject()
    {
        self.arrayController.rearrangeObjects()
        save()
    }
    private func isOurApp(aPath path: String, aName name: String = "") -> Bool
    {
        var res = false
        
        for entry:AppEntry in _params.apps
        {
            if entry.path == path || entry.name == name
            {
                res = true
                cout(path + " is our app.")
                break
            }
        }
        
        return res
    }
    
    //MARK: TableView Drag & Drop stuff
    //Reference: http://juliuspaintings.co.uk/cgi-bin/paint_css/animatedPaint/074-NSTableView-drag-drop.pl
    
    func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool
    {
        let data = NSKeyedArchiver.archivedDataWithRootObject(rowIndexes)
        pboard.declareTypes([DRAGGED_TYPE], owner: self)
        pboard.setData(data, forType: DRAGGED_TYPE)
        return true
    }
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation
    {
        return NSDragOperation.Every
    }
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool
    {
        let pboard = info.draggingPasteboard()
        let types  = pboard.types
        
        if (types?.contains(DRAGGED_TYPE) != nil)
        {
            let rowData     = pboard.dataForType(DRAGGED_TYPE)
            let rowIndexes  = NSKeyedUnarchiver.unarchiveObjectWithData(rowData!)
            let dragRow     = rowIndexes?.firstIndex
            let targetEntry = _params.apps[dragRow!]

            if dragRow < row
            {
                self.arrayController.removeObjectAtArrangedObjectIndex(dragRow!)
                self.arrayController.addObject(targetEntry)
                self.rearrangeObject()
            }
            else
            {
                self.arrayController.removeObjectAtArrangedObjectIndex(dragRow!)
                self.arrayController.insertObject(targetEntry, atArrangedObjectIndex: row)
                self.rearrangeObject()
            }
            
            cout("params apps: " + String(_params.apps.count))
            
            return true
        }
        else if (types?.contains(NSFilenamesPboardType) != nil)
        {
            //TODO: Drop a new entry.
            cout("NSFilenamesPboardType types")
            return true
        }
        
        return false
    }
}
