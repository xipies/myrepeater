
_addon.author   = 'bluekirby0 / Eleven Pies';
_addon.name     = 'MyRepeater';
_addon.version  = '3.1.0';

require 'common'
require 'myexec.myexec'

local function loadconf(filename)
    myexec.set_all(ashita.settings.load(_addon.path .. 'settings/' .. filename .. '.json'));
    myexec.persist_all(true);
    print ("Commands loaded: " .. filename .. '.json');
end

local function saveconf(filename)
    ashita.settings.save(_addon.path .. 'settings/' .. filename .. '.json', myexec.get_all());
    print ("Commands saved: " .. filename .. '.json');
end

ashita.register_event('command', function(cmd, nType)
    -- Ensure we should handle this command..
    local args = cmd:args();
    if (args[1] ~= '/repeat') then
        return false;
    elseif (#args < 2) then
        return true;
    elseif (args[2] == 'start' and (#args >= 3)) then
        myexec.start_steps(args[3]);
        return true;
    elseif (args[2] == 'stop' and (#args >= 3)) then
        myexec.stop_steps(args[3]);
        return true;
    elseif (args[2] == 'resume' and (#args >= 3)) then
        myexec.resume_steps(args[3]);
        return true;
    elseif (args[2] == 'help') then
        print("Valid commands are load save start stop")
        print("Backslashes and doublequotes in commands must be backslash escaped")
        return true;
    elseif (args[2] == 'startall') then
        myexec.start_all();
        return true;
    elseif (args[2] == 'stopall') then
        myexec.stop_all();
        return true;
    elseif (args[2] == 'resumeall') then
        myexec.resume_all();
        return true;
    elseif (args[2] == 'toggleall') then
        myexec.toggle_all();
        return true;
    elseif (args[2] == 'pauseall') then
        myexec.pause_all();
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
        myexec.print_debug();
        return true;
    end

    return false;
end );
