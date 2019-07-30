% this script is called inside other functions.

cfg=[];
cfg.dataset=[mdir sub{ii} filesep dsnames{ff}];
%   cfg.trialfun='ft_trialfun_general';
cfg.trialfun='ft_trialfun_general_motcue';
cfg.trialdef.eventtype  = 'UPPT002';
cfg.trialdef.eventvalue = {21 22}; % This means cue value
cfg.trialdef.prestim = 1.5;
cfg.trialdef.poststim = 2.5;
cfgtr=ft_definetrial(cfg);

cfg=[];
cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
cfg.channel={'MEG' 'MEGREF'};
rawd=ft_preprocessing(cfg);


%% from http://www.fieldtriptoolbox.org/example/how_to_incorporate_head_movements_in_meg_analysis
cfg.channel                 = {'HLC0011','HLC0012','HLC0013', ...
                              'HLC0021','HLC0022','HLC0023', ...
                              'HLC0031','HLC0032','HLC0033'}; 
headpos = ft_preprocessing(cfg);
ntrials = length(headpos.sampleinfo)
for t = 1:ntrials
  coil1(:,t) = [mean(headpos.trial{1,t}(1,:)); mean(headpos.trial{1,t}(2,:)); mean(headpos.trial{1,t}(3,:))];
  coil2(:,t) = [mean(headpos.trial{1,t}(4,:)); mean(headpos.trial{1,t}(5,:)); mean(headpos.trial{1,t}(6,:))];
  coil3(:,t) = [mean(headpos.trial{1,t}(7,:)); mean(headpos.trial{1,t}(8,:)); mean(headpos.trial{1,t}(9,:))];
end
 % calculate the headposition and orientation per trial (for function see bottom page) 
cc = circumcenter(coil1, coil2, coil3);
cc_rel = [cc - repmat(cc(:,1),1,size(cc,2))]';
 
% plot translations
figure(); plot(cc_rel(:,1:3)*1000);title('translations in mm') % in mm
% plot rotations
figure(); plot(cc_rel(:,4:6)) ; title('rotations')
maxposchange = max(abs(cc_rel(:,1:3)*1000)) % in mm

if isempty(reply)
  reply=input('run ft_headmovement? y/n: ','s');
end
close all

% Do this after source analysis
if 0
  % demean to obtain translations and rotations from the average position and orientation
  cc_dem = [cc - repmat(mean(cc,2),1,size(cc,2))]';
  confound = [cc_dem ones(size(cc_dem,1),1)];
  % regress out headposition confounds
  cfg                         = [];
  cfg.confound                = confound;
  cfg.reject                  = [1:6]; % keeping the constant (nr 7)
  regr = ft_regressconfound(cfg, timelock);
end

%%
if ii==22 && ff==5
  disp('reject channels before jump RM')
  cfg=[];
  cfg.method='summary';
  cfg.keeptrial='yes';
  %   cfg.keepchannel='yes';
  cfg.channel={'MEG'}; % ignore ADC
  megeye_userej=ft_rejectvisual(cfg,rawd);
  rejchan=setdiff(megeye_userej.cfg.channel,megeye_userej.label);
  cfg=[];
  cfg.channel=setdiff(rawd.label,rejchan);
  rawd=ft_selectdata(cfg,rawd);  
end


% JUMP removal (taken from motcue_jump and motcue_artifact*; now redundant)
motcue_jump_rm  % output is 'rawd_j'

if strmatch(reply,'y') % only if plots look like lots of movement?
  cfg = [];
%     cfg.trl          = cfgtr.trl(:,1:3);  % FIXME: Or do we want this to be after artifact rejection???
  cfg.trl = cfgtr.trl; % trl defining only the trials I use in this contrast (e. . Hits and misses at retrieval after preprocessing)
  cfg.dataset = [mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
  cfg.numclusters = ceil(size(cfgtr.trl,1)/10);  % Sebastian
%     cfg.numclusters  = 10;
  cfg.feedback = 'no';
  grad = ft_headmovement(cfg);
  rawd_j.grad = grad;
end
clear reply

% 3rd order gradient correction
cfg=[];
cfg.gradient='G3BR';
raw_dn=ft_denoise_synthetic(cfg, rawd_j);
clear rawd_j

cfg=[];
cfg.channel='MEG'; % we don't need MEGREF anymore
meg_dn=ft_selectdata(cfg,raw_dn);
clear raw_dn

% Line noise
cfg=[];
cfg.demean='yes';
% cfg.bsfilter='yes';
% cfg.bsfreq=[49 51; 99 101; 149 151];
cfg.hpfilter='yes';
cfg.hpfiltord=3;
cfg.hpfreq=0.2;  
cfg.channel={'MEG'}; % exclude ADC 
raw_dnbs=ft_preprocessing(cfg,meg_dn);
clear meg_dn

% Chunk to trials and load ADC eye channels
% Eyelink (blink here; still to do saccade)
motcue_blink_rm % output is megeye_br



% Manually visually inspect
if visflag
  cfg=[];
  cfg.method='summary';
  cfg.keeptrial='yes';
%   cfg.keepchannel='yes'; 
  cfg.channel={'MEG'}; % ignore ADC
  megeye_userej=ft_rejectvisual(cfg,megeye_br); % may reject channels here

%   rejchan=setdiff(megeye_userej.cfg.channel,megeye_userej.label);

  cfg=[];
  cfg.channel={'MEG'}; % ignore ADC
  cfg.artfctdef.summary.artifact= megeye_userej.cfg.artfctdef.summary.artifact;
  cfgout=ft_databrowser(cfg,megeye_userej);
  
  
  chankeep=megeye_userej.label;
  artfct_summary=cfgout.artfctdef.summary;
  
  save([adir sub{ii} '_rejectvisual_artfct_runff' num2str(ff) '.mat'],'chankeep','artfct_summary');
  clear megeye_userej
elseif ~visflag
end

artfct_vissummary=load([adir sub{ii} '_rejectvisual_artfct_runff' num2str(ff) '.mat']);
if ~isempty(artfct_vissummary.artfct_summary.artifact)
  cfg=[];
  cfg.artfctdef.reject='complete'; % 'nan'
  cfg.artfctdef.summary.artifact=artfct_vissummary.artfct_summary.artifact;
  megeye_br = ft_rejectartifact(cfg, megeye_br);
end
adcchan={'UADC001' 'UADC002' 'UADC003'}';
if ~isempty(setdiff(setdiff(megeye_br.label,artfct_vissummary.chankeep),adcchan))
  missingchannel=setdiff(setdiff(megeye_br.label,artfct_vissummary.chankeep),adcchan);
  cfg=[];
  cfg.channel=[artfct_vissummary.chankeep; adcchan];
  tmp=ft_selectdata(cfg,megeye_br);
  tmp=rmfield(tmp,'elec');
  load ctf275_neighb.mat
  cfg=[];
  cfg.neighbours=neighbours;
  cfg.senstype='MEG';
  cfg.grad=megeye_br.grad;
  cfg.missingchannel=missingchannel;
  megeye_br=ft_channelrepair(cfg,tmp);
end



