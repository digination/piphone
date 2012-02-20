        uuid = argv[1];
	dialstr1 = argv[2];
	dialstr2 = argv[3];
	dialstr12 = argv[4];
	dialstr22 = argv[5];
	greeting_snd = "/usr/local/freeswitch/sounds/"..argv[6];

	-- if (#argv > 6 and not argv[6] == "") then
	--        greeting_snd = "/usr/local/freeswitch/sounds"..argv[6];
	-- end

	max_retriesl1 = 5;
	max_retriesl2 = 3;
	connected = false;
	timeout = 45;

	freeswitch.consoleLog("notice", "*********** STARTING Call ***********\n");
	freeswitch.consoleLog("notice", "*********** DIALING "..dialstr1.." ***********\n");

	originate_base1 = "{ignore_early_media=true,originate_timeout=90,hangup_after_bridge=true,origination_uuid="..uuid..",leg=1}";
	originate_str1 = originate_base1..dialstr1;
	originate_str12 = originate_base1..dialstr12;

	session1 = null;
	retries = 0;
	ostr = "";
	repeat  
			retries = retries + 1;
	        if (retries % 2) then ostr = originate_str1;
		else ostr = originate_str12; end
	        freeswitch.consoleLog("notice", "*********** Dialing Leg1: " .. ostr .. " - Try: "..retries.." ***********\n");
	        session1 = freeswitch.Session(ostr);
	        local hcause = session1:hangupCause();
	        freeswitch.consoleLog("notice", "*********** Leg1: " .. hcause .. " - Try: "..retries.." ***********\n");
	until not ((hcause == 'NO_ROUTE_DESTINATION' or hcause == 'RECOVERY_ON_TIMER_EXPIRE' or hcause == 'INCOMPATIBLE_DESTINATION' or hcause == 'CALL_REJECTED' or hcause == 'NORMAL_TEMPORARY_FAILURE') and (retries < max_retriesl1))

	if (session1:ready()) then
	        -- log to the console
	        freeswitch.consoleLog("notice", "*********** Leg1 ("..ostr..") CONNECTED! ***********\n");

	        -- Play greeting message
	        -- if (not greeting_snd == "") then
	                freeswitch.consoleLog("notice", "*********** Playing greeting sound: "..greeting_snd.." ***********\n");
	                --session1:execute("sleep", 100);
	                session1:execute("playback", greeting_snd);
	        -- end

	        originate_base2 = "{ignore_early_media=true,originate_timeout=90,hangup_after_bridge=true,origination_uuid="..uuid..",leg=2}";
	        originate_str2 = originate_base2..dialstr2;
	        originate_str22 = originate_base2..dialstr22;

	        -- Set recording: uncomment these two lines if you'd like to record the call in stereo (one leg on each channel)
	        -- session1:setVariable("RECORD_STEREO", "true");
	        -- session1:execute("record_session", "/tmp/"..uuid..".wav");

	        -- Set ringback
	        session1:setVariable("ringback", "%(2000,4000,440,480)");

	        retries = 0;
	        session2 = null;
	        repeat  
	                -- Create session2
	                retries = retries + 1;
	                if (retries % 2) then ostr2 = originate_str2;
	                else ostr2 = originate_str22; end
	                freeswitch.consoleLog("notice", "*********** Dialing: " .. ostr2 .. " Try: "..retries.." ***********\n");
	                session2 = freeswitch.Session(ostr2, session1);
	                local hcause = session2:hangupCause();
	                freeswitch.consoleLog("notice", "*********** Leg2: " .. hcause .. " Try: " .. retries .. " ***********\n");
	        until not ((hcause == 'NO_ROUTE_DESTINATION' or hcause == 'RECOVERY_ON_TIMER_EXPIRE' or hcause == 'INCOMPATIBLE_DESTINATION' or hcause == 'CALL_REJECTED' or hcause == 'NORMAL_TEMPORARY_FAILURE') and (retries < max_retriesl2))

	        if (session2:ready()) then
	                freeswitch.consoleLog("notice", "*********** Leg2 ("..ostr2..") CONNECTED! ***********\n");
	                freeswitch.bridge(session1, session2);

	                -- Hangup session2 if session1 is over
	                if (session2:ready()) then session2:hangup(); end
	        end
	        -- hangup when done
	        if (session1:ready()) then session1:hangup(); end
	end

