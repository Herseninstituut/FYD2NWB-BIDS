% udpserver

u = udpport("IPV4", LocalPort=60816);
configureCallback(u,"terminator", @readudp);

function readudp(src, ~)
    persistent client port
    strdata = readline(src);
    try
        data = jsondecode(strdata);
    catch
        writeline(src, 'Error decoding json input', client, str2double(port))
        return
    end

    if isfield(data, 'messg')
        if matches(data.messg, 'connected')
            client = data.client;
            port = data.port;
            writeline(src, data.messg, client, port)
        end
    end
    disp(data)
 
end