function motcue_cuealpha(subind)

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
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
%   cfg.trialfun='ft_trialfun_general';
  cfg.trialfun='ft_trialfun_general_motcue';
  cfg.trialdef.eventtype  = 'UPPT002';
  cfg.trialdef.eventvalue = {21 22}; % This means cue value
  cfg.trialdef.prestim = 1.1;
  cfg.trialdef.poststim = 2.1;
  cfgtr=ft_definetrial(cfg);
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
  cfg.demean='yes';
  cfg.bsfilter='yes';
  cfg.bsfreq=[49 51; 99 101; 149 151];
  cfg.hpfilter='yes';
  cfg.hpfiltord=3;
  cfg.hpfreq=0.2;  % Could do higher for awake data but not want higher for sleep.
  cfg.channel={'MEG' };
  raw_hpf=ft_preprocessing(cfg);
  
  % get responses
  if 0
    event_meg = ft_read_event(cfg.dataset);
    event_resp = event_meg(strcmp('UPPT001', {event_meg.type}));
    event_stim = event_meg(strcmp('UPPT002', {event_meg.type}));
  end
  
  cfg=[];
  cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
  cfg.trl=cfgtr.trl;
  eye_adc_shift=motcue_loadshift_adc(cfg);
  
  cfg=[];
  cfg.trl=cfgtr.trl;
  raw_cue=ft_redefinetrial(cfg,raw_hpf);
  
  cfg=[];
  cfg.latency=[-1 2]; % these numbers should match EL file loading below
  raw_cue=ft_selectdata(cfg,raw_cue);
  eye_adc_shift=ft_selectdata(cfg,eye_adc_shift);
  
  if max(eye_adc_shift.time{1}-raw_cue.time{1})<2*eps
    eye_adc_shift.time=raw_cue.time;
  else
    error('something gone wrong with data alignment')
  end
  
  clear raw_hpf
  %     clear eyechan eye_cue_orig
  
  cfg=[];
  cfg.appenddim='chan';
  megeye_cue=ft_appenddata(cfg,raw_cue,eye_adc_shift);
  clear raw_cue eye_adc_shift
  
  %% Artifact rejection
  visflag=0;
  data_out=motcue_artifact_all(megeye_cue,ii,ff,sub,adir,visflag);

end


  %%
  
  % For MEG sensor data, ft_megplanar must be done on each run
  cfg                  = [];
  cfg.method           = 'template';
  cfg.planarmethod     = 'sincos';
  cfg.channel          = {'MEG'};
  %   cfg.neighbours       = ft_prepare_neighbours(cfg, megeye_cue{l});
  cfg.neighbours       = ft_prepare_neighbours(cfg, megeye_use);
  %   for ff=1:length(megeye_cue)
  megeye_cue_planar=ft_megplanar(cfg,megeye_use);
  %   end
  %     raw_locue_all_planar = ft_megplanar(cfg,raw_locue_all);
  %   raw_hicue_all_planar = ft_megplanar(cfg,raw_hicue_all);
  %   megeye_cue_planar_all=ft_appenddata([],megeye_cue_planar{:});
  %   clear megeye_cue_planar
  
  %   megeye_cuee_all=ft_appenddata([],megeye_cue{:});
  clear megeye_cue megeye_use
  
  error('fix me: check if this mapping of cue value is correct');
  cfg=[];
%   cfg.trials=megeye_cue_planar.trialinfo==sub_locue(ii);
  cfg.trials=megeye_cue_planar.trialinfo==21;
  raw_locue=ft_selectdata(cfg,megeye_cue_planar);
  cfg=[];
%   cfg.trials=megeye_cue_planar.trialinfo==sub_hicue(ii);
  cfg.trials=megeye_cue_planar.trialinfo==22;
  raw_hicue=ft_selectdata(cfg,megeye_cue_planar);
  clear meg*planar
  
  cfg=[];
  cfg.method='mtmconvol';
  cfg.pad=4;
  cfg.foi=4:2:30;
  cfg.taper='hanning';
  cfg.toi=-0.8:.1:2.0;
  cfg.t_ftimwin=4./cfg.foi;
  cfg.output='pow';
  cfg.keeptrials='yes';
  freq_locue=ft_freqanalysis(cfg,raw_locue);
  freq_hicue=ft_freqanalysis(cfg,raw_hicue);
  clear raw_locue raw_hicue
  
  cfg               = [];
  cfg.combinemethod = 'sum';
  freq_lc_combpl{ff} = ft_combineplanar(cfg,freq_locue);
  freq_hc_combpl{ff} = ft_combineplanar(cfg,freq_hicue);
  clear freq_locue freq_hicue
  
end  % ff

cfg=[];
cfg.parameter='powspctrm';
cfg.appenddim='rpt';
freq_lc_combpl_all=ft_appendfreq(cfg,freq_lc_combpl{:});
freq_hc_combpl_all=ft_appendfreq(cfg,freq_hc_combpl{:});
clear freq_lc_combpl freq_hc_combpl

freq_lc_combpl_all_avg=ft_freqdescriptives([],freq_lc_combpl_all);
freq_hc_combpl_all_avg=ft_freqdescriptives([],freq_hc_combpl_all);
save([mdir sub{ii} '_freq.mat'],'freq*combpl_all')

cfg=[];
cfg.parameter='powspctrm';
cfg.operation='x1/x2 - 1';
freq_diff=ft_math(cfg,freq_lc_combpl_all_avg,freq_hc_combpl_all_avg);

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
  
  
  % Hypothesis:
  % hicue -> integrate -> low visual alpha power
  % locue -> aud only -> high visual alpha power
  % locue - hicue -> + visual alpha power
  
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

return

%% Summary over group
clearvars -except *dir sub


subcnt=0;
for ii=3:length(sub)
  subcnt=subcnt+1;
  load([mdir sub{ii} '_freq.mat'])
  freq_locue_each_unavg{subcnt}=freq_lc_combpl_all;
  freq_hicue_each_unavg{subcnt}=freq_hc_combpl_all;
  freq_locue_each_avg{subcnt}=ft_freqdescriptives([],freq_lc_combpl_all);
  freq_hicue_each_avg{subcnt}=ft_freqdescriptives([],freq_hc_combpl_all);
  cfg=[];
  cfg.parameter='powspctrm';
  cfg.operation='x1/x2 - 1';
  freq_diff_each{subcnt}=ft_math(cfg,freq_locue_each_avg{subcnt},freq_hicue_each_avg{subcnt});
end

cfg=[];
grave_freqdiff=ft_freqgrandaverage(cfg,freq_diff_each{:});
cfg=[];
cfg.keepindividual='yes';
grind_freqdiff=ft_freqgrandaverage(cfg,freq_diff_each{:});
grind_freq_locue=ft_freqgrandaverage(cfg,freq_locue_each_avg{:});
grind_freq_hicue=ft_freqgrandaverage(cfg,freq_hicue_each_avg{:});

% redo tftimwin; baseline relchange prior to grandaverage?

figure;
cfg=[];
cfg.layout='CTF275.lay';
cfg.zlim='maxabs';
ft_multiplotTFR(cfg,grave_freqdiff)

load ctf275_neighb.mat

cfg=[];
cfg.latency=[.5 1];
cfg.freq=[8 12];
cfg.avgovertime='yes';
cfg.avgoverfreq='yes';
cfg.method='montecarlo';
cfg.correcttail='alpha';
cfg.design(1,:)=[1:21 1:21];
cfg.design(2,:)=[ones(1,21) 2*ones(1,21)];
cfg.uvar=1;
cfg.ivar=2;
cfg.statistic='depsamplesT';
cfg.numrandomization=500;
cfg.correctm='cluster';
cfg.neighbours=neighbours;
stat=ft_freqstatistics(cfg,grind_freq_locue, grind_freq_hicue);

cfg=[];
cfg.latency=[.5 1];
cfg.frequency=[8 12];
cfg.avgoverfreq='yes';
cfg.avgovertime='yes';
grave_plot=ft_selectdata(cfg,grave_freqdiff)
grave_plot.mask=stat.mask;

figure;
cfg=[];
cfg.parameter='powspctrm';
% cfg.maskparameter='mask';
cfg.layout='CTF275.lay';
cfg.highlight='on';
cfg.highlightchannel=stat.label(stat.prob<.08);
ft_topoplotTFR(cfg,grave_plot);

