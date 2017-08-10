function motcue_eeg_read

clear all
close all

if ispc
    edir='D:\motion_cued\eeg_data\';
    bdir='D:\motion_cued\behav_data\';
else
    [~,hostname]=system('hostname');
    if ~isempty(strfind(hostname,'les')) | ~isempty(strfind(hostname,'LES')) % either COLLES-151401 or LES-LINUX_FS3
        edir='/home/zumerj/motion_cued/eeg_data/';
        bdir='/home/zumerj/motion_cued/behav_data/';
    else % assume on VM linux of psychl-132432
        edir='/mnt/hgfs/D/motion_cued/eeg_data/';
        bdir='/mnt/hgfs/D/motion_cued/behav_data/';
    end
end
cd(edir)

sub{1}='e01'; % 10/12/15 (TP)
sub{2}='e02'; % 17/12/15 (JZ)
sub{3}='e03'; % 10/2/16 (p109) % cue-response-training codes were 97/104 but will be 87/94 from now on
sub{4}='e04'; % 16/2/16 (p37) migraine; insufficient data
sub{5}='e05'; % 17/2/16 (p115)
sub{6}='e06'; % 23/2/16 (p118)
sub{7}='e07'; % 25/2/16 (p113)
sub{8}='e08'; % 25/2/16 (p120)
sub{9}='e09'; % 26/2/16 (p116)
sub{10}='e10'; % 1/3/16 (p111)
sub{11}='e11'; % 2/3/16 (p117)
sub{12}='e12'; % 2/3/16 (p122)



if ispc
    rmpath(genpath('D:\matlab\spm8\external\fieldtrip\'))
    rmpath(genpath('D:\fieldtrip_svn\'))
    addpath('D:\fieldtrip_svn\')
else
    rmpath(genpath('/mnt/hgfs/D/matlab/spm8/external/fieldtrip/'))
    rmpath(genpath('/mnt/hgfs/D/fieldtrip_svn/'))
    addpath('/mnt/hgfs/D/fieldtrip_svn/')
end
which ft_defaults.m
ft_defaults;


%%

subuse=[1:3 5:12];

plotflag=0;
scdflag=1;

for ii=subuse
    
    if 0
        if ~exist(eogartifact,'file')
            motcue_eeg_eog;
        end
        if ~exist(muscleartifact,'file')
            motcue_eeg_muscle;
        end
    end
    
    files=dir([sub{ii} '*cued_*.eeg']);
    
    for ff=1:length(files)
        cfg=[];
        cfg.dataset=files(ff).name;
        cfg.trialfun='ft_trialfun_general';
        % cfg.trialdef.eventtype  = '?';
        cfg.trialdef.eventtype  = 'Stimulus';
        cfg.trialdef.eventvalue = {'S 21' 'S 22'};
        cfg.trialdef.prestim = 1;
        cfg.trialdef.poststim = 2;
        cfgtr=ft_definetrial(cfg);
        
        
        cfg=[];
        cfg.dataset=files(ff).name;
        cfg.demean='yes';
        cfg.bsfilter='yes';
        cfg.bsfreq=[49 51; 99 101; 149 151];
        cfg.hpfilter='yes';
        cfg.hpfiltord=3;
        cfg.hpfreq=0.2;  % Could do higher for awake data but not want higher for sleep.
        cfg.channel={'all' '-ECG' '-VEOG' '-HEOG' '-EMG'};
        cfg.reref='yes';
        cfg.refchannel='all'; % used linked-mastoids for sleep staging but use average reference for ERPs and TFRs and source localisation
        raw_hpf{ff}=ft_preprocessing(cfg);
        
        cfg=[];
        cfg.trl=cfgtr.trl;
        raw_cue{ff}=ft_redefinetrial(cfg,raw_hpf{ff});
    end
    
    cfg=[];
    raw_cue_all=ft_appenddata(cfg,raw_cue{:});
    
    if ii==2
        cfg=[];
        raw_cue_short=ft_appenddata(cfg,raw_cue{[1:2:10]});
        cfg=[];
        raw_cue_long=ft_appenddata(cfg,raw_cue{[2:2:10]});
    end
    
    if scdflag
        cfg=[];
        cfg.elecfile='standard_1005.elc';
        cfg.method='spline';
        raw_all_scd=ft_scalpcurrentdensity(cfg,raw_cue_all);
        if ii==2
            raw_all_scd_short=ft_scalpcurrentdensity(cfg,raw_cue_short);
            raw_all_scd_long=ft_scalpcurrentdensity(cfg,raw_cue_long);
        end
    end
    
    
    if plotflag
        cfg=[];
        ft_databrowser(cfg,raw_cue_all);
    end
    
    cfg=[];
    cfg.lpfilter='yes';
    cfg.lpfreq=40;
    cfg.demean='yes';
    cfg.baselinewindow=[-0.9 -0.4];
    % cfg.baselinewindow=[-0.9 0.9];
    if scdflag
        raw_cue_all_lpf=ft_preprocessing(cfg,raw_all_scd);
    else
        raw_cue_all_lpf=ft_preprocessing(cfg,raw_cue_all);
    end
    if ii==2
        if scdflag
            raw_cue_all_lpf_short=ft_preprocessing(cfg,raw_all_scd_short);
            raw_cue_all_lpf_long=ft_preprocessing(cfg,raw_all_scd_long);
        else
            raw_cue_all_lpf_short=ft_preprocessing(cfg,raw_cue_short);
            raw_cue_all_lpf_long=ft_preprocessing(cfg,raw_cue_long);
        end
    end
    
    % FIXME: make general so that code is for lowprob (check setup.cuefreq(1)
    cfg=[];
    cfg.trials=raw_cue_all.trialinfo==21;
    raw_locue_all=ft_selectdata(cfg,raw_cue_all);
    if scdflag
        raw_locue_scd=ft_selectdata(cfg,raw_all_scd);
    end
    raw_locue_all_lpf=ft_selectdata(cfg,raw_cue_all_lpf);
    if ii==2
        cfg.trials=raw_cue_short.trialinfo==21;
        raw_locue_short=ft_selectdata(cfg,raw_cue_short);
        cfg.trials=raw_cue_long.trialinfo==21;
        raw_locue_long=ft_selectdata(cfg,raw_cue_long);
    end
    cfg=[];
    cfg.trials=raw_cue_all.trialinfo==22;
    raw_hicue_all=ft_selectdata(cfg,raw_cue_all);
    if scdflag
        raw_hicue_scd=ft_selectdata(cfg,raw_all_scd);
    end
    raw_hicue_all_lpf=ft_selectdata(cfg,raw_cue_all_lpf);
    if ii==2
        cfg.trials=raw_cue_short.trialinfo==22;
        raw_hicue_short=ft_selectdata(cfg,raw_cue_short);
        cfg.trials=raw_cue_long.trialinfo==22;
        raw_hicue_long=ft_selectdata(cfg,raw_cue_long);
    end
    
    cfg=[];
    tlock_locue=ft_timelockanalysis(cfg,raw_locue_all_lpf);
    tlock_hicue=ft_timelockanalysis(cfg,raw_hicue_all_lpf);
    
    if plotflag
        figure;plot(tlock_locue.time,[mean(tlock_locue.avg(56:64,:),1); mean(tlock_hicue.avg(56:64,:),1)])
        
        figure;
        cfg=[];
        cfg.layout='elec1010.lay';
        cfg.interactive='yes';
        ft_multiplotER(cfg,tlock_locue,tlock_hicue);
    end
    
    % e09 the alpha is perfectly out of phase between cue types!
    
    cfg=[];
    cfg.method='mtmconvol';
    cfg.pad=4;
    cfg.foi=4:2:30;
    cfg.taper='hanning';
    cfg.toi=-0.8:.1:2.0;
    cfg.t_ftimwin=4./cfg.foi;
    cfg.output='pow';
    if scdflag
        freq_locue=ft_freqanalysis(cfg,raw_locue_scd);
        freq_hicue=ft_freqanalysis(cfg,raw_hicue_scd);
    else
        freq_locue=ft_freqanalysis(cfg,raw_locue_all);
        freq_hicue=ft_freqanalysis(cfg,raw_hicue_all);
    end
    
    cfg=[];
    cfg.parameter='powspctrm';
    cfg.operation='x1/x2 - 1';
    freq_diff=ft_math(cfg,freq_locue,freq_hicue);
    if ii==2
        cfg=[];
        cfg.method='mtmconvol';
        cfg.pad=4;
        cfg.foi=4:2:30;
        cfg.taper='hanning';
        cfg.toi=-0.8:.1:2.0;
        cfg.t_ftimwin=4./cfg.foi;
        cfg.output='pow';
        freq_locue_short=ft_freqanalysis(cfg,raw_locue_short);
        freq_hicue_short=ft_freqanalysis(cfg,raw_hicue_short);
        freq_locue_long=ft_freqanalysis(cfg,raw_locue_long);
        freq_hicue_long=ft_freqanalysis(cfg,raw_hicue_long);
        cfg=[];
        cfg.parameter='powspctrm';
        cfg.operation='x1/x2 - 1';
        freq_diff_long=ft_math(cfg,freq_locue_long,freq_hicue_long);
    end
    if scdflag
        save([edir sub{ii} '_freq_scd.mat'],'freq*')
    else
        save([edir sub{ii} '_freq.mat'],'freq*')
    end
    
    if plotflag
        chanuse=match_str(freq_hicue.label,{'PO9' 'PO10' 'O1' 'O2' 'Oz' 'PO3' 'PO4' 'POz' 'PO7' 'PO8'});
        figure;plot(freq_locue.time,[squeeze(mean(mean(freq_hicue.powspctrm(chanuse,3:5,:),1),2)) squeeze(mean(mean(freq_locue.powspctrm(chanuse,3:5,:),1),2))])
        legend({'High cue' 'Low cue'})
        
        if ii==2
            figure;plot(freq_locue.time,[squeeze(mean(mean(freq_hicue_short.powspctrm(chanuse,3:5,:),1),2)) squeeze(mean(mean(freq_locue_short.powspctrm(chanuse,3:5,:),1),2))])
            figure;plot(freq_locue.time,[squeeze(mean(mean(freq_hicue_long.powspctrm(chanuse,3:5,:),1),2))  squeeze(mean(mean(freq_locue_long.powspctrm(chanuse,3:5,:),1),2))])
        end
        
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
        cfg.layout='elec1010.lay';
        cfg.zlim='maxabs';
        ft_multiplotTFR(cfg,freq_diff)
        if ii==2
            ft_multiplotTFR(cfg,freq_locue_long)
            ft_multiplotTFR(cfg,freq_hicue_long)
            cfg=[];
            cfg.layout='elec1010.lay';
            cfg.zlim='maxabs';
            ft_multiplotTFR(cfg,freq_diff_long)
        end
    end
    
end % ii

return

%% Summary over group
clearvars -except *dir sub

scdflag=1;

subuse=[2:3 5:12]; % 1 had many eyeblinks just before cue;

for ii=1:length(subuse)
    if scdflag
        load([edir sub{subuse(ii)} '_freq_scd.mat'])
    else
        load([edir sub{subuse(ii)} '_freq.mat'])
    end
    freq_diff_each{ii}=freq_diff;
    freq_locue_each{ii}=freq_locue;
    freq_hicue_each{ii}=freq_hicue;
    
    freq_cueindex{ii}=freq_hicue_each{ii};
    freq_cueindex{ii}.powspctrm=2*[freq_locue_each{ii}.powspctrm-freq_hicue_each{ii}.powspctrm]./[freq_locue_each{ii}.powspctrm+freq_hicue_each{ii}.powspctrm];
end



cfg=[];
grave_freqdiff=ft_freqgrandaverage(cfg,freq_diff_each{:});
grave_freqindex=ft_freqgrandaverage(cfg,freq_cueindex{:});
cfg=[];
cfg.keepindividual='yes';
grind_freqdiff=ft_freqgrandaverage(cfg,freq_diff_each{:});
grind_freqindex=ft_freqgrandaverage(cfg,freq_cueindex{:});
grind_freq_locue=ft_freqgrandaverage(cfg,freq_locue_each{:});
grind_freq_hicue=ft_freqgrandaverage(cfg,freq_hicue_each{:});

% baseline relchange prior to grandaverage?

figure;
cfg=[];
cfg.layout='elec1010.lay';
cfg.zlim='maxabs';
ft_multiplotTFR(cfg,grave_freqdiff)
figure;
cfg=[];
cfg.layout='elec1010.lay';
cfg.zlim='maxabs';
ft_multiplotTFR(cfg,grave_freqindex)

load eeg1010_neighb

cfg=[];
if scdflag
    cfg.latency=[.2 .6];
else
    cfg.latency=[.4 .8];
end
cfg.frequency=[8 12];
cfg.avgovertime='yes';
cfg.avgoverfreq='yes';

% chanocc={'P3' 'PO9' 'O1' 'Oz' 'O2' 'PO10' 'P5' 'P1' 'PO7' 'PO3'};
% cfg.channel=chanocc;
% cfg.avgoverchan='yes';

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
stat.label(stat.prob<.06)

cfg=[];
cfg.latency=[.2 .6];
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
cfg.zlim='maxabs';
cfg.highlightchannel=stat.label(stat.prob<.05);
ft_topoplotTFR(cfg,grave_plot);

