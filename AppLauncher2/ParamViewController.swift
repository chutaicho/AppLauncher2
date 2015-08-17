//
//  AppLauncher2
//
//  Created by Takashi
//  http://takashiaoki.com
//
//  Copyright (c) 2015 Takashi Aoki. All rights reserved.
//

import Cocoa

class ParamViewController: NSWindowController
{
    // MARK: - consts
    let NIB_NAME = "ParamViewController"
    
    dynamic var keepRun: Bool      = true
    dynamic var timerEnabled: Bool = false
    dynamic var delay: Int         = 12
    dynamic var quitTime: NSDate   = NSDate()
    
    func setParams(params: LaunchParams)
    {
        keepRun = params.keepRun
        timerEnabled = params.timerEnabled
        delay = params.delay
        
        let cal  = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        let comp = NSDateComponents()
        comp.hour = params.quitHour
        comp.minute = params.quitMinute
        quitTime = cal!.dateFromComponents(comp)!
    }
    func getParams() -> LaunchParams
    {
        let params = LaunchParams()
        params.keepRun = keepRun
        params.timerEnabled = timerEnabled
        params.delay = delay
        
        let cal    = NSCalendar.currentCalendar()
        let hour   = cal.components(NSCalendarUnit.Hour, fromDate: quitTime).hour
        let minute = cal.components(NSCalendarUnit.Minute, fromDate: quitTime).minute
        
        params.quitHour = hour
        params.quitMinute = minute
        
        return params
    }
    
    override var windowNibName: String? { return NIB_NAME }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
    }
    
    //MARK: IBActions
    @IBAction func okayButtonClicked(button: NSButton)
    {
        let cal     = NSCalendar.currentCalendar()
        let hour    = cal.components(NSCalendarUnit.Hour, fromDate: quitTime).hour
        let minutes = cal.components(NSCalendarUnit.Minute, fromDate: quitTime).minute
        print("H: " + String(hour) + ", " + "M: " + String(minutes))
        
        dismissWithModalResponse(NSModalResponseOK)
    }
    @IBAction func cancelButtonClicked(button: NSButton)
    {
        dismissWithModalResponse(NSModalResponseCancel)
    }
    
    //MARK: public
    func dismissWithModalResponse(response: NSModalResponse)
    {
        window!.sheetParent!.endSheet(window!, returnCode: response)
    }
    
}
