
clear
motcue_init
cd(mdir)
subuse=2:23;

%%
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
    cfg.channel={'MEG' 'MEGREF'};
    raw_hpf=ft_preprocessing(cfg);
    
    cfg=[];
    cfg.trl=cfgtr.trl;
    meg_cue=ft_redefinetrial(cfg,raw_hpf);
    
    cfg=[];
    cfg.latency=[-1.4 2.4]; % these numbers should match EL file loading below
    meg_cue=ft_selectdata(cfg,meg_cue);
    
    cfg=[];
    cfg.gradient='G3BR';
    meg_cue3=ft_denoise_synthetic(cfg, meg_cue);
    
    clear raw_hpf meg_cue
    
    cfg=[];
    cfg.channel={'MEG'};
    meg3=ft_selectdata(cfg,meg_cue3);
    clear meg_cue3
    
    %% Artifact rejection
    visflag=1;
    data_out=motcue_artifact_all(meg3,ii,ff,sub,adir,visflag);
  end
  
end