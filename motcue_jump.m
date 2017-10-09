function motcue_jump(subind)

motcue_init
cd(mdir)

% for ii=subuse
ii=subind;

datanames=dir([mdir sub{ii} '/*.ds']);

for ff=1:length(avcuedata{ii})
  
  cfg=[];
  cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
  %     cfg.trialfun='ft_trialfun_general';
  cfg.trialfun='ft_trialfun_general_motcue';
  cfg.trialdef.eventtype  = 'UPPT002';
  cfg.trialdef.eventvalue = {21 22}; % This means cue value
  cfg.trialdef.prestim = 1.5;
  cfg.trialdef.poststim = 2.5;
  cfgtr=ft_definetrial(cfg);
  
  % jump
  cfg                    = [];
  cfg.trl = cfgtr.trl;
  cfg.dataset   = [mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
  cfg.continuous = 'yes';
  
  % channel selection, cutoff and padding
  cfg.artfctdef.zvalue.channel    = {'MEG' 'MEGREF'};
  cfg.artfctdef.zvalue.cutoff     = 30;
  cfg.artfctdef.zvalue.trlpadding = 0;
  cfg.artfctdef.zvalue.artpadding = 0;
  cfg.artfctdef.zvalue.fltpadding = 0;
  
  % algorithmic parameters
  cfg.artfctdef.zvalue.cumulative    = 'yes';
  cfg.artfctdef.zvalue.medianfilter  = 'yes';
  cfg.artfctdef.zvalue.medianfiltord = 9;
  cfg.artfctdef.zvalue.absdiff       = 'yes';
  
  % make the process interactive
  cfg.artfctdef.zvalue.interactive = 'no';
  
  cfg = ft_artifact_zvalue(cfg);
  artfct_jumpz=cfg.artfctdef.zvalue;
  save([adir sub{ii} '_jump_artfct_runff' num2str(ff) '.mat'],'artfct_jumpz')
end
% end
