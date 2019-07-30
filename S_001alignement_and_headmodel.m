clear;clc
restoredefaultpath;
if ispc
    addpath(['C:\toolbox\fieldtrip-20170216\fieldtrip-20170216']);
else
    tmp = dir(['~' filesep 'tools' filesep 'fieldtrip']);
    addpath(['~' filesep 'tools' filesep 'fieldtrip' filesep tmp(3).name]);
end

ft_defaults;
%%
sj = 24;
if ispc    
    base_ = ['Z:' filesep 'Sebastian' filesep 'project_meg_movie_sequences'];    
else    
    base_ = [filesep 'media' filesep 'sxm1085' filesep 'rds-share-01' filesep 'Sebastian' filesep 'project_meg_movie_sequences'];  
end
cd([base_ filesep 'data_NOT_MEG' filesep 'sj' sprintf('%02d', sj) filesep 'MRI']);

save_path_ = [base_ filesep 'data_NOT_MEG' filesep 'sj' sprintf('%02d', sj) filesep 'MRI'];
%% REad and plot first

hs = ft_read_headshape(['hs_sj' sprintf('%02d', sj) '.pos']);
if exist(['msj' sprintf('%02d', sj) '.nii'])
     mri = ft_read_mri(['msj' sprintf('%02d', sj) '.nii']);
     mri_uncorr = ft_read_mri(['sj' sprintf('%02d', sj) '.nii']);
else
    mri = ft_read_mri(['sj' sprintf('%02d', sj) '.nii']);
end
% mri2 = ft_read_mri('C:\toolbox\fieldtrip-20160926\template\anatomy\single_subj_T1_1mm.nii');
% mri = ft_volumerealign([], mri, mri2);
% 
% mri = ft_volumereslice([],mri);
% hs.pos(hs.pos(:,1)<-10,:) = []; % sj 23
hs_plot = ft_convert_units(hs, 'mm');
ft_plot_headshape(hs_plot); %hold on;
figure;
ft_plot_ortho(mri.anatomy, 'style', 'intersect', 'transform', mri.transform);

%% first segment the raw mri (we only need the brain)
cfg = [];
cfg.output = {'brain'};
segmentedmri = ft_volumesegment(cfg, mri);
%% plot again in 2 figures to check
figure
ft_plot_ortho(mri.anatomy, 'style', 'intersect', 'tranform', mri.transform); 

figure;
ft_plot_ortho(segmentedmri.brain, 'style', 'intersect');
%% first manually rotate and translate to help the icp algorithm. After that ICP is always run

cfg=[];
cfg.method         = 'headshape';
cfg.headshape.headshape      = hs;
cfg.coordsys = 'ctf';
cfg.headshape.interactive    = 'yes';
%   cfg.headshape.scalpsmooth    = scalar, smoothing parameter for the scalp
%                                  extraction (default = 2)
%   cfg.headshape.scalpthreshold = scalar, threshold parameter for the scalp
%                                  extraction (default = 0.1)
%   cfg.headshape.interactive    = 'yes' or 'no', use interactive realignment to
%                                  align headshape with scalp surface (default =
%                                  'yes')
%   cfg.headshape.icp            = 'yes' or 'no', use automatic realignment
%                                  based on the icp-algorithm. If both 'interactive'
%                                  and 'icp' are executed, the icp step follows the
%                                  interactive realignment step (default = 'yes')
mri2 = ft_volumerealign(cfg, mri);
%% check again. Because of the distance to the scalp introduced by hair ...
% and the EEG cap, sometimes it is necessary to rotate a bit so the nose comes down
 cfg.headshape.icp            = 'no';
mri = ft_volumerealign(cfg, mri2);
% mri = mri2;
aligned_mri = mri;
save aligned_mri mri


%% now overwrite the transform of the segmentation and prepare the vol
segmentedmri.transform = mri.transform;
cfg = [];
cfg.method='singleshell';
vol = ft_prepare_headmodel(cfg, segmentedmri);
close all
 %note: the vol is now in headspace and doesn't have a transform anymore.
ft_plot_vol(vol)
save vol vol;
save segmentedmri segmentedmri;
%%
load('aligned_mri.mat');
load('vol.mat');
figure;
ft_plot_mesh(vol.bnd(1), 'facecolor', 'r');
hold on;
ft_plot_ortho(mri.anatomy,'transform',mri.transform,'style','intersect')

% also read the sensors to plot everything together
 listing = dir([base_ filesep 'data_NOT_MEG' filesep 'sj' sprintf('%02d', sj) filesep 'MEG' filesep 'raw']);
    filenames  ={listing.name}';
    filenames = filenames(cell2mat(cellfun(@(x) ~isempty(strfind(x, '.ds')), ...
        filenames,'UniformOutput', false)));
    cd([base_ filesep 'data_NOT_MEG' filesep 'sj' sprintf('%02d', sj) filesep 'MEG' filesep 'raw']);

sens = ft_read_sens(filenames{end});
% sensors should be in mm too...
sens = ft_convert_units(sens,'mm');

hold on;
ft_plot_sens(sens, 'style', '*b', 'facecolor' , 'y', 'facealpha' , 0.5);
view(25, 10)
set(gcf, 'color', 'w')
saveas(gcf, 'position_in_dewar.png');
%% this is for later:
% to go back  and control the alignment of the MRI:
clear all;

sj = 24;
if ispc    
    base_ = ['Z:' filesep 'Sebastian' filesep 'project_meg_movie_sequences'];    
else    
    base_ = [filesep 'media' filesep 'sxm1085' filesep 'rds-share-01' filesep 'Sebastian' filesep 'project_meg_movie_sequences'];  
end
cd([base_ filesep 'data_NOT_MEG' filesep 'sj' sprintf('%02d', sj) filesep 'MRI']);

load('aligned_mri.mat');
hs = ft_read_headshape(['hs_sj' sprintf('%02d', sj) '.pos']);
%
cfg.method         = 'headshape';
cfg.headshape.headshape      = hs;
cfg.coordsys = 'ctf';
cfg.headshape.interactive    = 'yes';
cfg.headshape.icp            = 'no';
[~] = ft_volumerealign(cfg, mri); 
