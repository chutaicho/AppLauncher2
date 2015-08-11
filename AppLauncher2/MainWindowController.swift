//
//  AppLauncher2
//
//  Created by Takashi
//  http://takashiaoki.com
//
//  Copyright (c) 2015 Takashi Aoki. All rights reserved.
//

import Cocoa

typealias KVOContext = UInt8
var MyObservationContext = KVOContext()

class MainWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate
{
    @IBOutlet weak var arrayController: NSArrayController!
    
    @IBOutlet weak var keepRunButton: NSButton!
    @IBOutlet weak var timerEnabled:  NSButton!
    @IBOutlet weak var delaySlider:   NSSlider!
    @IBOutlet weak var delayTF:       NSTextField!
    
    
    // MARK: - consts
    let NIB_NAME     = "MainWindowController"
    let UDKEY_PARAMS = "SavedParams"
    let REBOOT_DELAY = 1.0
    
    // MARK: - vars
    var _params  : LaunchParams   = LaunchParams()
    var _keepRun : Bool           = true;
    var _timer   : NSTimer        = NSTimer()
    
    override var windowNibName: String? { return NIB_NAME }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()

        let userD = NSUserDefaults.standardUserDefaults()
        
        //MARK: DEBUG
        //deleteUserDefault()
        
        if let data = userD.objectForKey(UDKEY_PARAMS) as? NSData
        {
            let params = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! LaunchParams
            
            //TODO: should copy manually?
            _params.keepRun      = params.keepRun
            _params.timerEnabled = params.timerEnabled
            _params.quitHour     = params.quitHour
            _params.quitMinute   = params.quitMinute
            _params.delay        = params.delay
            
            cout("--------")
            cout(_params.keepRun)
            cout(_params.timerEnabled)
            cout(_params.quitHour)
            cout(_params.quitMinute)
            cout(_params.delay)
            
            keepRunButton.state  = _params.keepRun ? 1 : 0
            timerEnabled.state   = _params.timerEnabled ? 1 : 0
            delaySlider.integerValue = _params.delay
            delayTF.integerValue = _params.delay
            
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
        }
        else
        {
            cout("params undefined.")
        }
        
        let nc = NSWorkspace.sharedWorkspace().notificationCenter
        nc.addObserver(self, selector: "onLaunchNotification:", name: NSWorkspaceDidLaunchApplicationNotification,    object: nil)
        nc.addObserver(self, selector: "onQuitNotification:",   name: NSWorkspaceDidTerminateApplicationNotification, object: nil)
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("timerUpdate"), userInfo: nil, repeats: true)
    }

    // MARK: - IBAction
    @IBAction func quitApplication(sender: NSButton)
    {
        exit()
    }
    @IBAction func keepRunHandler(sender: NSButton)
    {
        _params.keepRun = sender.state == NSOnState ? true : false
        save()
    }
    @IBAction func delayHandler(sender: NSSlider)
    {
        _params.delay = sender.integerValue
        delayTF.integerValue = _params.delay
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
                    if !self.isOurApp(aPath: path!)
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
        let date = NSDate()
        let cal = NSCalendar.currentCalendar()
        let hour    = cal.components(NSCalendarUnit.Hour, fromDate: date).hour
        let minutes = cal.components(NSCalendarUnit.Minute, fromDate: date).minute
        let now:(h:Int,m:Int) = (hour, minutes)
        
        //print("now: " + String(now.h) + ":" + String(now.m))
        //print("set: " + String(_params.quitHour) + ":" + String(_params.quitMinute))
        if now.h == _params.quitHour && now.m == _params.quitMinute
        {
            exit()
        }
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
    
    
    //MARK: - private
    //private
    func save()
    {
        let ud = NSUserDefaults.standardUserDefaults()
        ud.setValue(NSKeyedArchiver.archivedDataWithRootObject(_params), forKey: UDKEY_PARAMS)
        cout("----------> saved.")
    }
    private func rearrangeObject()
    {
        self.arrayController.rearrangeObjects()
        save()
    }
    private func isOurApp(aPath path: String) -> Bool
    {
        var res = false
        
        for entry:AppEntry in _params.apps
        {
            if entry.path == path
            {
                res = true
                cout(path + " is our app.")
                break
            }
        }
        
        return res
    }
    //MARK: - TableView
    //TODO: set the table-view's order to be editable.
}
