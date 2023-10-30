% initDJ

global dbpar

dbpar = nhi_fyd_Aparms();
%dbpar = nhi_fyd_VCparms();
%dbpar = nhi_fyd_MVPparms();


setenv('DJ_HOST', dbpar.Server)
setenv('DJ_USER', dbpar.User)
setenv('DJ_PASS', dbpar.Passw)

Con = dj.conn();