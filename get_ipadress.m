function ipadress = get_ipadress()
% gets the ip adress of the system you are running matlab on

[~, comout] = system('ipconfig');
newStr = splitlines(comout);
pat = digitsPattern(1,3) + "." + digitsPattern(1,3) + "." + digitsPattern(1,3) + "." + digitsPattern(1,3);

for i = 1:length(newStr)
    str = newStr{i};
    if contains(str, 'IPv4')
        idx = strfind(str, pat);
        ipadress = str(idx(1):end);
        % disp(ipadress)
        break
    end
end