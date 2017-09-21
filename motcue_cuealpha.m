
motcue_init
cd(mdir)

%%
subuse=[3:23];

plotflag=1;

sub_locue=[nan 21 21 21 21  21 22 21 21 22  22 22 22 22 21  21 21 21 21 22  22 22 21];
sub_hicue=[nan 22 22 22 22  22 21 22 22 21  21 21 21 21 22  22 22 22 22 21  21 21 22];


%%

for ii=subuse % not parfor (too much RAM)
  clearvars -except ii sub* avcue* *dir *flag
  
  if 0 % artifact removal
    if ~exist(eogartifact,'file')
      motcue_eog;
    end
    if ~exist(muscleartifact,'file')
      motcue_muscle;
    end
    
    % jump
    cfg                    = [];
    cfg.trl = trl;
    cfg.datafile   = 'ArtifactMEG.ds';
    cfg.headerfile = 'ArtifactMEG.ds';
    cfg.continuous = 'yes';
    
    % channel selection, cutoff and padding
    cfg.artfctdef.zvalue.channel    = 'MEG';
    cfg.artfctdef.zvalue.cutoff     = 20;
    cfg.artfctdef.zvalue.trlpadding = 0;
    cfg.artfctdef.zvalue.artpadding = 0;
    cfg.artfctdef.zvalue.fltpadding = 0;
    
    % algorithmic parameters
    cfg.artfctdef.zvalue.cumulative    = 'yes';
    cfg.artfctdef.zvalue.medianfilter  = 'yes';
    cfg.artfctdef.zvalue.medianfiltord = 9;
    cfg.artfctdef.zvalue.absdiff       = 'yes';
    
    % make the process interactive
    cfg.artfctdef.zvalue.interactive = 'yes';
    
    [cfg, artifact_jump] = ft_artifact_zvalue(cfg);
  end
  
  % datanames=dir([volnum{ii} '*']);
  % datanames=dir([sub{ii} '/' volnum{ii} '*']);
  datanames=dir([sub{ii} '/*.ds']);
  
  for ff=1:length(avcuedata{ii}) % parfor on cluster
    
    % cfg=[];
    % cfg.dataset=datanames(ff).name;
    % raw_hpf{ff}=ft_preprocessing(cfg);
    % % raw_hpf.hdr.orig.hist(68:84) % date/time stamp
    
    % cfg=[];
    % cfg.dataset=datanames(ff).name;
    % event=ft_read_event(cfg.dataset);
    
    cfg=[];
    cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
    cfg.trialfun='ft_trialfun_general';
    % cfg.trialdef.eventtype  = '?';
    cfg.trialdef.eventtype  = 'UPPT002';
    cfg.trialdef.eventvalue = {21 22}; % This means cue value
    cfg.trialdef.prestim = 1;
    cfg.trialdef.poststim = 2;
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
    % cfg.reref='yes';
    % cfg.refchannel='all'; % used linked-mastoids for sleep staging but use average reference for ERPs and TFRs and source localisation
    raw_hpf=ft_preprocessing(cfg);
    
    % get responses
    event_meg = ft_read_event(cfg.dataset);
    event_resp = event_meg(strcmp('UPPT001', {event_meg.type}));
    event_stim = event_meg(strcmp('UPPT002', {event_meg.type}));
    
    cfg=[];
    cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
    cfg.channel={'UADC*' };
    eyechan=ft_preprocessing(cfg);
    
    cfg=[];
    cfg.trl=cfgtr.trl;
    raw_cue=ft_redefinetrial(cfg,raw_hpf);
    eye_cue=ft_redefinetrial(cfg,eyechan);
    
    clear raw_hpf eyechan
    
    cfg=[];
    megeye_cue=ft_appenddata(cfg,raw_cue,eye_cue);
    clear raw_cue eye_cue
    
    % cfg=[];
    % cfg.channel='MEG';
    % megchan=ft_selectdata(cfg,raw_hpf);
    % cfg=[];
    % cfg.hpfilter='yes';
    % cfg.hpfreq=1;
    % megchan_hpf=ft_preprocessing(cfg,megchan);
    %   end
    
    %%
    
    % For MEG sensor data, ft_megplanar must be done on each run
    cfg                  = [];
    cfg.method           = 'template';
    cfg.planarmethod     = 'sincos';
    cfg.channel          = {'MEG'};
    %   cfg.neighbours       = ft_prepare_neighbours(cfg, megeye_cue{l});
    cfg.neighbours       = ft_prepare_neighbours(cfg, megeye_cue);
    %   for ff=1:length(megeye_cue)
    megeye_cue_planar=ft_megplanar(cfg,megeye_cue);
    %   end
    %     raw_locue_all_planar = ft_megplanar(cfg,raw_locue_all);
    %   raw_hicue_all_planar = ft_megplanar(cfg,raw_hicue_all);
    %   megeye_cue_planar_all=ft_appenddata([],megeye_cue_planar{:});
    %   clear megeye_cue_planar
    
    %   megeye_cue_all=ft_appenddata([],megeye_cue{:});
    clear megeye_cue
    
    cfg=[];
    cfg.trials=megeye_cue_planar.trialinfo==sub_locue(ii);
    raw_locue=ft_selectdata(cfg,megeye_cue_planar);
    cfg=[];
    cfg.trials=megeye_cue_planar.trialinfo==sub_hicue(ii);
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
  
end % ii

return

%% Summary over group
clearvars -except *dir sub

subuse=[2:3 5:12]; % 1 had many eyeblinks just before cue;

for ii=1:length(subuse)
  load([edir sub{subuse(ii)} '_freq.mat'])
  freq_diff_each{ii}=freq_diff;
  freq_locue_each{ii}=freq_locue;
  freq_hicue_each{ii}=freq_hicue;
end

cfg=[];
grave_freqdiff=ft_freqgrandaverage(cfg,freq_diff_each{:});
cfg=[];
cfg.keepindividual='yes';
grind_freqdiff=ft_freqgrandaverage(cfg,freq_diff_each{:});
grind_freq_locue=ft_freqgrandaverage(cfg,freq_locue_each{:});
grind_freq_hicue=ft_freqgrandaverage(cfg,freq_hicue_each{:});

% redo tftimwin; baseline relchange prior to grandaverage?

figure;
cfg=[];
cfg.layout='elec1010.lay';
cfg.zlim='maxabs';
ft_multiplotTFR(cfg,grave_freqdiff)

load eeg1010_neighb

cfg=[];
cfg.latency=[.5 1];
cfg.freq=[8 12];
cfg.avgovertime='yes';
cfg.avgoverfreq='yes';
cfg.method='montecarlo';
cfg.correcttail='alpha';
cfg.design(1,:)=[1:10 1:10];
cfg.design(2,:)=[ones(1,10) 2*ones(1,10)];
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
cfg.layout='eeg1010.lay';
cfg.highlight='on';
cfg.highlightchannel=stat.label(stat.prob<.08);
ft_topoplotTFR(cfg,grave_plot);

