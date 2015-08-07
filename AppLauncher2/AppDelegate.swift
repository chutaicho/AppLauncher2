//
//  AppLauncher2
//
//  Created by Takashi
//  http://takashiaoki.com
//
//  Copyright (c) 2015 Takashi Aoki. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    var _mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        let mainWindowController = MainWindowController()
        mainWindowController.showWindow(self)
        _mainWindowController = mainWindowController
    }

    func applicationWillTerminate(aNotification: NSNotification)
    {
        // Insert code here to tear down your application
        //_mainWindowController?.save()
    }
}