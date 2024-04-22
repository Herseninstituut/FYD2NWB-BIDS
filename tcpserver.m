
  %% SERVER


    s = tcpserver("localhost", 8080, "ConnectionChangedFcn", @connectionFcn);   
    configureCallback(s,"terminator", @readFcn);

    function connectionFcn (src,~)
        if src.Connected
           disp("client connection request accepted.")
        else
           disp("Client has disconnected.")
        end
    end
    
    function readFcn(src, ~)
        message = readline(src);
        disp(message)
   end



%% CLIENT

% client = tcpclient("192.87.10.37",8080)
% 
% writeline(client, "Hello  world")
% 
% writeline(client, '{ "hello": "world" )' )
% 
% client = []
