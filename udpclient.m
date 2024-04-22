classdef udpclient < handle
% write data to udpport on vcserver: 192.87.11.191 port: 60816
  properties (Access = private)
    up 
    server = '192.87.11.191';
    port = 60816;
  end
    
  methods 
    function g = udpclient() 
         g.up = udpport("byte",'IPV4');
         configureCallback(g.up,"terminator", @readudp);
         
         ipadress = get_ipadress();
         strjson = ['{ "messg": "connected", "client": "', ipadress, '", "port": "', num2str(g.up.LocalPort), '" }'];
         writeline(g.up, strjson , g.server, g.port)
          
        function readudp(src, ~)
            command = readline(src);
            disp(command)
        end
    end 

    function write(g, strjson)
        if ischar(strjson)
            writeline(g.up,strjson, g.server, g.port)
        end
        %flush(u)
    end
  end
    
end
