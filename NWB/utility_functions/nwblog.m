function nwblog(messg)

[~, name] = system('hostname');
if contains(name, 'MVP-server')
    messg = append(messg, '<br>');
    system(['ssh fyd@10.41.53.10 "echo ''', messg,''' >> ./NWB/nwblog.html"'])
else
    disp(messg);
end

