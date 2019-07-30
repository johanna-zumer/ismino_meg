
motcue_init
cd(sdir);
iiuse=3:23;
ii=3;
%%

cd([sdir sub{ii} ])

dircon=dir('*');
clear mriname
for dd=3:length(dircon),
  if dircon(dd).isdir
    dirmri=dir(dircon(dd).name);
    for dm=3:length(dirmri)
      if ~isempty(strfind(dirmri(dm).name,'nii'))
        if exist('mriname','var')
          disp('help 2 MRIs'); keyboard
        end
        mriname=[sdir sub{ii} filesep dircon(dd).name filesep dirmri(dm).name];
      end
    end
  end
end
dirpol=dir([pdir sub{ii}]);

mri=ft_read_mri(mriname);
polshape = ft_read_headshape([pdir sub{ii} filesep dirpol(3).name],'unit','mm');

% mri = ft_determine_coordsys(mri, 'interactive', 'yes');
% % ft_plot_headshape(polshape); %hold on;
% % figure;
% % ft_plot_ortho(mri.anatomy, 'style', 'intersect', 'transform', mri.transform);
% %
% 
%   cfg          = [];
%   cfg.method   = 'interactive';
%   cfg.coordsys = 'ctf';
%   mri_ctf_rs   = ft_volumerealign(cfg, mri);
% %   % transform_vox2ctf = mri_ctf_rs.transform;
% 
% ft_interactiverealign % is called within ft_interactiverealign

% First, get roughly in line with fiducial points
cfg          = [];
cfg.method   = 'interactive';
cfg.coordsys = 'ctf';
mri_fid   = ft_volumerealign(cfg, mri);

% First step does actual ICP realignment
cfg          = [];
cfg.method   = 'headshape';
cfg.coordsys = 'ctf';
cfg.headshape.headshape = polshape;
cfg.headshape.icp            = 'yes';
cfg.headshape.interactive    = 'no';
mri_pol   = ft_volumerealign(cfg, mri_fid);
transform_vox2ctf = mri_pol.transform;

% Second step just for visualisation (no need to interact if all looks okay)
cfg          = [];
cfg.method   = 'headshape';
cfg.coordsys = 'ctf';
cfg.headshape.headshape = polshape;
cfg.headshape.icp            = 'no';
cfg.headshape.interactive    = 'yes';
mri_tmp   = ft_volumerealign(cfg, mri_pol);

if 0
  addpath('D:/Matlab/nottingham/Coregister/')
  [transfidpoints,R12_final,T1_final,T2_final,fidfilename]=lucky_coreg([sdir '06275\becky.shape'],[pdir '06275_100.pos']);
  % compare FT vs NT
end

save('mri_pol.mat','mri_pol');

cfg = [];
cfg.output = {'brain', 'skull', 'scalp'};
% segmentedmri = ft_volumesegment(cfg, mri);
segmentedmri_pol = ft_volumesegment(cfg, mri_pol);

cfg = [];
cfg.tissue = {'skull', 'brain'};
cfg.spmversion = 'spm8';
cfg.numvertices = [1000 1000 1000];
mesh = ft_prepare_mesh(cfg, segmentedmri_pol);

cfg = [];
cfg.method='singleshell';
vol = ft_prepare_headmodel(cfg, segmentedmri_pol);

ft_plot_vol(vol);hold on;ft_plot_mesh(mesh(2));alpha 0.3 % brain
ft_plot_vol(vol);hold on;ft_plot_mesh(mesh(1));alpha 0.3 % skull

% cfg = [];
% cfg.anaparameter='brain';
% cfg.anaparameter='skull';
% ft_sourceplot(cfg, segmentedmri_pol);

close all
%note: the vol is now in headspace and doesn't have a transform anymore.
ft_plot_vol(vol);hold on;
ft_plot_headshape(polshape);hold on;
ft_plot_mesh(mesh(1))
figure;ft_plot_mesh(mesh(2));hold on;ft_plot_headshape(polshape)
save('vol.mat','vol');
save('segmentedmri.mat','segmentedmri_pol');


% cfg = [];
% figure;ft_sourceplot(cfg, mri);
% figure;ft_sourceplot(cfg, mri_pol);
%
% cfg           = [];
% cfg.output    = {'brain', 'scalp'};
% cfg.spmversion= 'spm8';
% segmentedmri_ctf_rs  = ft_volumesegment(cfg, mri_ctf_rs);
% % segmentedmri_spm  = ft_volumesegment(cfg, mri_spm);

% cfg = [];
% cfg.tissue = {'scalp', 'brain'};
% cfg.spmversion = 'spm8';
% cfg.numvertices = [1000 1000];
% mesh = ft_prepare_mesh(cfg, segmentedmri_ctf_rs);

% cfg = [];
% cfg.anaparameter='brain';
% cfg.anaparameter='scalp';
% ft_sourceplot(cfg, segmentedmri_ctf_rs);

% cfg = [];
% cfg.method = 'singleshell';
% headmodel = ft_prepare_headmodel(cfg, segmentedmri_ctf_rs);

% cfg = [];
% cfg.method         = 'surface';
% cfg.anaparameter='brain';
% ft_sourceplot(cfg, segmentedmri_ctf_rs);
%%
cd([sdir sub{ii}])
load('mri_pol.mat');
mri=mri_pol;clear mri_pol
load('vol.mat');
datanames=dir([mdir sub{ii} '/*.ds']);
dsnames={datanames(avcuedata{ii}).name};
for dd=1:length(dsnames),
  sens{dd} = ft_convert_units(ft_read_sens([mdir sub{ii} filesep dsnames{dd}],'senstype','meg'),'mm');
  
  figure;
  ft_plot_mesh(vol.bnd(1), 'facecolor', 'r');
  hold on;
  ft_plot_ortho(mri.anatomy,'transform',mri.transform,'style','intersect')
  hold on;
  ft_plot_sens(sens{dd}, 'style', '*b', 'facecolor' , 'y', 'facealpha' , 0.5);
  view(25, 10)
  set(gcf, 'color', 'w')
  saveas(gcf, [sub{ii} 'session' num2str(dd) '_position_in_dewar.png']);

  
  figure;
  ft_plot_mesh(vol.bnd(1), 'facecolor', 'r');
  hold on;
  ft_plot_sens(sens{dd}, 'style', '*b', 'facecolor' , 'y', 'facealpha' , 0.5);
  view(25, 10)
  set(gcf, 'color', 'w')

end

% movie of head motion across runs
writerObj = VideoWriter([sub{ii} '_headmotion.avi']);
writerObj.FrameRate=1;
open(writerObj);
for dd=1:length(dsnames),
  thisimage = imread([sub{ii} 'session' num2str(dd) '_position_in_dewar.png']);
  writeVideo(writerObj, thisimage);
end
close(writerObj);

close all

% end  % ii

%% Realign/normalise individual MRI to standard template MNI
% for ii=iiuse
cd([sdir sub{ii} ])
try
  load mrinorm.mat
catch
  %     mri = ft_read_mri(mriname);
  load('mri_pol.mat');
  
  % We might want this if starting from 'mri' to get roughly in right place
  %     cfg=[];
  %     cfg.coordsys='ras';
  %     cfg.nonlinear='no';   %
  %     mrinormlin=ft_volumenormalise(cfg,mri_pol); % I've modified spm_defaults to expand .bb
  %     mrinormlin=ft_convert_units(mrinormlin,'mm');
  %
  %     % The above 'mrinormlin' should be considered subject-specific MRI (but
  %     % in Affine-coregistered to MNI space
  
  cfg=[];
  cfg.coordsys='ras';
  cfg.nonlinear='yes';
  cfg.spmversion='spm8';
  %       mrinormwarp=ft_volumenormalise(cfg,mri); % I've modified spm_defaults to expand .bb
  mrinormwarp=ft_volumenormalise(cfg,mri_pol); % I've modified spm_defaults to expand .bb
  %     mrinormwarp=ft_volumenormalise(cfg,mrinormlin); % I've modified spm_defaults to expand .bb
  mrinormwarp=ft_convert_units(mrinormwarp,'mm');
  save('mrinorm','mrinormwarp');
  %     save('mrinorm','mrinormlin','mrinormwarp');
  
  params=mrinormwarp.params;
  save('params_sn.mat','-struct','params'); % to be used later with John's Gems
end
% end

%% Get and use template grid, warped to individual MRI
% http://www.fieldtriptoolbox.org/tutorial/sourcemodel#subject-specific_grids_that_are_equivalent_across_subjects_in_normalized_space

load standard_sourcemodel3d5mm;
sourcemodel=ft_convert_units(sourcemodel,'mm');

if 0   % just to check how far out the 'outside' points are for standard
  volstandard=load('standard_singleshell.mat');
  volstandard.vol=ft_convert_units(volstandard.vol,'mm');
  figure; % plot standard vol
  ft_plot_mesh(volstandard.vol.bnd, 'edgecolor', 'none'); alpha 0.4;
  ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
end

% for ii=iiuse

cd([sdir sub{ii} ])
load vol
load('mrinorm');
load('mri_pol.mat');

figure; % plot skull boundary
ft_plot_mesh(vol.bnd, 'edgecolor', 'none'); alpha 0.4;
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));  % very wrong

%   gridman=sourcemodel;
%   gridman.pos = ft_warp_apply(inv(mrinormwarp.initial), ft_warp_apply(mrinormwarp.params, sourcemodel.pos, 'sn2individual'));
%   figure; % plot skull boundary
%   ft_plot_mesh(vol.bnd, 'edgecolor', 'none'); alpha 0.4;
%   ft_plot_mesh(gridman.pos(gridman.inside,:));  % slightly wrong


cfg = [];
cfg.grid.warpmni   = 'yes';
cfg.grid.template  = sourcemodel;
cfg.grid.nonlinear = 'yes'; % use non-linear normalization
cfg.grid.unit      = 'mm';
cfg.mri            = mri_pol;
grid               = ft_prepare_sourcemodel(cfg);

pos2mri             = ft_warp_apply(inv(mri_pol.transform), grid.pos);        % transform to MRI voxel coordinates
pos2mri             = round(pos2mri);
tmpinside              = getinside(pos2mri, segmentedmri_pol.brain);  % from inside ft_prepare_sourcemodel

grid.inside=tmpinside;

figure; % plot skull boundary
ft_plot_mesh(mesh(2), 'edgecolor', 'none'); alpha 0.4;
ft_plot_mesh(grid.pos(grid.inside,:)); alpha 0.4; % slightly wrong

keyboard
close all

save grid.mat grid

% end

% leadfield gets computed later, with final grad

