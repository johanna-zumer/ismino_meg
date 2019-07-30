% motcue_blink_rm


cfg=[];
cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
cfg.trl=cfgtr.trl;
eye_adc_shift=motcue_loadshift_adc(cfg);

cfg=[];
cfg.trl=cfgtr.trl;
raw_cue=ft_redefinetrial(cfg,raw_dnbs);
clear raw_dnbs

cfg=[];
cfg.latency=[-1.4 2.4]; % these numbers should match EL file loading below
raw_cue=ft_selectdata(cfg,raw_cue);
eye_adc_shift=ft_selectdata(cfg,eye_adc_shift);

if max(eye_adc_shift.time{1}-raw_cue.time{1})<2*eps
  eye_adc_shift.time=raw_cue.time;
else
  error('something gone wrong with data alignment')
end
%     clear eyechan eye_cue_orig

cfg=[];
cfg.appenddim='chan';
megeye_cue=ft_appenddata(cfg,raw_cue,eye_adc_shift);
megeye_cue.grad=raw_cue.grad;
clear raw_cue eye_adc_shift

if 0 % not necessary: already loaded in to .trialinfo via cfgtr.trl
  % get responses
  event_meg = ft_read_event([sub{ii} '/' datanames(avcuedata{ii}(ff)).name]);
  event_resp = event_meg(strcmp('UPPT001', {event_meg.type}));
  event_stim = event_meg(strcmp('UPPT002', {event_meg.type}));
  keyboard
  clear respvalue
  for tr=1:size(megeye_br.sampleinfo,1)
    trresp=find(([event_resp.sample]-megeye_br.sampleinfo(tr,2))<1000 & ([event_resp.sample]-megeye_br.sampleinfo(tr,2))>0   );
    if ~isempty(trresp)
      respvalue(tr)=event_resp().value;
    else
      respvalue(tr)=nan;
    end
  end
end

if brdo
  switch brval
    case 'run'
      % Call FT artifact rejection for EOG
      switch brzvalue
        case 'sensor_old'
          zvalue_cutoff=[nan 1.5 1.5 1.2 1.5   1.5 1.5 1.5 1.5 1.5   1.5 1.5 1.5 1.5 1.5   1.5 1.5 1.5 1.5 1.5   1.5 1.5 1.5];
        case 'source1'
          zvalue_cutoff=[nan 2.5*ones(1,22)];
      end
      cfg=[];
      cfg.trl=cfgtr.trl;
      cfg.continuous = 'no';
      cfg.artfctdef.zvalue.channel = 'UADC002'; %vertical
      cfg.artfctdef.zvalue.cutoff = zvalue_cutoff(ii);
      cfg.artfctdef.zvalue.trlpadding =0;
      cfg.artfctdef.zvalue.fltpadding =0;
      cfg.artfctdef.zvalue.artpadding =0.25;
      cfg.artfctdef.zvalue.rectify       = 'yes';
      if plotflag
        cfg.artfctdef.zvalue.interactive = 'yes';
      end
      [cfg, artifact] = ft_artifact_zvalue(cfg, megeye_cue);
      artfct_blinkz=cfg.artfctdef.zvalue;
      artfct_blink_save=artfct_blinkz;  % ADC channel
      delete([adir sub{ii} '_eye_artfct_runff' num2str(ff) '.mat'])
      save([adir sub{ii} '_eye_artfct_runff' num2str(ff) '.mat'],'artfct_blink_save')
    case 'load'
  end
  artfct_blinkz=load([adir sub{ii} '_eye_artfct_runff' num2str(ff) '.mat'],'artfct_blink_save');
  
  cfg=[];
  cfg.artfctdef.reject='complete'; % 'nan'
  cfg.artfctdef.crittoilim = [0 2];
  cfg.artfctdef.blink.artifact=artfct_blinkz.artfct_blink_save.artifact;
  eyeadc_blinkrm = ft_rejectartifact(cfg, megeye_cue);
  % replace with nan where it occurs elsewhere
  cfg=[];
  cfg.artfctdef.reject='nan';
  cfg.artfctdef.blink.artifact=artfct_blinkz.artfct_blink_save.artifact;
  megeye_br = ft_rejectartifact(cfg, eyeadc_blinkrm);
else
  megeye_br=megeye_cue;
end
clear eyeadc_blinkrm
clear megeye_cue

