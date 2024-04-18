
%% SERVER
function connectionFcn(src,~)
    if src.Connected
       disp("client connection request accepted.")
    else
       disp("Client has disconnected.")
    end
end

function readFcn(src,~)
    message = readline(src);
    disp(message)
end


server = tcpserver("localhost", 8080, "ConnectionChangedFcn", @connectionFcn);

configureCallback(server,"terminator", @readFcn)





%% CLIENT

client = tcpclient("localhost",8080)

writeline(client, "Hello  world")

writeline(client, '{ "hello": "world" )' )

client = []
