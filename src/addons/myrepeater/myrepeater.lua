
_addon.author   = 'bluekirby0 / Eleven Pies';
_addon.name     = 'MyRepeater';
_addon.version  = '3.0.0';

require 'common'

local __go;
----local __command;
----local __timer;
----local __cycle;

local __cmds = { };

local function zerotimer()
    return os.clock();
end

local function getcmd(key)
    local cmditem = __cmds[key];
    if (cmditem == nil) then
        cmditem = { };
        cmditem.command = '';
        cmditem.limit = 0;
        cmditem.position = 0;
        cmditem.cycle = 5;
        cmditem.offset = 0;
        cmditem.timer = zerotimer();
        cmditem.go = false;
        __cmds[key] = cmditem;
    end

    return cmditem;
end

local function setgo()
    local go = false;

    for k, v in pairs(__cmds) do
        if (v.go) then
            go = true;
        end
    end

    __go = go;
end

local function concatargs(args, seperator, startpos, endpos)
    local t = { };
    for k, v in pairs(args) do
        local s = string.gsub(string.gsub(v, '\\\"', '"'), '\\\\', '\\');
        table.insert(t, s);
    end

    return table.concat(t, seperator, startpos, endpos);
end

local function resumecmd(key)
    local cmditem = getcmd(key);

    if(#cmditem.command > 1) then
        print("Starting cycle!")
        -- Do not reset position for resuming
        cmditem.timer = zerotimer() - cmditem.offset;
        cmditem.go = true;
        setgo();
    else
        print("Set a command first!")
    end
end

local function startcmd(key)
    local cmditem = getcmd(key);

    if(#cmditem.command > 1) then
        print("Starting cycle!")
        cmditem.position = 0;
        cmditem.timer = zerotimer() - cmditem.offset;
        cmditem.go = true;
        setgo();
    else
        print("Set a command first!")
    end
end

local function stopcmd(key)
    local cmditem = getcmd(key);

    cmditem.go = false;
    setgo();
    print("Cycle Terminated!")
end

local function resumeall()
    for k, v in pairs(__cmds) do
        -- Do not reset position for resuming
        v.timer = zerotimer() - v.offset;
        v.go = true;
    end
    setgo();
    print("Starting all!");
end

local function startall()
    for k, v in pairs(__cmds) do
        v.position = 0;
        v.timer = zerotimer() - v.offset;
        v.go = true;
    end
    setgo();
    print("Starting all!");
end

local function stopall()
    for k, v in pairs(__cmds) do
        v.go = false;
    end
    setgo();
    print("Stopping all!");
end

local function toggleall()
    if (__go) then
        stopall();
    else
        startall();
    end
end

local function pauseall()
    if (__go) then
        stopall();
    else
        resumeall();
    end
end

---------------------------------------------------------------------------------------------------
-- func: confFromExternal
-- desc: Converts from external settings to internal settings
---------------------------------------------------------------------------------------------------
local function confFromExternal(externalConf)
    local internalConf = { };

    for k, v in pairs(externalConf) do
        -- Create internal item and fill in from external item
        -- Need to set values on required internal properties
        local item = { };
        item.command = v.command;
        item.limit = v.limit;
        item.position = 0;
        item.cycle = v.cycle
        item.offset = v.offset;
        item.timer = zerotimer();
        item.go = v.go;

        if (v.go) then
            item.timer = zerotimer() - item.offset;
        end

        internalConf[k] = item;
    end

    return internalConf;
end

---------------------------------------------------------------------------------------------------
-- func: confToExternal
-- desc: Converts from internal settings to external settings
---------------------------------------------------------------------------------------------------
local function confToExternal(internalConf)
    local externalConf = { };

    for k, v in pairs(internalConf) do
        -- Create external item and fill in from internal item
        -- Only copying certain internal properties
        local item = { };
        item.command = v.command;
        item.limit = v.limit;
        item.cycle = v.cycle;
        item.offset = v.offset;
        item.go = v.go;

        externalConf[k] = item;
    end

    return externalConf;
end

local function loadconf(filename)
    if (__go) then
        stopall();
    end

    __cmds = confFromExternal(ashita.settings.load(_addon.path .. 'settings/' .. filename .. '.json'));
    setgo();
    print ("Commands loaded: " .. filename .. '.json');
    for k, v in pairs(__cmds) do
        if (v.go) then
            print ("Command started: " .. k);
        end
    end
end

local function saveconf(filename)
    ashita.settings.save(_addon.path .. 'settings/' .. filename .. '.json', confToExternal(__cmds));
    print ("Commands saved: " .. filename .. '.json');
end

ashita.register_event('load', function(cmd, nType)
end );

ashita.register_event('command', function(cmd, nType)
    local key;
    local cmditem;
    local cycle;
    local offset;
    local limit;

    -- Ensure we should handle this command..
    local args = cmd:args();
    if (args[1] ~= '/repeat') then
        return false;
    elseif (#args < 2) then
        return true;
    elseif ((args[2] == 'set') and (#args >= 4)) then
        key = args[3];
        cmditem = getcmd(key);

        ----cmditem.command = table.concat(args," ",4,#args);
        cmditem.command = concatargs(args," ",4,#args);
        print ("Command to be repeated: " .. cmditem.command);
        return true;
    elseif (args[2] == 'start' and (#args >= 3)) then
        key = args[3];
        startcmd(key);
        return true;
    elseif (args[2] == 'stop' and (#args >= 3)) then
        key = args[3];
        stopcmd(key);
        return true;
    elseif (args[2] == 'resume' and (#args >= 3)) then
        key = args[3];
        resumecmd(key);
        return true;
    elseif ((args[2] == 'cycle') and (#args == 4)) then
        key = args[3];
        cmditem = getcmd(key);

        cycle = tonumber(args[4]);
        if(cycle < 1) then cycle = 1 end
        cmditem.cycle = cycle;
        cmditem.timer = zerotimer();
        print("Command will be executed every " .. cmditem.cycle .. " seconds!")
        return true;
    elseif ((args[2] == 'offset') and (#args == 4)) then
        key = args[3];
        cmditem = getcmd(key);

        offset = tonumber(args[4]);
        if ((offset < -86400) or (offset > 86400)) then offset = 0 end
        cmditem.offset = offset;
        cmditem.timer = zerotimer();
        print("Initial offset set to " .. cmditem.offset .. " seconds!")
        return true;
    elseif ((args[2] == 'limit') and (#args == 4)) then
        key = args[3];
        cmditem = getcmd(key);

        limit = tonumber(args[4]);
        if (limit < 0) then limit = 0 end
        cmditem.limit = limit;
        cmditem.position = 0;
        print("Limit set to " .. cmditem.limit .. " times!")
        return true;
    elseif (args[2] == 'remove' and (#args >= 3)) then
        key = args[3];
        __cmds[key] = nil;
        print("Command removed!")
        return true;
    elseif (args[2] == 'help') then
        print("Valid commands are set start stop and cycle")
        print("Backslashes and doublequotes in commands must be backslash escaped")
        return true;
    elseif (args[2] == 'startall') then
        startall();
        return true;
    elseif (args[2] == 'stopall') then
        stopall();
        return true;
    elseif (args[2] == 'resumeall') then
        resumeall();
        return true;
    elseif (args[2] == 'toggleall') then
        toggleall();
        return true;
    elseif (args[2] == 'pauseall') then
        pauseall();
        return true;
    elseif (args[2] == 'load' and (#args >= 3)) then
        local filename = args[3];
        loadconf(filename);
        return true;
    elseif (args[2] == 'save' and (#args >= 3)) then
        local filename = args[3];
        saveconf(filename);
        return true;
    elseif (args[2] == 'debug') then
        print('Commands:');
        for k, v in pairs(__cmds) do
            print('Command ' .. tostring(k) .. ': ' .. v.command);
            print('Cycle: ' .. tostring(v.cycle));
            print('Offset: ' .. tostring(v.offset));
            print('Limit: ' .. tostring(v.limit));
            print('Position: ' .. tostring(v.position));
            print('Timer: ' .. tostring(v.timer));
            if (v.go) then
                print('Go: true');
            else
                print('Go: false');
            end
        end
        return true;
    end

    return false;
end );

ashita.register_event('timerpulse', function()
    if(__go) then
        -- Get zerotimer once per pulse
        local thiszerotimer = zerotimer();

        for k, v in pairs(__cmds) do
            if (v.go) then
                if ((v.timer + v.cycle) <= thiszerotimer) then
                    AshitaCore:GetChatManager():QueueCommand(v.command, 1);
                    v.timer = thiszerotimer;

                    if (v.limit > 0) then
                        v.position = v.position + 1;
                        if (v.position >= v.limit) then
                            print('stopping ' .. v.command);
                            v.go = false;
                            setgo();
                        end
                    end
                end
            end
        end
    end
end );
