//
//  AppLauncher2
//
//  Created by Takashi
//  http://takashiaoki.com
//
//  Copyright (c) 2015 Takashi Aoki. All rights reserved.
//

import Cocoa

//TODO: save the entry list
@objc(AppEntry)
class AppEntry: NSObject
{
    var name: String = ""
    var path: String = ""
    var hide: Bool   = false
    var icon: NSImage!
    
    //TODO: error handling in case of that the icon file is missing.
    init(aPath p: String, aName n: String, aHide h: Bool, aIcon i: NSImage!)
    {
        path = p; name = n; hide = h; icon = i
    }
    convenience override init()
    {
        self.init(aPath: "",aName: "", aHide: false, aIcon: nil)
    }
}

class LaunchParams: NSObject, NSCoding
{
    var keepRun     : Bool = false
    var timerEnabled: Bool = false
    
    
    // TODO: should use a tuple for these? -> maybe Tuple can not be encoded because it's not a class!
    var quitHour    : Int  = -1
    var quitMinute  : Int  = -1
    
    // TEST
    //var quitTime:(hour:Int, minute:Int) = (-1,-1)
    
    // TODO: needs application list.
    //var apps: [String] = []
    
    override init(){}
    
    required init(coder aDecoder: NSCoder)
    {
        keepRun = aDecoder.decodeObjectForKey("KR") as! Bool
        timerEnabled = aDecoder.decodeObjectForKey("TE") as! Bool
        quitHour   = aDecoder.decodeObjectForKey("QH") as! Int
        quitMinute = aDecoder.decodeObjectForKey("QM") as! Int
        
        //TEST
        //quitTime = aDecoder.decodeObjectForKey("QT") as! (Int, Int)
    }
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(keepRun, forKey:"KR")
        aCoder.encodeObject(timerEnabled, forKey:"TE")
        aCoder.encodeObject(quitHour, forKey:"QH")
        aCoder.encodeObject(quitMinute, forKey:"QM")
        
        //TEST
        //aCoder.encodeObject(quitTime, forKey:"QT")
    }
}

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
    
    //TODO: validation for adding only application file.
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
                print(openPanel.URL?.absoluteString)
                print(openPanel.URL?.lastPathComponent)
                
                let path = openPanel.URL?.path
                let name = openPanel.URL?.lastPathComponent
                let appname = name?.stringByDeletingPathExtension
                
                // TODO: set the icon image into the entry
                let ws = NSWorkspace.sharedWorkspace()
                let icon: NSImage = ws.iconForFile(path!)
                let entry: AppEntry = AppEntry(aPath: path!, aName: appname!, aHide: false, aIcon: icon)
                
                self.arrayController.addObject(entry)
                self.rearrangeObject()
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
            
            if target.hide
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
    func launchApp(t: NSTimer)
    {
        let userInfo = t.userInfo as! Dictionary<String, AnyObject>
        let path: String = userInfo["aPath"] as! String
        NSWorkspace.sharedWorkspace().launchApplication(path)
    }
    
    //MARK: - TableView
    //TODO: set the table-view's order to be editable.
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
