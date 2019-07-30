% create the standard grid --------------------------------------------------------%





load(fullfile(ft_path,  'template','headmodel','standard_singleshell.mat'));

vol = ft_convert_units(vol, 'mm');



%%

% now prepare the standard grid (the virtual electrode positions) for all

% future analysis

cfg = [];

cfg.grid.xgrid  = -200:10:200;

cfg.grid.ygrid  = -200:10:200;

cfg.grid.zgrid  = -200:10:200;

cfg.grid.unit   = 'mm';

cfg.grid.tight  = 'yes';

cfg.inwardshift = 6;

cfg.vol        = vol;

template_grid  = ft_prepare_sourcemodel(cfg);

%% plot the 3 together



ft_plot_ortho(mri.anatomy, 'transform', mri.transform,'style', 'intersect');

ft_plot_mesh(vol.bnd, 'facealpha' , 0.2);

ft_plot_mesh(template_grid.pos(template_grid.inside,:), 'vertexcolor', [1 0 0]);





% ------------------------ this is optional (call ft_headmovement for n_trials/10 clusters

cfg = []; cfg.trl = trl; % trl defining only the trials I use in this contrast (e. . Hits and misses at retrieval after preprocessing)

cfg.dataset = filename_of_dataset;

cfg.numclusters = ceil(size(trl,1)/10);

cfg.feedback = 'no';

grad = ft_headmovement(cfg);



% ------------------------ this is to denoise the data and get the updated grad (check that the grad.tra is to get the correct LF later)

data.grad = grad;

cfg = []; cfg.gradient = 'G3BR';

data = ft_denoise_synthetic(cfg, data);

grad = data.grad;



% ------------------------ now load the template grid (MNI space) and the individual volume conduction model and aligned mri



load([base_ filesep 'data_NOT_MEG' filesep 'templates' filesep 'template_grid.mat']) %template



load('vol.mat'); %individual vol

load('aligned_mri.mat'); %individual mri



mri.coordsys = 'ctf';



%this is the important bit that will do all the inverse warping etc…

cfg = [];

cfg.grid.warpmni   = 'yes';

cfg.grid.template  = template_grid;

fg.grid.nonlinear = 'yes'; % use non-linear normalization

cfg.mri            = mri;

cfg.grid.unit = 'mm';

grid = ft_prepare_sourcemodel(cfg);





%% check

%     ft_plot_mesh(grid.pos(grid.inside,:))

%     hold on ;

%     ft_plot_mesh(vol.bnd(1));

%%

%     computing the leadfield is somehow done again later in ft_sourceanalysis. I kept this line of code anyway because this is how it is done in the tutorials and it might work smoothly with the new FT version..in my opinion it is a bug that this is % % called again later from within the function.

cfg                  = [];

cfg.grad             = grad;  % gradiometer distances

cfg.vol              = vol;   % volume conduction headmodel

cfg.grid             = grid;  % normalized grid positions

cfg.channel          = labels;

lf                   = ft_prepare_leadfield(cfg);



%% ----------------------------- from here on: lcmv



cfg = [];

cfg.demean = 'yes';

cfg.bpfilter = 'yes';

cfg.bpfreq = [4 15]; % bp in the range of interest

data = ft_preprocessing(cfg, data);



cfg                  = [];

cfg.covariance       = 'yes';

cfg.covariancewindow = 'all';

cfg.vartrllength     = 2;

timelock             = ft_timelockanalysis(cfg, data);





%% get the filters

timelock.grad = grad;

cfg              = [];

cfg.method       = 'lcmv';

cfg.latency = [-1 7];

cfg.lcmv.keepfilter = 'yes';

cfg.grid         = lf; % the individual grid with leadfield (which is however computed again…)

cfg.headmodel    = vol;

cfg.lcmv.fixedori = 'yes';

cfg.lcmv.lambda       = 1;

source_all= ft_sourceanalysis(cfg, timelock);





filtermat =  cell2mat(source_all.avg.filter(rois{rr})); % roi will be source.inside for all data



source            = [];

source.sampleinfo = data.sampleinfo; % transfer sample information

source.time       = data.time;       % transfer time information

source.trialinfo  = data.trialinfo;  % transfer trial information

source.fsample    = data.fsample;             % set sampling rate



% create labels for each virtual electrode

label = {};

for cc = 1 : numel(rois{rr}); label{cc,1} = ['S' num2str(cc)]; end

source.label = label;

% for each trial, apply filters to the recorded data

for jj = 1 : numel(data.trial); source.trial{1,jj} = filtermat*data.trial{1,jj}; end



% then the data is in source space… FIN











