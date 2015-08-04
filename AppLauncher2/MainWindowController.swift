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
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tableColumn: NSTableColumn!
    @IBOutlet weak var arrayController: NSArrayController!
    
    // MARK: - consts
    let NIB_NAME     = "MainWindowController"
    let UDKEY_PARAMS = "SavedParams"
    let REBOOT_DELAY = 1.0
    
    // MARK: - vars
    var _params  : LaunchParams   = LaunchParams()
    var _keepRun : Bool           = true;
    var _timer   : NSTimer        = NSTimer()
    var _apps    : [AppEntry]     = []
    
    override var windowNibName: String? { return NIB_NAME }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()

        let userD = NSUserDefaults.standardUserDefaults()
        
        //TODO: solve when the param is empty.
        if let data = userD.objectForKey(UDKEY_PARAMS) as? NSData
        {
//            let params = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! LaunchParams
//            
//            print(params.keepRun)
//            print(params.timerEnabled)
//            print(params.quitHour)
//            print(params.quitMinute)
            
            //_params = params
            
            print("params decoded.")
            
            //TODO: set the saved params into the app.
        }
        else
        {
            print("params undefined.")
        }
        
        let nc = NSWorkspace.sharedWorkspace().notificationCenter
        nc.addObserver(self, selector: "onLaunchNotification:", name: NSWorkspaceDidLaunchApplicationNotification,    object: nil)
        nc.addObserver(self, selector: "onQuitNotification:",   name: NSWorkspaceDidTerminateApplicationNotification, object: nil)
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(REBOOT_DELAY, target: self, selector: Selector("timerUpdate"), userInfo: nil, repeats: true)
    }
    
    // MARK: - IBAction
    @IBAction func quitApplication(sender: NSButton)
    {
        //TODO: quit all apps which are on the list.
        
        NSThread.sleepForTimeInterval(0.25) // sleep a bit before quitting.
        NSApp.terminate(self)
    }
    @IBAction func keepRunHandler(sender: NSButton)
    {
        _params.keepRun = sender.state == NSOnState ? true : false
        save()
    }
    @IBAction func endTimeCheckBoxHandler(sender: NSButton)
    {
        _params.timerEnabled = sender.state == NSOnState ? true : false
        save()
    }
    @IBAction func endTimeHandler(sender: NSDatePicker)
    {
        let value   = sender.dateValue
        let cal     = NSCalendar.currentCalendar()
        let hour    = cal.components(NSCalendarUnit.Hour, fromDate: value).hour
        let minutes = cal.components(NSCalendarUnit.Minute, fromDate: value).minute
        
        _params.quitHour = hour
        _params.quitMinute = minutes
        
        save()
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
                
                //print(openPanel.URL?.absoluteString)
                //print(openPanel.URL?.lastPathComponent)
                
                let path = openPanel.URL?.path
                let name = openPanel.URL?.lastPathComponent
                let appname = name?.stringByDeletingPathExtension
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
//                    let ws = NSWorkspace.sharedWorkspace()
//                    let icon: NSImage = ws.iconForFile(path!)
                    let entry: AppEntry = AppEntry()
                    entry.set(aPath: path!, aName: appname!, aHide: false)//, aIcon: nil)
                    entry.fetchIconData()
                    
                    self.arrayController.addObject(entry)
                    self.rearrangeObject()
                }
            }
        }
    }
    @IBAction func removeApplication(sender:NSButton)
    {
        self.arrayController.removeObjectAtArrangedObjectIndex(self.arrayController.selectionIndex)
        self.rearrangeObject()
        
        //TODO: store full-path list to _params
    }
    
    // MARK: - Event handlers
    func onLaunchNotification(notification: NSNotification?)
    {
        if let info = notification!.userInfo
        {
            let name: String = info["NSApplicationName"] as! String
            let path: String = info["NSApplicationPath"] as! String
            print("launched: " + path + ", " + name)
            
            var target:AppEntry!
            for entry:AppEntry in _apps
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
                NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("launchApp:"), userInfo: ["aPath": path], repeats: false)
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
        //TODO: check the current time. shutdown everything.
        
        let date = NSDate()
        let cal = NSCalendar.currentCalendar()
        let hour    = cal.components(NSCalendarUnit.Hour, fromDate: date).hour
        let minutes = cal.components(NSCalendarUnit.Minute, fromDate: date).minute
        
        let now:(h:Int,m:Int) = (hour, minutes)
        print(String(now.h) + ":" + String(now.m))
    }
    func clear()
    {
        
    }
    
    
    //MARK: - private
    private func save()
    {
        let ud = NSUserDefaults.standardUserDefaults()
        ud.setValue(NSKeyedArchiver.archivedDataWithRootObject(_params), forKey: UDKEY_PARAMS)
    }
    private func rearrangeObject()
    {
        self.arrayController.rearrangeObjects()
    }
    private func isOurApp(aPath path: String) -> Bool
    {
        var res = false
        
        for entry:AppEntry in _apps
        {
            if entry.path == path
            {
                res = true
                print(path + " is our app.")
                break
            }
        }
        
        return res
    }
    
    //MARK: - TableView
    //TODO: set the table-view's order to be editable.
    func validatePath(stringPointer: AutoreleasingUnsafeMutablePointer<NSString?>, error outError: NSError) -> Bool
    {
        print("validated.")
        return false
    }
    func numberOfRowsInTableView(tableView: NSTableView) -> Int
    {
        let numberOfRows:Int = 10
        return numberOfRows
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
    {
        let string:String = "row " + String(row) + ", Col " + String(tableColumn?.identifier)
        return string
    }
}
