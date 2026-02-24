
%Adam Wright
%This puts the data into the format t,z,y,x -- if you array slice data(:,:)
%the format will the t,voxel #
function [data] = loadData(filename)
    data = squeeze(double(niftiread(filename)));
    dim = length(size(data));
    if dim == 4
        data = permute(data,[4 3 2 1]);
    elseif dim == 3
        data = permute(data,[3 2 1]);
    else
        error('Image input not 3 or 4 dimensions')
    end
end