% udpserver

u = udpport("IPV4", LocalPort=60816);
configureCallback(u,"terminator", @readudp);

function readudp(src, ~)
    command = readline(src);
    disp(command)
end