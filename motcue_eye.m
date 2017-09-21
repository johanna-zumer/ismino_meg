% script to remove trials based on eye blinks or movements

motcue_init
cd(mdir)
plotflag=0;

% Which *.asc file to use
% comment states which MEG run it goes with
avcue_asc{2} =[3:4];      dataasc{2}=[1 1]; % 4 5
avcue_asc{3} =[3:8];      dataasc{3}=[0 1 1 1 1 1 1];% 5:10; % missing for 4
avcue_asc{4} =[4:10];     dataasc{4}=[1 1 1 1 1 1 1 ]; % 4:10
avcue_asc{5} =[4:9];      dataasc{5}=[1 1 0 1 1 1 1 ]; % [4:5 7:10] % missing for 6
avcue_asc{6} =[4:8];      dataasc{6}=[1 1 1 1 1 0 ]; % [3:7] % missing for 8
avcue_asc{7} =[3:9];      dataasc{7}=[1 1 1 1 1 1 1]; % 4:10
avcue_asc{8} =[4:8];      dataasc{8}=[1 1 1 0 1 1 ]; % [4:6 8:9] % missing for 7
avcue_asc{9} =[3:7];      dataasc{9}=[1 1 1 1 0 1 0 ]; % [4:7 9] % missing for 8 and 10
avcue_asc{10}=[4:8];      dataasc{10}=[1 1 1 0 1 1 ]; % [4:6 8:9] % missing for 7
avcue_asc{11}=[4:10];     dataasc{11}=[1 1 1 1 1 1 1 ]; % 4:10
avcue_asc{12}=[3:6];      dataasc{12}=[1 0 1 1 1 0 ]; % [4 6 7 8] % missing for 5 and 9
avcue_asc{13}=[4:9];      dataasc{13}=[1 1 0 1 1 1 1 ]; % [4:5 7:10] % missing for 6
avcue_asc{14}=[3:7];      dataasc{14}=[1 1 0 1 1 1 0 ]; % [4 5 7:9] % missing for 6 and 10
avcue_asc{15}=[4:8];      dataasc{15}=[0 0 1 1 1 1 1 ]; % [6:10] % missing for 4 and 5
avcue_asc{16}=[4:8];      dataasc{16}=[1 1 0 1 1 0 1 ]; % [4:5 7:8 10] % missing for 6 and 9
avcue_asc{17}=[3:4 6:7];  dataasc{17}=[1 1 0 1 0 1 ]; % [4 5 8 10] % missing for 6 and 9
avcue_asc{18}=[4:6 8:10]; dataasc{18}=[1 1 1 0 1 1 1 ]; % [4:6  8:10] % missing for 7
avcue_asc{19}=[4:9];      dataasc{19}=[1 1 1 1 1 1 ];% [4:9]
avcue_asc{20}=[4:8];      dataasc{20}=[1 0 1 1 1 1 ]; % [4 6:9] % missing for 5
avcue_asc{21}=[1:6];      dataasc{21}=[1 1 1 0 1 1 1 ]; % [4:6 8:10] % missing for 7
avcue_asc{22}=[4:8];      dataasc{22}=[1 0 1 1 1 1 ]; % [4 6:9] % missing for 5
avcue_asc{23}=[4:8];      dataasc{23}=[1 0 1 1 1 0 1 ]; % [4 6:8 10] % missing for 5 and 9

subuse=2:23;
for ii=subuse
  
  datanames=dir([mdir sub{ii} '/*.ds']);
  filenames_eye=dir([bdir sub{ii} '*asc']);
  
  clear fileeye_use
  fileeye_use(find(dataasc{ii}))=filenames_eye(avcue_asc{ii});
  
  datanames(avcuedata{ii}); % simple test if avcuedata matches datanames found
  
  
  
  for ff=1:length(avcuedata{ii})
    
    cfg=[];
    cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
    cfg.trialfun='ft_trialfun_general';
    %     cfg.trialfun='ft_trialfun_motcue';
    % cfg.trialdef.eventtype  = '?';
    cfg.trialdef.eventtype  = 'UPPT002';
    cfg.trialdef.eventvalue = {21 22}; % This means cue value
    cfg.trialdef.prestim = 1.1;
    cfg.trialdef.poststim = 2.1;
    cfgtr=ft_definetrial(cfg);
    
    cfg=[];
    cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
    cfg.demean='yes';
    cfg.bsfilter='yes';
    cfg.bsfreq=[49 51; 99 101; 149 151];
    cfg.hpfilter='yes';
    cfg.hpfiltord=3;
    cfg.hpfreq=0.2;
    cfg.channel={'MEG' };
    cfg.channel={'MRF14' 'MLF14'};
    raw_hpf=ft_preprocessing(cfg);
    
    cfg=[];
    cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
    cfg.channel={'UADC*' };
    eyechan=ft_preprocessing(cfg);
    
    cfg=[];
    cfg.trl=cfgtr.trl;
    raw_cue=ft_redefinetrial(cfg,raw_hpf);
    eye_cue_orig=ft_redefinetrial(cfg,eyechan);
    
    cfg=[];
    cfg.offset=-11; % 10 ms delay for EyeLink data to reach ADC channel on MEG
    eye_adc_shift=ft_redefinetrial(cfg, eye_cue_orig);
    
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
    clear raw_cue eye_cue eye_adc_shift
    
    % Call FT artifact rejection for EOG
    cfg=[];
    cfg.trl=cfgtr.trl;
    cfg.continuous = 'no';
    cfg.artfctdef.zvalue.channel = 'UADC002'; %vertical
    cfg.artfctdef.zvalue.cutoff = 1;
    cfg.artfctdef.zvalue.trlpadding =0;
    cfg.artfctdef.zvalue.fltpadding =0;
    cfg.artfctdef.zvalue.artpadding =0.2;
    cfg.artfctdef.zvalue.rectify       = 'yes';
    if plotflag
      cfg.artfctdef.zvalue.interactive = 'yes';
    end
    [cfg, artifact] = ft_artifact_zvalue(cfg, megeye_cue);
    
    artfct_blinkz=cfg.artfctdef.zvalue;
    
    %     cfg=[];
    %     cfg.artfctdef.reject='nan';
    %     cfg.artfctdef.blink.artifact=artfct_blinkz.artifact;
    %     eyeadc_blinkrm = ft_rejectartifact(cfg, eye_adc_shift);
    %
    % if plotflag
    %     cfg=[];
    %     cfg.viewmode='vertical';
    %     cfg.preproc.demean='yes';
    %     cfg.artfctdef.blink.artifact=artfct_blinkz.artifact;
    %     ft_databrowser(cfg,eyeadc_blinkrm);
    % end
    
    if 0
      % Use values from Eyelink to convert voltage back to pixels.
      % The minimum/maximum voltage range and the maximum/minimum range of the data are defined in EyeLink configuration file FINAL.INI. The physical dimensions of your screen (screenright, screenleft, screenbottom, screentop) are defined in PHYSICAL.INI, or your presentation settings.
      minvoltage = nan;
      maxvoltage = nan;
      minrange = nan;
      maxrange = nan;
      screenright = nan;
      screenleft = nan;
      screentop = nan;
      screenbottom = nan;
      Xgaze=[];
      Ygaze=[];
      for trln=1:size(megeye_cue.trial,2)
        
        voltageH=megeye_cue.trial{trln}(find(strcmp(megeye_cue.label,'UADC002')),:);
        voltageV=megeye_cue.trial{trln}(find(strcmp(megeye_cue.label,'UADC003')),:);
        
        R_h = (voltageH-minvoltage)./(maxvoltage-minvoltage);%voltage range proportion
        S_h = R_h.*(maxrange-minrange)+minrange;%proportion of screen width or height
        
        R_v = (voltageV-minvoltage)./(maxvoltage-minvoltage);
        S_v = R_v.*(maxrange-minrange)+minrange;
        
        S_h = ((voltageH-minvoltage)./(maxvoltage-minvoltage)).*(maxrange-minrange)+minrange;
        S_v = ((voltageV-minvoltage)./(maxvoltage-minvoltage)).*(maxrange-minrange)+minrange;
        
        Xgaze(trln,:) = S_h.*(screenright-screenleft+1)+screenleft;
        Ygaze(trln,:) = S_v.*(screenbottom-screentop+1)+screentop;
        
      end
      % Next, we know that X pixels means Y visual degrees.
      pix_per_deg = nan; % FIXME
      sacc_deg_thresh = 2;
      sacc_pix_thresh = pix_per_deg*sacc_deg_thresh;
    end
    
    % eyelink data doesn't exist for all runs
    hasEL=0;
    if ~isempty( intersect(avcuedata{ii}(ff), avcuedata{ii}(find(dataasc{ii}))))
      hasEL=1;
      
      cfg=[];
      cfg.dataset=[edir fileeye_use(ff).name];
      data_eye=ft_preprocessing(cfg);
      event_eye=jz_read_eyelink_events(cfg.dataset);
      % figure
      % plot([event_eye.sample]./data_eye.hdr.Fs, [event_eye.value], '.')
      % title('Eye position during fixation')
      % xlabel('time (s)');
      % ylabel('X position in pixels');
      %
      
      if 0
        cfg=[];
        cfg.viewmode='vertical';
        cfg.preproc.demean='yes';
        cfg.event=event_eye;
        cfg.channel={'2' '3' '4'};
        ft_databrowser(cfg,data_eye);
        % channels 2, 3, and 4 are: X position, Y position, and pupil AREA
      end
      
      cfg=[];
      cfg.dataset=[edir fileeye_use(ff).name];
      cfg.trialdef.eventtype='msg';
      cfg.trialdef.eventvalue={21 22};
      cfg.trialdef.prestim=1;
      cfg.trialdef.poststim=2;
      cfg.event=event_eye;
      % cfg.trialfun='ft_trialfun_eyelink_appmot';
      cfg=ft_definetrial(cfg);
      data_eye2=ft_preprocessing(cfg);
      
      cfg=[];
      cfg.time=megeye_cue.time;
      data_eye_resamp=ft_resampledata(cfg,data_eye2);
      
      % what to do with event markers?
      % What to reject:
      % 1) blink if end is -0.5s or later
      % 2) saccade
      msgevents=find(strcmp({event_eye.type},'msg'));
      starttrial=msgevents(find([event_eye(msgevents).value]==20));
      zerosample=dsearchn(data_eye2.time{1}',0); % true for all trials, number of samples to add to start sample
      eblinksample=dsearchn(data_eye2.time{1}',-.5); % true for all trials, number of samples to add to start sample
      esaccsample =dsearchn(data_eye2.time{1}',.5); % true for all trials, number of samples to add to start sample
      blinkfound=nan(length(data_eye2.trial),1);
      artfct_blink=nan(length(data_eye2.trial),1);
      artfct_sacc1=nan(length(data_eye2.trial),1);
      artfct_sacc2=nan(length(data_eye2.trial),1);
      numsacc=zeros(length(data_eye2.trial),1);
      sacc_thresh=7; %  <-- FIXME what value ??
      for ee=1:length(starttrial)
        ind=starttrial(ee)+1;
        while event_eye(ind).value~=20 && event_eye(ind).value~=71 && event_eye(ind).value~=72
          switch event_eye(ind).type
            case 'ssacc'
              numsacc(ee)=numsacc(ee)+1;
              %               event_eye(ind).timestamp-event_eye(starttrial(ee)).timestamp;
              samp_esacc=event_eye(ind).sample+event_eye(ind).duration; % when sacc ends
              if [samp_esacc > data_eye2.sampleinfo(ee,1)+esaccsample ]
                artfct_sacc1(ee)=1;
              end
              if [event_eye(ind).value > sacc_thresh]
                artfct_sacc2(ee)=1;
              end
            case 'sblink'
              blinkfound(ee)=1;
              samp_eblink=event_eye(ind).sample+event_eye(ind).duration; % when blink ends
              if samp_eblink > data_eye2.sampleinfo(ee,1)+eblinksample % if blink ends too late
                artfct_blink(ee)=1;
              end
            otherwise
          end
          ind=ind+1;
        end %  while
      end % ee
      
      cfg=[];
      cfg.channel={'2' '3' '4'};
      data_eye_resamp234=ft_selectdata(cfg,data_eye_resamp);
      
      cfg=[];
      cfg.appenddim = 'chan';
      megeye_cue_all=ft_appenddata(cfg,megeye_cue,data_eye_resamp);
      clear megeye_cue
      
    else
      
      megeye_cue_all=megeye_cue;
      clear megeye_cue
    end
    
    
    
    
    cfg=[];
%     cfg.channel={'MZ'};
%     megchanZ=ft_selectdata(cfg,megeye_cue_all);
    cfg.channel={'MRF14' 'MLF14'};
    megchanF=ft_selectdata(cfg,megeye_cue_all);
    cfg.channel={'UADC*'};
    eyechan=ft_selectdata(cfg,megeye_cue_all);
    
    cfg=[];
    cfg.parameter='trial';
    cfg.operation='multiply';
    cfg.scalar=10^15;
%     megchanZs=ft_math(cfg,megchanZ);
    megchanFs=ft_math(cfg,megchanF);
    cfg.scalar=10^2;
    eyechans=ft_math(cfg,eyechan);
    
    if plotflag
      cfg=[];
      cfg.viewmode='vertical';
      cfg.preproc.demean='yes';
      cfg.artfctdef.blink.artifact=artfct_blinkz.artifact;
      if hasEL
        cfg.artfctdef.blink=[];
        artfctdef=ft_databrowser(cfg,ft_appenddata([],megchanFs,eyechans,data_eye_resamp234));
      else
        ft_databrowser(cfg,ft_appenddata([],megchanFs,eyechans));
      end
      %       ft_databrowser(cfg,megchanZ);
      %       ft_databrowser(cfg,eyechan);
    end
    
    % save artifact info for this block
    save([adir sub{ii} '_eye_artfct_runff' num2str(ff) '.mat'],'artfct_blinkz')
    
    clear meg* eye*
    
  end % ff
end % ii

