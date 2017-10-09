

motcue_init
cd(mdir)


%%
% ii=subind;
for ii=subuse % not parfor (too much RAM)
%   clearvars -except ii sub* avcue* *dir *flag

datanames=dir([sub{ii} '/*.ds']);

for ff=1:length(avcuedata{ii}) % parfor on cluster
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
%   cfg.trialfun='ft_trialfun_general';
  cfg.trialfun='ft_trialfun_general_motcue';
  cfg.trialdef.eventtype  = 'UPPT002';
  cfg.trialdef.eventvalue = {21 22}; % This means cue value
  cfg.trialdef.prestim = 1.5;
  cfg.trialdef.poststim = 2.5;
  cfgtr=ft_definetrial(cfg);
  
  cfg=[];
  cfg.dataset=[sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
  cfg.demean='yes';
  cfg.bsfilter='yes';
  cfg.bsfreq=[49 51; 99 101; 149 151];
  cfg.hpfilter='yes';
  cfg.hpfiltord=3;
  cfg.hpfreq=0.5;  
  cfg.channel={'MEG' };
  raw_hpf=ft_preprocessing(cfg);
  
  cfg=[];
  cfg.trl=cfgtr.trl;
  raw_cue=ft_redefinetrial(cfg,raw_hpf);
  
  cfg=[];
  cfg.latency=[-1.4 2.4]; % these numbers should match EL file loading below
  raw_cue=ft_selectdata(cfg,raw_cue);
  
  clear raw_hpf
  %     clear eyechan eye_cue_orig
    
  %% Artifact rejection
  visflag=1;
  data_out=motcue_artifact_all(raw_cue,ii,ff,sub,adir,visflag);
end

end