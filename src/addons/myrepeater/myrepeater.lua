
_addon.author   = 'bluekirby0 / Eleven Pies';
_addon.name     = 'MyRepeater';
_addon.version  = '2.0.0';

require 'common'

local __go;
----local __command;
----local __timer;
----local __cycle;
local __invdivisor;

local __cmds = { };

function read_fps_divisor() -- borrowed from fps addon
    local fpscap = { 0x81, 0xEC, 0x00, 0x01, 0x00, 0x00, 0x3B, 0xC1, 0x74, 0x21, 0x8B, 0x0D };
    local fpsaddr = mem:FindPattern('FFXiMain.dll', fpscap, #fpscap, 'xxxxxxxxxxxx');
    if (fpsaddr == 0) then
        print('[FPS] Could not locate required signature!');
        return true;
    end

    -- Read the address..
    local addr = mem:ReadULong(fpsaddr + 0x0C);
    addr = mem:ReadULong(addr);
    return mem:ReadULong(addr + 0x30);
end;

local function getcmd(key)
    local cmditem = __cmds[key];
    if (cmditem == nil) then
        cmditem = { };
        cmditem.command = '';
        cmditem.cycle = 5;
        cmditem.fpscycle = __invdivisor * cmditem.cycle;
        cmditem.offset = 0;
        cmditem.fpsoffset = __invdivisor * cmditem.offset;
        cmditem.timer = 0;
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

local function setfpscycle()
    for k, v in pairs(__cmds) do
        v.fpscycle = __invdivisor * v.cycle;
        v.fpsoffset = __invdivisor * v.offset;
    end
end

local function concatargs(args, seperator, startpos, endpos)
    local t = { };
    for k, v in pairs(args) do
        local s = string.gsub(string.gsub(v, '\\\"', '"'), '\\\\', '\\');
        table.insert(t, s);
    end

    return table.concat(t, seperator, startpos, endpos);
end

local function startcmd(key)
    local cmditem = getcmd(key);

    if(#cmditem.command > 1) then
        print("Starting cycle!")
        setfpscycle();
        cmditem.timer = cmditem.fpsoffset;
        cmditem.go = true;
        setgo();
    else
        print("Set a command first!")
    end
end

local function stopcmd(key)
    local cmditem = getcmd(key);

    cmditem.go = false;
    setfpscycle();
    setgo();
    print("Cycle Terminated!")
end

local function startall()
    setfpscycle();
    for k, v in pairs(__cmds) do
        v.timer = v.fpsoffset;
        v.go = true;
    end
    setgo();
    print("Starting all!");
end

local function stopall()
    for k, v in pairs(__cmds) do
        v.go = false;
    end
    setfpscycle();
    setgo();
    print("Stopping all!");
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
        item.cycle = v.cycle
        item.fpscycle = __invdivisor * v.cycle;
        item.offset = v.offset;
        item.fpsoffset = __invdivisor * v.offset;
        item.timer = 0;
        item.go = v.go;

        if (v.go) then
            item.timer = item.fpsoffset;
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

    __cmds = confFromExternal(settings:load(_addon.path .. 'settings/' .. filename .. '.json'));
    setfpscycle();
    setgo();
    print ("Commands loaded: " .. filename .. '.json');
    for k, v in pairs(__cmds) do
        if (v.go) then
            print ("Command started: " .. k);
        end
    end
end

local function saveconf(filename)
    setfpscycle();
    settings:save(_addon.path .. 'settings/' .. filename .. '.json', confToExternal(__cmds));
    print ("Commands saved: " .. filename .. '.json');
end

ashita.register_event('load', function(cmd, nType)
    ----__go = false;
    ----__command = "";
    ----__timer = 0;
    ----__cycle = 5;
end );

ashita.register_event('command', function(cmd, nType)
    __invdivisor = 60 / read_fps_divisor();

    local key;
    local cmditem;
    local cycle;
    local offset;

    -- Ensure we should handle this command..
    local args = cmd:GetArgs();
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
    elseif ((args[2] == 'cycle') and (#args == 4)) then
        key = args[3];
        cmditem = getcmd(key);

        cycle = tonumber(args[4]);
        if(cycle < 1) then cycle = 1 end
        cmditem.cycle = cycle;
        cmditem.timer = 0;
        print("Command will be executed every " .. cmditem.cycle .. " seconds!")
        return true;
    elseif ((args[2] == 'offset') and (#args == 4)) then
        key = args[3];
        cmditem = getcmd(key);

        offset = tonumber(args[4]);
        if ((offset < -86400) or (offset > 86400)) then offset = 0 end
        cmditem.offset = offset;
        cmditem.timer = 0;
        print("Initial offset set to " .. cmditem.offset .. " seconds!")
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
    elseif (args[2] == 'load' and (#args >= 3)) then
        local filename = args[3];
        loadconf(filename);
        return true;
    elseif (args[2] == 'save' and (#args >= 3)) then
        local filename = args[3];
        saveconf(filename);
        return true;
    elseif (args[2] == 'debug') then
        setfpscycle();
        print('Commands:');
        for k, v in pairs(__cmds) do
            print('Command ' .. tostring(k) .. ': ' .. v.command);
            print('Cycle: ' .. tostring(v.cycle));
            print('Render cycle: ' .. tostring(v.fpscycle));
            print('Offset: ' .. tostring(v.offset));
            print('Render offset: ' .. tostring(v.fpsoffset));
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

ashita.register_event('render', function()
    if(__go) then
        for k, v in pairs(__cmds) do
            if(v.timer >= v.fpscycle) then
                AshitaCore:GetChatManager():QueueCommand(v.command, 1);
                v.timer = 0;
            else
                v.timer = v.timer + 1;
            end
        end
    end
end );
