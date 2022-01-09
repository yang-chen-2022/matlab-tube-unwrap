function [wrapped] = Wrap2(unwrapped,sizeWrapped,InterpMethod,varargin)
%Return a "unwrapped" tube volume to its initial "wrapped" configuration
%       Using 2D interpolation (interpn) slice per slice
%
%    [wrapped] = Wrap2(unwrapped,sizeWrapped,InterpMethod,OSL)
%    [wrapped] = Wrap2(unwrapped,sizeWrapped,InterpMethod,OSL,rmin,rmax)
%
%   Principe:
%       wrapped = interpn(Ruw,Thetauw,unwrapped,Rwr,Thetawr,method);
%
%   Inputs:
%       unwrapped:  the unwrapped 2D image to be wrapped
%       sizeWrapped: 1x2 matrix, the size of the "wrapped" image
%       InterpMethod:  method for interpolation
%             ('nearest','liner','pchip','cubic','spline')    
%       OSL:  the tube centre coordinate for every slice (matrix nBx2, with
%             nB the nomber of slices)
%       rmin,rmax (can be empty): the min,max radii during the previous
%             "unwrapping" stage. If rmin,rmax were not input, they will be
%             computed as : rmax=length(unwrapped)/(2pi);
%                           rmin=rmax-height(unwrapped);
%
%   Output:
%       wrapped:  the "wrapped" image
%
% Yang CHEN version 2018.12.05

[O0, rmin, rmax] = ParseInputs(varargin{:});

disp('wrapping...')


if islogical(unwrapped)
    wrapped = false(sizeWrapped);
else 
    wrapped = zeros(sizeWrapped,'like',unwrapped);
end
wrappedSL = wrapped(:,:,1);

% ------ Define a ndgrid of [R,Theta] for unwrapped configuration
if isempty(rmin)
    disp 'u should be sure about the [rmin,rmax] ! (see "UnWrap2.m")'
    rmax = size(unwrapped,2)/(2*pi);
    rmin = rmax-size(unwrapped,1);
    disp(['     rmin=',num2str(rmin),';   rmax=',num2str(rmax)]);
    Ruw=[rmin:1:rmax];
    if size(Ruw,2)>size(unwrapped,1)
        Ruw(end)=[];
    elseif size(Ruw,2)<size(unwrapped,1)
        Ruw=[Ruw,rmax];
    end
    dTheta=1./rmax;
    Thetauw=[0:dTheta:2.*pi];       % should be a "complete" sinusoidal period (0,2pi) 
else
    Ruw=[rmin:1:rmax];
    dTheta=1./rmax;
    Thetauw=[0:dTheta:2.*pi];       % should be a "complete" sinusoidal period (0,2pi) 
    Thetauw(end) = 2*pi;
end

[Ruw,Thetauw] = ndgrid(Ruw,Thetauw);


% ------ Define a ndgrid of [X,Y] for wrapped configuration
Xwr = 1:sizeWrapped(1);
Ywr = 1:sizeWrapped(2);
%[Xwr,Ywr] = ndgrid(Xwr,Ywr); 
[Ywr,Xwr] = ndgrid(Xwr,Ywr); %modified by Y.CHEN 2018.12.05

for i=1:sizeWrapped(3)
    % ------ From [X,Y]wr to [R,Theta]wr
    Rwr = ((Xwr-O0(i,1)).^2+(Ywr-O0(i,2)).^2).^0.5;
    Thetawr = acos((Xwr-O0(i,1))./Rwr);
    i0 = find(Ywr<O0(i,2));
    Thetawr(i0)=2*pi-Thetawr(i0);

    %idx0 = find(Rwr<=rmax & Rwr>=rmin); % choose the interpolation zone according to radii
    idx0 = Rwr<=rmax & Rwr>=rmin; % choose the interpolation zone according to radii (modified by Y.Chen 2018.12.05)
    
    % ------ Interpolation
    unwrapped_compl = [unwrapped(:,:,i),unwrapped(:,1,i)];    % correspond to the "complete" sinusoidal period (2pi)
    if islogical(unwrapped)
        idx1 = uint8(interpn(Ruw,Thetauw,single(unwrapped_compl),Rwr(idx0),Thetawr(idx0),InterpMethod)); %NaN's cannot be converted to logicals
        wrappedSL(idx0) = logical(idx1);
    elseif isa(unwrapped,'uint8')
        wrappedSL(idx0) = uint8(interpn(Ruw,Thetauw,single(unwrapped_compl),Rwr(idx0),Thetawr(idx0),InterpMethod));
    elseif isa(unwrapped,'uint16')
        wrappedSL(idx0) = uint16(interpn(Ruw,Thetauw,single(unwrapped_compl),Rwr(idx0),Thetawr(idx0),InterpMethod));
    elseif isa(unwrapped,'uint32')
        wrappedSL(idx0) = uint32(interpn(Ruw,Thetauw,single(unwrapped_compl),Rwr(idx0),Thetawr(idx0),InterpMethod));
    elseif isa(unwrapped,'uint64')
        wrappedSL(idx0) = uint64(interpn(Ruw,Thetauw,single(unwrapped_compl),Rwr(idx0),Thetawr(idx0),InterpMethod));
    else 
        wrappedSL(idx0) = interpn(Ruw,Thetauw,single(unwrapped_compl),Rwr(idx0),Thetawr(idx0),InterpMethod);
    end
    %wrapped(:,:,i) = transpose(wrappedSL);
    wrapped(:,:,i) = wrappedSL; %modified by Y.CHEN 2018.12.05
end


end



%%%
%%% ParseInputs
%%%
function [p1, p2, p3] = ParseInputs(varargin)

p1 = varargin{1};
% default
p2   = [];
p3   = [];

% Check the number of input arguments.
narginchk(1,3);

% Determine the type from the number of input arguments.

switch nargin   
    case 3
       p2 = varargin{2};
       p3 = varargin{3};
end

end
