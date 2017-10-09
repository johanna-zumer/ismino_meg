% script to remove trials based on eye blinks or movements

motcue_init
cd(mdir)
plotflag=0;
doreject=1;
loadEL=1;

% Which *.asc file to use
% comment states which MEG run it goes with
avcue_asc{2} =[6 8];      dataasc{2}=[1 1]; % 4 5
avcue_asc{3} =[4:10];     dataasc{3}=[1 1 1 1 1 1 1];% 4:10
avcue_asc{4} =[5:11];     dataasc{4}=[1 1 1 1 1 1 1 ]; % 4:10
avcue_asc{5} =[4:10];     dataasc{5}=[1 1 1 1 1 1 1 ]; % 4:10
avcue_asc{6} =[4:9];      dataasc{6}=[1 1 1 1 1 1 ]; % [3:8] 
avcue_asc{7} =[4:10];     dataasc{7}=[1 1 1 1 1 1 1]; % 4:10
avcue_asc{8} =[4:9];      dataasc{8}=[1 1 1 1 1 1 ]; % [4:9]
avcue_asc{9} =[5:11];     dataasc{9}=[1 1 1 1 1 1 1 ]; % [410]
avcue_asc{10}=[6 8:9 11:13];dataasc{10}=[1 1 1 1 1 1 ]; % [5:10]
avcue_asc{11}=[4:10];     dataasc{11}=[1 1 1 1 1 1 1 ]; % 4:10
avcue_asc{12}=[5 7:11];   dataasc{12}=[1 1 1 1 1 1 ]; % [4:9]
avcue_asc{13}=[4 6:11];   dataasc{13}=[1 1 1 1 1 1 1 ]; % [4:10]
avcue_asc{14}=[4:10];     dataasc{14}=[1 1 1 1 1 1 1 ]; % [4:10]
avcue_asc{15}=[4:10];     dataasc{15}=[1 1 1 1 1 1 1 ]; % [4:10]
avcue_asc{16}=[4:10];     dataasc{16}=[1 1 1 1 1 1 1 ]; % [4:10] 
avcue_asc{17}=[4:6 8:10]; dataasc{17}=[1 1 1 1 1 1 ]; % [4:6 8:10] 
avcue_asc{18}=[4:7 9:11]; dataasc{18}=[1 1 1 1 1 1 1 ]; % [4:10] 
avcue_asc{19}=[5:10];     dataasc{19}=[1 1 1 1 1 1 ];% [4:9]
avcue_asc{20}=[4 6:10];   dataasc{20}=[1 1 1 1 1 1 ]; % [4:9]
avcue_asc{21}=[4:10];     dataasc{21}=[1 1 1 1 1 1 1 ]; % [4:10]
avcue_asc{22}=[4:9];      dataasc{22}=[1 1 1 1 1 1 ]; % [4:9]
avcue_asc{23}=[4:10];     dataasc{23}=[1 1 1 1 1 1 1 ]; % [4:10]

% from setup_screen.m , we know that
%         case 'meg'
%           setup.res = [1280 1024]; % worked with stimulus presentation and eyelink 13/4/16
%           setup.refresh = 60;
%           setup.mon.dist = 54; % confirmed
%           setup.mon.width = 40; % confirmed

subuse=2:23;

%%
for ii=subuse
  
  datanames=dir([mdir sub{ii} '/*.ds']);
  filenames_eye=dir([edir sub{ii} '*asc']);
  
  clear fileeye_use
  fileeye_use(find(dataasc{ii}))=filenames_eye(avcue_asc{ii});
  
  datanames(avcuedata{ii}); % simple test if avcuedata matches datanames found
  
  
  
  for ff=1:length(avcuedata{ii})
    
    cfg=[];
    cfg.dataset=[mdir sub{ii} '/' datanames(avcuedata{ii}(ff)).name];
%     cfg.trialfun='ft_trialfun_general';
    cfg.trialfun='ft_trialfun_general_motcue';
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
    
    if doreject % run here to get output of how many trials kept for given zvalue threshold
      % first reject if eyeblink during main part of trial
      cfg=[];
      cfg.artfctdef.reject='complete'; % 'nan'
      cfg.artfctdef.crittoilim = [0 2];
      cfg.artfctdef.blink.artifact=artfct_blinkz.artifact;
      eyeadc_blinkrm = ft_rejectartifact(cfg, megeye_cue);
      
      num_nonblinktrials{ii}(ff,:)=[length(megeye_cue.trial) length(eyeadc_blinkrm.trial)];
      
      % do this instead elsewhere, when load data
      %       % then replace blinks remaining with nan
      %       cfg=[];
      %       cfg.artfctdef.reject='nan';
      %       cfg.artfctdef.blink.artifact=artfct_blinkz.artifact;
      %       eyeadc_blinkrm_nan = ft_rejectartifact(cfg, eyeadc_blinkrm);
    end
    
    %
    % if plotflag
    %     cfg=[];
    %     cfg.viewmode='vertical';
    %     cfg.preproc.demean='yes';
    %     cfg.artfctdef.blink.artifact=artfct_blinkz.artifact;
    %     ft_databrowser(cfg,eyeadc_blinkrm);
    % end
    
    % eyelink data doesn't exist for all runs
    hasEL=0;
    if loadEL && ~isempty( intersect(avcuedata{ii}(ff), avcuedata{ii}(find(dataasc{ii}))))
      hasEL=1;
      
      cfg=[];
      cfg.dataset=[edir fileeye_use(ff).name];
      data_eye=ft_preprocessing(cfg);
      event_eye=jz_read_eyelink_events(cfg.dataset);

      
      if 0
        figure
        plot([event_eye.sample]./data_eye.hdr.Fs, [event_eye.value], '.')
        title('Eye position during fixation')
        xlabel('time (s)');
        ylabel('X position in pixels');
        %
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
      
        cfg=[];
        cfg.viewmode='vertical';
        cfg.preproc.demean='yes';
        cfg.event=event_eye;
        cfg.channel={'2' '3' '4'};
        ft_databrowser(cfg,megeye_cue_all);

    % Call FT artifact rejection for EOG
    cfg=[];
    cfg.trl=cfgtr.trl;
    cfg.continuous = 'no';
    cfg.artfctdef.zvalue.channel = '3'; %vertical direct from EL
    cfg.artfctdef.zvalue.cutoff = 1;
    cfg.artfctdef.zvalue.trlpadding =0;
    cfg.artfctdef.zvalue.fltpadding =0;
    cfg.artfctdef.zvalue.artpadding =0.2;
    cfg.artfctdef.zvalue.rectify       = 'yes';
    if plotflag
      cfg.artfctdef.zvalue.interactive = 'yes';
    end
    [cfg, artifact] = ft_artifact_zvalue(cfg, megeye_cue_all);
    
    artfct_blinkz_EL=cfg.artfctdef.zvalue;

        cfg=[];
        cfg.viewmode='vertical';
        cfg.preproc.demean='yes';
        cfg.event=event_eye;
        cfg.channel={'2' '3' '4'};
        cfg.artfctdef.artfct_blinkz_EL.artifact=artfct_blinkz_EL.artifact;
        cfg.artfctdef.artfct_blinkz.artifact=artfct_blinkz.artifact;
        ft_databrowser(cfg,megeye_cue_all);
        
        % for some reason, artfct_blinkz better.  artfct_blinkz_EL picks up
        % extra ones where not really a blink.

    else
      
      megeye_cue_all=megeye_cue;
      clear megeye_cue
    end
    
    
    % Use values from Eyelink to convert voltage back to pixels.
    
    % The physical dimensions of your screen (screenright, screenleft, screenbottom, screentop) are defined in PHYSICAL.INI, or your presentation settings.
    screenright = 1023;
    screenleft = 0;
    screentop = 0;
    screenbottom = 767;  % according to my .asc files
%     screenbottom = 819; % according to EL computer in 2017
    % The minimum/maximum voltage range and the maximum/minimum range of the data are defined in EyeLink configuration file FINAL.INI.
    minvoltage = nan;
    maxvoltage = nan;
    minrange = nan;
    maxrange = nan;
    
    Xgaze=[];
    Ygaze=[];
    
    if isnan(minvoltage) & hasEL % hack because we don't have this real info
      % find a trial without blinks
      switch ii
        case 2
          switch ff
            case 1
              trialnoblink=17;
            case 2
              trialnoblink=14;
          end
        case 3
          switch ff
            case 2
              trialnoblink=12;
            case 3
              trialnoblink=27;
            case 4
              trialnoblink=23;
            case 5
              trialnoblink=23;
            case 6
              trialnoblink=28;
            case 7
              trialnoblink=29;
            otherwise
              disp([ii ff])
              keyboard
          end
        otherwise
          disp([ii ff])
          keyboard
      end
      pfh=polyfit(megeye_cue_all.trial{trialnoblink}(3,:),megeye_cue_all.trial{trialnoblink}(7,:)/1024,1);
      pfv=polyfit(megeye_cue_all.trial{trialnoblink}(4,:),megeye_cue_all.trial{trialnoblink}(8,:)/768,1);
      if max(abs(pfh-pfv))>.002
        error('not ideal fit')
      end
      slope=mean([pfv(1) pfh(1)]);
      icept=mean([pfv(2) pfh(2)]);
      % FIXME: make channel indices general
    elseif isnan(minvoltage)
      slope=0.1412;
      icept=0.4993;
    else
      %         slope= % some function of minvoltage,maxvoltage,minrange,maxrange
      %         icept= % some function of minvoltage,maxvoltage,minrange,maxrange
    end
    for tt=1:size(megeye_cue_all.trial,2)
      megeye_cue_all.trial{tt}(11,:)=1280*(slope*megeye_cue_all.trial{tt}(3,:)+icept);
      megeye_cue_all.trial{tt}(12,:)=1024*(slope*megeye_cue_all.trial{tt}(4,:)+icept);
    end
    megeye_cue_all.label{11}='HGaze';
    megeye_cue_all.label{12}='VGaze';
    
    % Next, we know that X pixels means Y visual degrees.
    % cm/deg = .95 (approximately. it varies with increasing degrees) tand(1)*54cm = 0.943cm
    % pix/cm = 1280/40 = 32;
    pix_per_deg = 30.4; % 32 * 0.95
    sacc_deg_thresh = 2; % FIXME! what value to use?
    sacc_pix_thresh = pix_per_deg*sacc_deg_thresh;
    
    % But fixation seems different every run!?
    
    
    if plotflag
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


num_nbt_allruns=nan(23,2);
for ii=subuse
  num_nbt_allruns(ii,:)=sum(num_nonblinktrials{ii});
end
save([adir 'num_nbt_allruns.mat'],'num_nbt_allruns','num_nonblinktrials');

