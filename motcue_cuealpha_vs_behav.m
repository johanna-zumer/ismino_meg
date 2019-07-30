function motcue_cuealpha_vs_behav(subind)

motcue_init
cd(mdir)
plotflag=0;

% for participant with cueord=[1 2] , trigger 21 means 400Hz; locue
% for participant with cueord=[2 1] , trigger 21 means 1600Hz; locue

sub_locue=[nan 21 21 21 21  21 22 21 21 22  22 22 22 22 21  21 21 21 21 22  22 22 21];
sub_hicue=[nan 22 22 22 22  22 21 22 22 21  21 21 21 21 22  22 22 22 22 21  21 21 22];


%%
ii=subind;
% for ii=subuse % not parfor (too much RAM)
%   clearvars -except ii sub* avcue* *dir *flag

% datanames=dir([volnum{ii} '*']);
% datanames=dir([sub{ii} '/' volnum{ii} '*']);
datanames=dir([sub{ii} '/*.ds']);

for ff=1:length(avcuedata{ii}) % parfor on cluster

  jrval='load'; % JUMP: 'run' if make new params, or 'load' old results
  brval='load'; % BLINK: 'run' if make new params, or 'load' old results
  visflag=0; % Final Visual inspection: =1 if view visually, =0 if load old results
  motcue_load_preproc % output is megeye_br for each ii,ff
  
%   %% Artifact rejection
%   megeye_cue=motcue_artifact_all(megeye_cue,ii,ff,sub,adir,visflag);

% end


  %%
  
  % For MEG sensor data, ft_megplanar must be done on each run
  cfg                  = [];
  cfg.method           = 'template';
  cfg.planarmethod     = 'sincos';
  cfg.channel          = {'MEG'};
  %   cfg.neighbours       = ft_prepare_neighbours(cfg, megeye_cue{l});
  cfg.neighbours       = ft_prepare_neighbours(cfg, megeye_br);
  %   for ff=1:length(megeye_cue)
  megeye_cue_planar=ft_megplanar(cfg,megeye_br);
  %   end
  %     raw_locue_all_planar = ft_megplanar(cfg,raw_locue_all);
  %   raw_hicue_all_planar = ft_megplanar(cfg,raw_hicue_all);
  %   megeye_cue_planar_all=ft_appenddata([],megeye_cue_planar{:});
  %   clear megeye_cue_planar
  
  %   megeye_cuee_all=ft_appenddata([],megeye_cue{:});
  clear megeye_cue megeye_use megeye_br
  
  cfg=[];
  cfg.method='mtmconvol';
  cfg.pad=4;
  cfg.foi=4:2:30;
  cfg.taper='hanning';
  cfg.toi=-0.8:.1:2.0;
  cfg.t_ftimwin=4./cfg.foi;
  cfg.output='pow';
  cfg.keeptrials='yes';
  freq_cueplanar=ft_freqanalysis(cfg,megeye_cue_planar);
  clear megeye_cue_planar
  
  cfg               = [];
  cfg.combinemethod = 'sum';
  freq_combpl{ff} = ft_combineplanar(cfg,freq_cueplanar);
  clear freq_cueplanar
  
end  % ff


cfg=[];
cfg.parameter='powspctrm';
cfg.appenddim='rpt';
freq_combpl_all=ft_appendfreq(cfg,freq_combpl{:});
clear freq_combpl

save([mdir sub{ii} '_freq_alltrials.mat'],'freq_combpl_all')

return


%% 

freq_combpl_all_avg=ft_freqdescriptives([],freq_combpl_all);

if plotflag
  % chanuse=match_str(freq_hicue.label,{'PO9' 'PO10' 'O1' 'O2' 'Oz' 'PO3' 'PO4' 'POz' 'PO7' 'PO8'});
  cfg=[];
  cfg.channel={'MLO' 'MRO' 'MZO'};
  cfg.avgoverchan='yes';
  %     freq_locue_occ=ft_selectdata(cfg,freq_locue);
  %     freq_hicue_occ=ft_selectdata(cfg,freq_hicue);
  freq_locue_occ=ft_selectdata(cfg,freq_lc_combpl_all_avg);
  freq_hicue_occ=ft_selectdata(cfg,freq_hc_combpl_all_avg);
  figure;plot(freq_locue_occ.time,[squeeze(mean(freq_locue_occ.powspctrm(1,3:5,:),2)) squeeze(mean(freq_hicue_occ.powspctrm(1,3:5,:),2))])
  legend({'High cue' 'Low cue'})
  %   figure;plot(freq_locue.time,[squeeze(mean(mean(freq_hicue.powspctrm(chanuse,3:5,:),1),2)) squeeze(mean(mean(freq_locue.powspctrm(chanuse,3:5,:),1),2))])
  
  
  % cfg=[];
  % cfg.layout='elec1010.lay';
  % cfg.baseline=[-0.5 0];
  % cfg.baselinetype='relchange';
  % cfg.zlim='maxabs';
  % ft_multiplotTFR(cfg,freq_locue)
  % ft_multiplotTFR(cfg,freq_hicue)
  figure
  cfg=[];
  cfg.layout='CTF275.lay';
  cfg.zlim='maxabs';
  ft_multiplotTFR(cfg,freq_diff)
end

if 0
  cfg=[];
  cfg.lpfilter='yes';
  cfg.lpfreq=40;
  cfg.demean='yes';
  cfg.baselinewindow=[-0.9 -0.4];
  cfg.baselinewindow=[-0.9 0.9];
  %   raw_cue_all_lpf=ft_preprocessing(cfg,megeye_cue_all);
  raw_cue_planar_lpf=ft_preprocessing(cfg,megeye_cue_planar_all);
  
  cfg=[];
  cfg.trials=megeye_cue_all.trialinfo==sub_locue(ii);
  %   raw_locue_all=ft_selectdata(cfg,megeye_cue_all);
  %   raw_locue_all_lpf=ft_selectdata(cfg,raw_cue_all_lpf);
  raw_locue_all=ft_selectdata(cfg,megeye_cue_planar_all);
  raw_locue_all_lpf=ft_selectdata(cfg,raw_cue_planar_lpf);
  cfg=[];
  cfg.trials=megeye_cue_all.trialinfo==sub_hicue(ii);
  %   raw_hicue_all=ft_selectdata(cfg,megeye_cue_all);
  %   raw_hicue_all_lpf=ft_selectdata(cfg,raw_cue_all_lpf);
  raw_hicue_all=ft_selectdata(cfg,megeye_cue_planar_all);
  raw_hicue_all_lpf=ft_selectdata(cfg,raw_cue_planar_lpf);
  
  cfg=[];
  tlock_locue=ft_timelockanalysis(cfg,raw_locue_all_lpf);
  tlock_hicue=ft_timelockanalysis(cfg,raw_hicue_all_lpf);
  
  
  if plotflag
    cfg=[];
    cfg.channel={'MLO*' 'MRO*' 'MZO*'};
    cfg.avgoverchan='yes';
    tlock_locue_occ=ft_selectdata(cfg,tlock_locue);
    tlock_hicue_occ=ft_selectdata(cfg,tlock_hicue);
    figure;plot(tlock_locue.time,[tlock_locue_occ.avg; tlock_hicue_occ.avg])
    
    cfg=[];
    cfg.channel={'MLT*' 'MRT*' };
    cfg.avgoverchan='yes';
    tlock_locue_tem=ft_selectdata(cfg,tlock_locue);
    tlock_hicue_tem=ft_selectdata(cfg,tlock_hicue);
    figure;plot(tlock_locue.time,[tlock_locue_tem.avg; tlock_hicue_tem.avg])
    
    %     figure;
    %     cfg=[];
    %     cfg.layout='CTF275.lay';
    %     cfg.interactive='yes';
    %     ft_multiplotER(cfg,tlock_locue,tlock_hicue);
  else
    %
    % figure('Visible','off');
    % plot(tlock_locue.time,[mean(tlock_locue.avg(56:64,:),1); mean(tlock_hicue.avg(56:64,:),1)])
    %
    % figure;
    % cfg=[];
    % cfg.layout='elec1010.lay';
    % cfg.interactive='yes';
    % ft_multiplotER(cfg,tlock_locue,tlock_hicue);
  end
  
  clear *lpf
  
  % e09 the alpha is perfectly out of phase between cue types!
end

% end % ii


%% Summary over group
clearvars -except *dir sub
  % .trialinfo has
  % [cue      aud_dir vis_dir/abs response    response_corr AVcongruent]
  % [21/22    31/32   41/42/40    1/2/3/8     0/1           0/1        ]
  % [lo/high  R/L     R/L/abs     Lc/Lu/Ru/Rc N/Y           N/Y        ]
  
  % Hypothesis:
  % hicue -> integrate -> low visual alpha power
  % locue -> aud only -> high visual alpha power
  % locue - hicue -> + visual alpha power
  
subcnt=0;
for ii=3:length(sub)
  subcnt=subcnt+1;
  load([mdir sub{ii} '_freq_alltrials.mat'])
  cfg=[];
  cfg.trials=find(freq_combpl_all.trialinfo(:,2)==31);
  freq_audLR=ft_selectdata(cfg,freq_combpl_all);
  cfg.trials=find(freq_combpl_all.trialinfo(:,2)==32);
  freq_audRL=ft_selectdata(cfg,freq_combpl_all);
  
  cfg.trials=find(freq_combpl_all.trialinfo(:,3)==41);
  freq_visLR=ft_selectdata(cfg,freq_combpl_all);
  cfg.trials=find(freq_combpl_all.trialinfo(:,3)==42);
  freq_visRL=ft_selectdata(cfg,freq_combpl_all);
  cfg.trials=find(freq_combpl_all.trialinfo(:,3)==40);
  freq_visNo=ft_selectdata(cfg,freq_combpl_all);

  cfg.trials=find(freq_combpl_all.trialinfo(:,5)==1);
  freq_respC=ft_selectdata(cfg,freq_combpl_all);
  cfg.trials=find(freq_combpl_all.trialinfo(:,5)==0);
  freq_respI=ft_selectdata(cfg,freq_combpl_all);

  cfg.trials=find(freq_combpl_all.trialinfo(:,5)==1 & freq_combpl_all.trialinfo(:,6)==0);
  freq_respC_Inc=ft_selectdata(cfg,freq_combpl_all);
  cfg.trials=find(freq_combpl_all.trialinfo(:,5)==0 & freq_combpl_all.trialinfo(:,6)==0);
  freq_respI_Inc=ft_selectdata(cfg,freq_combpl_all);
  
  cfg.trials=find(freq_combpl_all.trialinfo(:,6)==1);
  freq_avCon=ft_selectdata(cfg,freq_combpl_all);
  cfg.trials=find(freq_combpl_all.trialinfo(:,6)==0);
  freq_avInc=ft_selectdata(cfg,freq_combpl_all);
  
  freq_audLR_avg{subcnt}=ft_freqdescriptives([],freq_audLR);
  freq_audRL_avg{subcnt}=ft_freqdescriptives([],freq_audRL);
  freq_visLR_avg{subcnt}=ft_freqdescriptives([],freq_visLR);
  freq_visRL_avg{subcnt}=ft_freqdescriptives([],freq_visRL);
  freq_visNo_avg{subcnt}=ft_freqdescriptives([],freq_visNo);
  freq_respC_avg{subcnt}=ft_freqdescriptives([],freq_respC);
  freq_respI_avg{subcnt}=ft_freqdescriptives([],freq_respI);
  freq_respCinc_avg{subcnt}=ft_freqdescriptives([],freq_respC_Inc);
  freq_respIinc_avg{subcnt}=ft_freqdescriptives([],freq_respI_Inc);
  freq_avCon_avg{subcnt}=ft_freqdescriptives([],freq_avCon);
  freq_avInc_avg{subcnt}=ft_freqdescriptives([],freq_avInc);

  
  cfg=[];
  cfg.parameter='powspctrm';
  cfg.operation='x1/x2 - 1';
  freq_diff_aud{subcnt}=ft_math(cfg,freq_audLR_avg{subcnt},freq_audRL_avg{subcnt});
  freq_diff_vis{subcnt}=ft_math(cfg,freq_visLR_avg{subcnt},freq_visRL_avg{subcnt});
  freq_diff_res{subcnt}=ft_math(cfg,freq_respC_avg{subcnt},freq_respI_avg{subcnt});
  freq_diff_resI{subcnt}=ft_math(cfg,freq_respCinc_avg{subcnt},freq_respIinc_avg{subcnt});
  freq_diff_avc{subcnt}=ft_math(cfg,freq_avCon_avg{subcnt},freq_avInc_avg{subcnt});

  cfg.operation='add';
  freq_sum_aud{subcnt}=ft_math(cfg,freq_audLR_avg{subcnt},freq_audRL_avg{subcnt});
  freq_sum_vis{subcnt}=ft_math(cfg,freq_visLR_avg{subcnt},freq_visRL_avg{subcnt});
  freq_sum_res{subcnt}=ft_math(cfg,freq_respC_avg{subcnt},freq_respI_avg{subcnt});
  freq_sum_resI{subcnt}=ft_math(cfg,freq_respCinc_avg{subcnt},freq_respIinc_avg{subcnt});
  freq_sum_avc{subcnt}=ft_math(cfg,freq_avCon_avg{subcnt},freq_avInc_avg{subcnt});
end

% go through each subject;
for ii=1:length(freq_diff_aud)
  figure;
  cfg=[];
  cfg.layout='CTF275.lay';
  cfg.zlim='maxabs';
  ft_multiplotTFR(cfg,freq_diff_aud{ii})
  disp('freq_diff_aud')
  keyboard
end

%% 
subjkeep=setdiff(1:length(freq_sum_res),[1 13 16])

cfg=[];
grave_auddiff=ft_freqgrandaverage(cfg,freq_diff_aud{subjkeep});
grave_visdiff=ft_freqgrandaverage(cfg,freq_diff_vis{subjkeep});
grave_resdiff=ft_freqgrandaverage(cfg,freq_diff_res{subjkeep});
grave_resIdiff=ft_freqgrandaverage(cfg,freq_diff_resI{subjkeep});
grave_avcdiff=ft_freqgrandaverage(cfg,freq_diff_avc{subjkeep});
grave_audsum=ft_freqgrandaverage(cfg,freq_sum_aud{subjkeep});
grave_vissum=ft_freqgrandaverage(cfg,freq_sum_vis{subjkeep});
grave_ressum=ft_freqgrandaverage(cfg,freq_sum_res{subjkeep});
grave_resIsum=ft_freqgrandaverage(cfg,freq_sum_resI{subjkeep});
grave_avcsum=ft_freqgrandaverage(cfg,freq_sum_avc{subjkeep});

cfg=[];
cfg.keepindividual='yes';
grind_auddiff=ft_freqgrandaverage(cfg,freq_diff_aud{subjkeep});
grind_visdiff=ft_freqgrandaverage(cfg,freq_diff_vis{subjkeep});
grind_resdiff=ft_freqgrandaverage(cfg,freq_diff_res{subjkeep});
grind_resIdiff=ft_freqgrandaverage(cfg,freq_diff_resI{subjkeep});
grind_avcdiff=ft_freqgrandaverage(cfg,freq_diff_avc{subjkeep});

grind_audLR=ft_freqgrandaverage(cfg,freq_audLR_avg{subjkeep});
grind_audRL=ft_freqgrandaverage(cfg,freq_audRL_avg{subjkeep});
grind_visLR=ft_freqgrandaverage(cfg,freq_visLR_avg{subjkeep});
grind_visRL=ft_freqgrandaverage(cfg,freq_visRL_avg{subjkeep});
grind_respC=ft_freqgrandaverage(cfg,freq_respC_avg{subjkeep});
grind_respI=ft_freqgrandaverage(cfg,freq_respI_avg{subjkeep});
grind_respCinc=ft_freqgrandaverage(cfg,freq_respCinc_avg{subjkeep});
grind_respIinc=ft_freqgrandaverage(cfg,freq_respIinc_avg{subjkeep});
grind_avCon=ft_freqgrandaverage(cfg,freq_avCon_avg{subjkeep});
grind_avInc=ft_freqgrandaverage(cfg,freq_avInc_avg{subjkeep});


% cfg=[];
% cfg.layout='CTF275.lay';
% cfg.zlim='maxabs';
% figure;
% ft_multiplotTFR(cfg,grave_auddiff)
% figure;
% ft_multiplotTFR(cfg,grave_visdiff)
% figure;
% ft_multiplotTFR(cfg,grave_resdiff)
% figure;
% ft_multiplotTFR(cfg,grave_avcdiff)



% figure;
% cfg=[];
% cfg.layout='CTF275.lay';
% cfg.baseline=[-.3 .4];
% ft_multiplotTFR(cfg,grave_freqsum)


% redo tftimwin; baseline relchange prior to grandaverage?

load ctf275_neighb.mat


%% 
% % for grind_respC vs grind_respI
% cfg=[];  % BEST:  0.4-0.5 s at 18-24 Hz
% cfg.latency=[0.4 0.5];   % 0.2-0.6 and 8-28 Hz
% cfg.freq=[18 24];   % 0.9-1.0 at 8-12 and 20-28

cfg=[];  % BEST:  
cfg.latency=[0.4 0.5];   %
cfg.freq=[16 24];   % 
cfg.avgovertime='yes';
cfg.avgoverfreq='yes';
cfg.method='montecarlo';
cfg.correcttail='alpha';
cfg.design(1,:)=[1:length(subjkeep) 1:length(subjkeep)];
cfg.design(2,:)=[ones(1,length(subjkeep)) 2*ones(1,length(subjkeep))];
cfg.uvar=1;
cfg.ivar=2;
cfg.statistic='depsamplesT';
cfg.numrandomization=500;
cfg.correctm='cluster';
cfg.neighbours=neighbours;
stat=ft_freqstatistics(cfg,grind_respCinc, grind_respIinc);
min(stat.prob(:))

cfg=[];
cfg.latency=stat.cfg.latency;
cfg.frequency=stat.cfg.freq;
cfg.avgoverfreq='yes';
cfg.avgovertime='yes';
grave_plot=ft_selectdata(cfg,grave_resdiff)
grave_plot.mask=stat.mask;

figure;
cfg=[];
cfg.parameter='powspctrm';
% cfg.maskparameter='mask';
cfg.layout='CTF275.lay';
cfg.highlight='on';
cfg.highlightchannel=stat.label(min(min(stat.prob,[],3),[],2)<.05);
ft_topoplotTFR(cfg,grave_plot);

