function [VOL0uw,rmin,rmax] = UnWrap2(VOL0,Ri0,Re0,marg,O0,method)
%Calculate the image projection in plane from cylindric via interpolation 2D
%   1. identify the tube materal region for each slice
%   2. define a unwrapped plane mesh
%   3. interpolate 2D (slice per slice)
%
%   [VOL0uw,rmin,rmax] = UnWrap2(VOL0,Ri0,Re0,marg,O0,method)
%
%  Inputs:
%       - VOL0: images in volume
%       - [Ri0,Re0]: Tube's internal and external radius (scalar or vector)
%       - marg: vector(2x1), margins to reserve for the internal and external edges
%       - O0: the centres of each slice-tube circle (dim:[nz x 2])
%       - method: 2D interpolation method
%                 ("linear","nearest","pchip","cubic","spline", see help interp2) 
%  Outputs:
%       - VOL0uw: unwrapped plane volume

dr = 1 ;

fprintf('unwrapping the tube into a plate...\n');
nz = size(VOL0,3);

% Identify the tube material region
rmin = mean(Ri0) - marg(1);
rmax = mean(Re0) + marg(2);


% Define a unwrapped plane mesh
dtheta = dr / rmax;
theta = [0:dtheta:2*pi-dtheta];
r=[rmin:dr:rmax];
[R,Theta] = ndgrid(r,theta);
Xuw = R.*cos(Theta);
Yuw = R.*sin(Theta);

if islogical(VOL0)
    VOL0uw = false(size(Xuw,1),size(Xuw,2),nz);
else
    VOL0uw = zeros(size(Xuw,1),size(Xuw,2),nz,class(VOL0));
end

% Interpolate 2D (slice per slice)
for i=1:1:nz
%     disp(i);
    SL0wr=VOL0(:,:,i);
    X = Xuw + O0(i,1);
    Y = Yuw + O0(i,2);
    if islogical(VOL0)
        tmp=interp2(single(SL0wr),X,Y,method);
        VOL0uw(:,:,i) = tmp>0;
    elseif isa(VOL0,'uint8')
        VOL0uw(:,:,i) = uint8(interp2(single(SL0wr),X,Y,method));
    elseif isa(VOL0,'uint16')
        VOL0uw(:,:,i) = uint16(interp2(single(SL0wr),X,Y,method));
    elseif isa(VOL0,'uint32')
        VOL0uw(:,:,i) = uint32(interp2(single(SL0wr),X,Y,method));
    elseif isa(VOL0,'uint64')
        VOL0uw(:,:,i) = uint64(interp2(single(SL0wr),X,Y,method));
    else
        VOL0uw(:,:,i) = interp2(single(SL0wr),X,Y,method);
    end
end


end

