function dat = func_uncell(dat, varargin)
if nargin > 1
    if isstr(varargin{1})
        if strcmp(varargin{1}, 'vec')
            dat = dat{:};
        end
    else
        dat = dat{varargin{:}};
    end
else
    dat = dat{varargin{:}};
end
end