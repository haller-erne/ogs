	
    finishProcess 	= 0x0001 ,  // finish assembly processing (without waiting)
	clearProcess  	= 0x0002,   // clear all tightening results on assembly go to first Job

	startJob	  	= 0x0004,   // start current Job (is available only in WorkflowState::WaitJobStart)
	finishJob	  	= 0x0008,   // finish current Job processing and set WorkflowState::WaitJobStart
	skipJob		  	= 0x0010,   // finish current Job processing and go to next Job
	clearJob	  	= 0x0020,   // clear all tightening results on current Job and set WorkflowState::WaitJobStart

	skipRundown	  	= 0x0040,   // set current operation to NOK and go to next operation
	clearBolt 		= 0x0080,  	// set current Bolt to NOT_PROCESSED
	startDiag    	= 0x0100,  	// enable start diagnostic job
	selectRundown	= 0x0200,  	// select Job / Bolt in view or on image
	userLogon       = 0x0400,   // user logon
	pauseJob        = 0x0800,   // pause Job
	processNOK      = 0x1000,   //continue processing after NOK result
	CCW      		= 0x2000,   // CCW
	manualInput     = 0x4000,   // manual input in start view (added for LUA trace log only)
	unmountJob      = 0x8000,   // unmount Job
	switchTool      = 0x10000,  // switch between alternative and standard tool
	teachToolPos    = 0x20000,  // teach Tool position
	waitFinishProcess = 0x40000,  // finish assembly processing normally (wait for completion)
