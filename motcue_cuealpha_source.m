function motcue_cuealpha_source(subind)

motcue_init
cd(mdir)
plotflag=0;


% motcue_mriheadmodels will already be run.

% for participant with cueord=[1 2] , trigger 21 means 400Hz; locue
% for participant with cueord=[2 1] , trigger 21 means 1600Hz; locue
sub_locue=[nan 21 21 21 21  21 22 21 21 22  22 22 22 22 21  21 21 21 21 22  22 22 21];
sub_hicue=[nan 22 22 22 22  22 21 22 22 21  21 21 21 21 22  22 22 22 22 21  21 21 22];

%%


ii=subind;
datanames=dir([mdir sub{ii} '/*.ds']);
dsnames={datanames(avcuedata{ii}).name};


for ff=1:length(avcuedata{ii}) % parfor on cluster
  
  jrval='run'; % 'run' if make new params, or 'load' old results
  brval='run'; % 'run' if make new params, or 'load' old results
  brdo= 0; % =0 if don't actually remove blinks, =1 yes replace blink with nan
  %   brzvalue='sensor_old';
  %   brzvalue='source1';r
  visflag=0;  % = 0 load previous vis-inspected artfct; = 1 'interactive'
  reply='y'; % =[] (empty); ask!;  = 'y' yes run ft_headmovement;   = 'n' (don't)
  motcue_load_preproc4sourceloc % output is megeye_br for each ii,ff
  
  
  megrun{ff}=megeye_br;
  clear megeye_br
  
  %   % http://www.fieldtriptoolbox.org/reference/ft_headmovement
  %     cfg=[];
  %     cfg.dataset      = [mdir sub{ii} filesep dsnames{dd}];
  %     cfg.trl          = cfgtr.trl(:,1:3);  % FIXME: Or do we want this to be after artifact rejection???
  %     cfg.numclusters  = 10;
  %     grad = ft_headmovement(cfg);
  
  %     data.grad = grad;  % this needs to be once have proper data loaded.
  %     cfg = [];
  %     cfg.gradient = 'G3BR';
  %     data = ft_denoise_synthetic(cfg, data);
  %     grad = data.grad;
  
  
end % ff


%% 
cfg=[];
% cfg.parameter='trial';
% cfg.appenddim='rpt';
meg_all=ft_appenddata(cfg,megrun{:});
graduse=input('Which run to use for grad? ');
grad=megrun{graduse}.grad;
save([sdir sub{ii} filesep 'grad.mat'],'grad');
clear megrun


meg_all=rmfield(meg_all,'elec');

% TF
cfg=[];
%   cfg.trials=megeye_cue_planar.trialinfo==sub_locue(ii);
cfg.trials=meg_all.trialinfo==21;
run_locue=ft_selectdata(cfg,meg_all);
cfg=[];
%   cfg.trials=megeye_cue_planar.trialinfo==sub_hicue(ii);
cfg.trials=meg_all.trialinfo==22;
run_hicue=ft_selectdata(cfg,meg_all);


cfg.trials=find(meg_all.trialinfo(:,5)==1 & meg_all.trialinfo(:,6)==0);
run_respC_Inc=ft_selectdata(cfg,meg_all);
cfg.trials=find(meg_all.trialinfo(:,5)==0 & meg_all.trialinfo(:,6)==0);
run_respI_Inc=ft_selectdata(cfg,meg_all);

cfg=[];
cfg.method='mtmconvol';
cfg.pad=4;
cfg.foi=4:2:30;
cfg.taper='hanning';
cfg.toi=-0.8:.1:2.0;
cfg.t_ftimwin=4./cfg.foi;
cfg.output='powandcsd';
%   cfg.keeptrials='yes';  % can't for memory reasons.  what to do? run on cluster!
freq_all=ft_freqanalysis(cfg,meg_all);
clear meg_all
freq_locue=ft_freqanalysis(cfg,run_locue);
clear run_locue
freq_hicue=ft_freqanalysis(cfg,run_hicue);
clear raw_hicue
freq_respC_Inc=ft_freqanalysis(cfg,run_respC_Inc);
clear run_respC_Inc
freq_respI_Inc=ft_freqanalysis(cfg,run_respI_Inc);
clear run_respI_Inc


save([mdir sub{ii} '_freq4source.mat'],'freq_*cue','freq_*Inc');


% leadfield
load vol
load grid
cfg=[];
cfg.vol=vol;
cfg.grid=grid;
cfg.grad=ft_convert_units(freq_hicue{graduse}.grad,'mm');
cfg.channel='MEG';
lf=ft_prepare_leadfield(cfg);
save('lf.mat','lf');

try, freq_all=rmfield(freq_all,'elec');end
cfg              = [];
cfg.method       = 'dics';
cfg.grid.leadfield = lf;
cfg.reducerank = 2;
cfg.keepfilter = 'yes';
cfg.headmodel    = vol;
cfg.grad=grad;
cfg.latency=[0.6 1.3];
cfg.frequency=[8 12];
sourceall = ft_sourceanalysis(cfg, freq_all);

% cfg.latency = [-1 7];
% % cfg.grid         = lf; % the individual grid with leadfield (which is however computed again…)
% cfg.lcmv.fixedori = 'yes';
% cfg.lcmv.lambda       = 1;




