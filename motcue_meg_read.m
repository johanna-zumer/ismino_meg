function motcue_eeg_read

clear all
close all

if ispc
%   mdir='D:\motion_cued\meg_data\';
%   bdir='D:\motion_cued\behav_data\';
  mdir='I:\motion_cued\meg_data\';
  bdir='I:\motion_cued\behav_data\';
else
  [~,hostname]=system('hostname');
  if ~isempty(strfind(hostname,'les')) | ~isempty(strfind(hostname,'LES')) % either COLLES-151401 or LES-LINUX_FS3
    mdir='/home/zumerj/motion_cued/meg_data/';
    bdir='/home/zumerj/motion_cued/behav_data/';
  else % assume on VM linux of psychl-132432
    mdir='/mnt/hgfs/D/motion_cued/meg_data/';
    bdir='/mnt/hgfs/D/motion_cued/behav_data/';
  end
end
cd(mdir)

for ii=1:9
	sub{ii}=['m0' num2str(ii)];
end
for ii=10:30
	sub{ii}=['m' num2str(ii)];
end

% volnum{1}='10859021';
% volnum{2}='09376057';
% volnum{3}='10925013';

if ispc
  rmpath(genpath('D:\matlab\spm8\external\fieldtrip\'))
  rmpath(genpath('D:\fieldtrip_svn\'))
%   addpath('D:\fieldtrip_svn\')
  addpath('D:\fieldtrip_git\')
  addpath('D:\motion_cued\mfiles\')
else
  rmpath(genpath('/mnt/hgfs/D/matlab/spm8/external/fieldtrip/'))
  rmpath(genpath('/mnt/hgfs/D/fieldtrip_svn/'))
%   addpath('/mnt/hgfs/D/fieldtrip_svn/')
  addpath('/mnt/hgfs/D/fieldtrip_git/')
  addpath('/mnt/hgfs/D/motion_cued/mfiles/')
end
which ft_defaults.m
ft_defaults;


%%

subuse=[2 ];

plotflag=0;

for ii=subuse
  
if 0
  if ~exist(eogartifact,'file')
    motcue_eeg_eog;
  end
  if ~exist(muscleartifact,'file')
    motcue_eeg_muscle;
  end
end

% datanames=dir([volnum{ii} '*']);
% datanames=dir([sub{ii} '/' volnum{ii} '*']);
datanames=dir([sub{ii} '/*.ds']);

% the number here is the MEG run e.g. *_04.ds
avcuedata{2}=[4 5];
avcuedata{3}=[4:10];
avcuedata{4}=[4:10];
avcuedata{5}=[4:10];
avcuedata{6}=[3:8];
avcuedata{7}=[4:10];
avcuedata{8}=[4:9];
avcuedata{9}=[4:10];
avcuedata{10}=[5:10];
avcuedata{11}=[4:10];
avcuedata{12}=[4:9];
avcuedata{13}=[4:10];
avcuedata{14}=[4:10];
avcuedata{15}=[4:10];
avcuedata{16}=[4:10];
avcuedata{17}=[4:6 8:10];
avcuedata{18}=[4:10];
avcuedata{19}=[4:9];
avcuedata{20}=[4:9];
avcuedata{21}=[4:10];
avcuedata{22}=[4:9];
avcuedata{23}=[4:10];

blockind=0;
for ff=avcuedata{ii}
  blockind=blockind+1;
  
  % cfg=[];
  % cfg.dataset=datanames(ff).name;
  % raw_hpf{blockind}=ft_preprocessing(cfg);
  % % raw_hpf.hdr.orig.hist(68:84) % date/time stamp
  
  % cfg=[];
  % cfg.dataset=datanames(ff).name;
  % event=ft_read_event(cfg.dataset);
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(ff).name];
  cfg.trialfun='ft_trialfun_general';
  % cfg.trialdef.eventtype  = '?';
  cfg.trialdef.eventtype  = 'UPPT002';
  cfg.trialdef.eventvalue = {21 22};
  cfg.trialdef.prestim = 1;
  cfg.trialdef.poststim = 2;
  cfgtr=ft_definetrial(cfg);
  
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(ff).name];
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
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(ff).name];
  cfg.channel={'UADC*' };
  eyechan=ft_preprocessing(cfg);
  
  cfg=[];
  cfg.trl=cfgtr.trl;
  raw_cue=ft_redefinetrial(cfg,raw_hpf);
  eye_cue=ft_redefinetrial(cfg,eyechan);
  
  clear raw_hpf eyechan
  
  cfg=[];
  megeye_cue{blockind}=ft_appenddata(cfg,raw_cue,eye_cue);
  clear raw_cue eye_cue
  
  % cfg=[];
  % cfg.channel='MEG';
  % megchan=ft_selectdata(cfg,raw_hpf);
  % cfg=[];
  % cfg.hpfilter='yes';
  % cfg.hpfreq=1;
  % megchan_hpf=ft_preprocessing(cfg,megchan);
end

filename_eye=[bdir 'm03_1424.asc'];
cfg=[];
cfg.dataset=filename_eye;
data_eye=ft_preprocessing(cfg);

event_eye=jz_read_eyelink_events(filename_eye);

cfg=[];
cfg.viewmode='vertical';
cfg.preproc.demean='yes';
cfg.event=event_eye;
cfg.channel={'2' '3' '4'};
ft_databrowser(cfg,data_eye);

cfg=[];
cfg.dataset=filename_eye;
cfg.trialdef.eventtype='msg';
cfg.trialdef.eventvalue={21 22};
cfg.trialdef.prestim=1;
cfg.trialdef.poststim=2;
cfg.event=event_eye;
% cfg.trialfun='ft_trialfun_eyelink_appmot';
cfg=ft_definetrial(cfg);
data_eye2=ft_preprocessing(cfg);

cfg=[];
cfg.resamplefs=megeye_cue{1}.fsample;
data_eye_resamp=ft_resampledata(cfg,data_eye2);

megeye_cue_all=ft_appenddata([],megeye_cue{1},data_eye_resamp);


% figure
% plot([event_eye.sample]./data_eye.hdr.Fs, [event_eye.value], '.')
% title('Eye position during fixation')
% xlabel('time (s)');
% ylabel('X position in pixels');
% 
% event_eye = ft_read_event('m03_1343.asc');

megeye_cue_all=ft_appenddata([],megeye_cue{:});
clear megeye_cue

cfg=[];
cfg.channel={'MZ'};
% cfg.channel={'MZ' 'UADC*'};
megchanZ=ft_selectdata(cfg,megeye_cue_all);
cfg.channel={'MRF14' 'MLF14'};
megchanF=ft_selectdata(cfg,megeye_cue_all);

cfg=[];
cfg.channel={'UADC*'};
eyechan=ft_selectdata(cfg,megeye_cue_all);

cfg=[];
cfg.channel={'2' '3' '4'};
data_eye_resamp234=ft_selectdata(cfg,data_eye_resamp);

cfg=[];
cfg.parameter='trial';
cfg.operation='multiply';
cfg.scalar=10^15;
megchanZs=ft_math(cfg,megchanZ);
megchanFs=ft_math(cfg,megchanF);
cfg.scalar=10^3;
eyechans=ft_math(cfg,eyechan);


if plotflag
  cfg=[];
  cfg.viewmode='vertical';
  cfg.preproc.demean='yes';
  ft_databrowser(cfg,ft_appenddata([],megchanFs,eyechans,data_eye_resamp234));
  ft_databrowser(cfg,megchanZ);
  ft_databrowser(cfg,eyechan);
end


cfg=[];
cfg.lpfilter='yes';
cfg.lpfreq=40;
cfg.demean='yes';
cfg.baselinewindow=[-0.9 -0.4];
cfg.baselinewindow=[-0.9 0.9];
raw_cue_all_lpf=ft_preprocessing(cfg,megeye_cue_all);

% FIXME: make general so that code is for lowprob (check setup.cuefreq(1)
cfg=[];
cfg.trials=megeye_cue_all.trialinfo==21;
raw_locue_all=ft_selectdata(cfg,megeye_cue_all);
raw_locue_all_lpf=ft_selectdata(cfg,raw_cue_all_lpf);
cfg=[];
cfg.trials=megeye_cue_all.trialinfo==22;
raw_hicue_all=ft_selectdata(cfg,megeye_cue_all);
raw_hicue_all_lpf=ft_selectdata(cfg,raw_cue_all_lpf);

cfg=[];
tlock_locue=ft_timelockanalysis(cfg,raw_locue_all_lpf);
tlock_hicue=ft_timelockanalysis(cfg,raw_hicue_all_lpf);


if plotflag
  cfg=[];
  cfg.channel={'MLO' 'MRO' 'MZO'};
  cfg.avgoverchan='yes';
  tlock_locue_occ=ft_selectdata(cfg,tlock_locue);
  tlock_hicue_occ=ft_selectdata(cfg,tlock_hicue);
  figure;plot(tlock_locue.time,[tlock_locue_occ.avg; tlock_hicue_occ.avg])

  cfg=[];
  cfg.channel={'MLT' 'MRT' };
  cfg.avgoverchan='yes';
  tlock_locue_tem=ft_selectdata(cfg,tlock_locue);
  tlock_hicue_tem=ft_selectdata(cfg,tlock_hicue);
  figure;plot(tlock_locue.time,[tlock_locue_tem.avg; tlock_hicue_tem.avg])

figure;
cfg=[];
cfg.layout='CTF275.lay';
cfg.interactive='yes';
ft_multiplotER(cfg,tlock_locue,tlock_hicue);
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

cfg=[];
cfg.method='mtmconvol';
cfg.pad=4;
cfg.foi=4:2:30;
cfg.taper='hanning';
cfg.toi=-0.8:.1:2.0;
cfg.t_ftimwin=4./cfg.foi;
cfg.output='pow';
freq_locue=ft_freqanalysis(cfg,raw_locue_all);
freq_hicue=ft_freqanalysis(cfg,raw_hicue_all);

cfg=[];
cfg.parameter='powspctrm';
cfg.operation='x1/x2 - 1';
freq_diff=ft_math(cfg,freq_locue,freq_hicue);
save([mdir sub{ii} '_freq.mat'],'freq*')

if plotflag
% chanuse=match_str(freq_hicue.label,{'PO9' 'PO10' 'O1' 'O2' 'Oz' 'PO3' 'PO4' 'POz' 'PO7' 'PO8'});
  cfg=[];
  cfg.channel={'MLO' 'MRO' 'MZO'};
  cfg.avgoverchan='yes';
  freq_locue_occ=ft_selectdata(cfg,freq_locue);
  freq_hicue_occ=ft_selectdata(cfg,freq_hicue);
  figure;plot(freq_locue.time,[squeeze(mean(freq_hicue.powspctrm(1,3:5,:),2)) squeeze(mean(freq_locue.powspctrm(1,3:5,:),2))])
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

