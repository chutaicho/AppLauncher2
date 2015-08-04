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
class AppEntry: NSObject, NSCoding
{
    var name: String = ""
    var path: String = ""
    var hide: Bool   = false
    var icon: NSImage!
    
    //TODO: error handling in case of that the icon file is missing.
    func set(aPath p: String, aName n: String, aHide h: Bool)
    {
        path = p; name = n; hide = h;
    }
    
    //    convenience override init()
    //    {
    //        self.init(aPath: "",aName: "", aHide: false)//, aIcon: nil)
    //    }
    
    //TODO: change this into setter
    func fetchIconData()
    {
        let ws = NSWorkspace.sharedWorkspace()
        icon = ws.iconForFile(path)
    }
    
    override init(){}
    required init(coder aDecoder: NSCoder)
    {
        name = aDecoder.decodeObjectForKey("Name") as! String
        path = aDecoder.decodeObjectForKey("Path") as! String
        hide = aDecoder.decodeObjectForKey("Hide") as! Bool
    }
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(name, forKey:"Name")
        aCoder.encodeObject(path, forKey:"Path")
        aCoder.encodeObject(hide, forKey:"Hide")
    }
}

class LaunchParams: NSObject, NSCoding
{
    var keepRun     : Bool = false
    var timerEnabled: Bool = false
    
    // TODO: should use a tuple for these? -> NO. maybe Tuple can not be encoded because it's not a class!
    var quitHour    : Int  = -1
    var quitMinute  : Int  = -1
    
    // TODO: application list - can I do this?
    var apps: [AppEntry] = []
    
    override init(){}
    
    required init(coder aDecoder: NSCoder)
    {
        keepRun = aDecoder.decodeObjectForKey("KR") as! Bool
        timerEnabled = aDecoder.decodeObjectForKey("TE") as! Bool
        quitHour   = aDecoder.decodeObjectForKey("QH") as! Int
        quitMinute = aDecoder.decodeObjectForKey("QM") as! Int
        
        //TODO: can I do this?
        //apps = aDecoder.decodeObjectForKey("APPS") as! [AppEntry]
    }
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(keepRun, forKey:"KR")
        aCoder.encodeObject(timerEnabled, forKey:"TE")
        aCoder.encodeObject(quitHour, forKey:"QH")
        aCoder.encodeObject(quitMinute, forKey:"QM")
        
        //TEST
        //aCoder.encodeObject(apps, forKey:"APPS")
    }
}