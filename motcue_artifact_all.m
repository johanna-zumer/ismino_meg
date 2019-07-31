function data_out=motcue_artifact_all(data,ii,ff,sub,adir,visflag)
% function data_out=motcue_artifact_all(data,ii,ff,sub,adir,visflag)

cfg=[];
cfg.channel={'MEG'}; % get rid of eye ADC channels
data=ft_selectdata(cfg,data);

%% JUMP
% replace with Nan then interpolate, where there is a 'jump' (it's usually only 1-2 samples long)
artfct_jumpz=load([adir sub{ii} '_jump_artfct_runff' num2str(ff) '.mat'],'artfct_jumpz');
cfg=[];
cfg.artfctdef.reject='nan';
cfg.artfctdef.jump.artifact=artfct_jumpz.artfct_jumpz.artifact;
megeye_jumprm_nan = ft_rejectartifact(cfg, data);

% interpolate missing datapoints
% for-loop hack from Sebastian, to avoid errors in ft_interpolatenan
for tt=1:length(megeye_jumprm_nan.trial)
  orig_nans=isnan(megeye_jumprm_nan.trial{tt}(100,:));
  [bricks, bricknumber]= bwlabeln(~orig_nans); %nans is a logical vector
  [bricksizes] = arrayfun(@(x) numel(find(bricks==x)), [1:bricknumber] );
  minibricks = (find(bricksizes <= 0.01*megeye_jumprm_nan.fsample));%% find bricks of data that are too small
  megeye_jumprm_nan.trial{tt}(:,ismember(bricks, minibricks))=nan;
end
if ii==3 && ff==2 % trial 64 has large artifact
  cfg=[];
  cfg.trials=[1:63 65:numel(megeye_jumprm_nan.trial)];
  megeye_jumprm_nan=ft_selectdata(cfg,megeye_jumprm_nan);
end
if ii==18 && ff==4 % trial 64 has large artifact
  cfg=[];
  cfg.trials=[1:106 108:numel(megeye_jumprm_nan.trial)];
  megeye_jumprm_nan=ft_selectdata(cfg,megeye_jumprm_nan);
end
if ii==3 && ff==3 % trial 116 goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{116}(:,end-2:end)=repmat(megeye_jumprm_nan.trial{116}(:,end-3),[1 3]);
end
if ii==3 && ff==4 % trial 116 goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{116}(:,end-5:end)=repmat(megeye_jumprm_nan.trial{116}(:,end-6),[1 6]);
end
if ii==6 && ff==4 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{34}(:,end-8:end)=repmat(megeye_jumprm_nan.trial{34}(:,end-9),[1 9]);
end
if ii==6 && ff==5 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{7}(:,end-6:end)=repmat(megeye_jumprm_nan.trial{7}(:,end-7),[1 7]);
end
if ii==12 && ff==3 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{68}(:,end-16:end)=repmat(megeye_jumprm_nan.trial{68}(:,end-17),[1 17]);
end
if ii==16 && ff==3 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{35}(:,end-3:end)=repmat(megeye_jumprm_nan.trial{35}(:,end-4),[1 4]);
end
if ii==16 && ff==6 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{85}(:,end-12:end)=repmat(megeye_jumprm_nan.trial{85}(:,end-13),[1 13]);
end
if ii==20 && ff==2 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{40}(:,end-21:end)=repmat(megeye_jumprm_nan.trial{40}(:,end-22),[1 22]);
  megeye_jumprm_nan.trial{53}(:,end-9:end)=repmat(megeye_jumprm_nan.trial{53}(:,end-10),[1 10]);
end
if ii==20 && ff==5 % trial X goes to edge; can't solve by setting postwindow to 0
  megeye_jumprm_nan.trial{15}(:,end-17:end)=repmat(megeye_jumprm_nan.trial{15}(:,end-18),[1 18]);
end
cfg = [];
cfg.method = 'pchip'; % Here you can specify any method that is supported by interp1: 'nearest','linear','spline','pchip','cubic','v5cubic'
cfg.prewindow = 0.005; % Window prior to segment to use data points for interpolation
cfg.postwindow = 0.005; % Window after segment to use data points for interpolation
try
  data_out = ft_interpolatenan(cfg, megeye_jumprm_nan); % Clean data
catch ME% sometimes interpolation fails, so then reject whole trial.
  disp('Catch: reject 1 trial that did not interpolate');
  disp(ME.message)
  keyboard
end

clear megeye_jumprm_nan

%% Blink
% reject completely where a blink occurs during main part of trial
artfct_blinkz=load([adir sub{ii} '_eye_artfct_runff' num2str(ff) '.mat'],'artfct_blink_save');
cfg=[];
cfg.artfctdef.reject='complete'; % 'nan'
cfg.artfctdef.crittoilim = [0 2];
cfg.artfctdef.blink.artifact=artfct_blinkz.artfct_blink_save.artifact;
eyeadc_blinkrm = ft_rejectartifact(cfg, data_out);
% replace with nan where it occurs elsewhere
cfg=[];
cfg.artfctdef.reject='nan';
cfg.artfctdef.blink.artifact=artfct_blinkz.artfct_blink_save.artifact;
data_out = ft_rejectartifact(cfg, eyeadc_blinkrm);
clear eyeadc_blinkrm


%% Manually visually inspect
if visflag
  cfg=[];
  cfg.method='summary';
  cfg.keeptrial='yes';
  cfg.keepchannel='yes';
%   cfg.channel={'MEG'};
  megeye_userej=ft_rejectvisual(cfg,data_out);
  %     cfg=[];
  %     cfg.method='channel';
  %   %   cfg.channel={'MEG'};
  %     megeye_userej=ft_rejectvisual(cfg,data_out);
  %     cfg=[];
  %     cfg.method='trial';
  %   %   cfg.channel={'MEG'};
  %     megeye_userej=ft_rejectvisual(cfg,data_out);
  cfg=[];
  cfg.artfctdef.summary.artifact= megeye_userej.cfg.artfctdef.summary.artifact;
  cfgout=ft_databrowser(cfg,data_out);
  
  %   chanrej=setdiff(data_out.label,megeye_userej.label);
  chankeep=megeye_userej.label;
  artfct_summary=cfgout.artfctdef.summary;
  
  save([adir sub{ii} '_rejectvisual_artfct_runff' num2str(ff) '.mat'],'chankeep','artfct_summary');
elseif ~visflag
  
  artfct_vissummary=load([adir sub{ii} '_rejectvisual_artfct_runff' num2str(ff) '.mat']);
  if ~isempty(artfct_vissummary.artfct_summary.artifact)
    cfg=[];
    cfg.artfctdef.reject='complete'; % 'nan'
    cfg.artfctdef.summary.artifact=artfct_vissummary.artfct_summary.artifact;
    data_out = ft_rejectartifact(cfg, data_out);
  end
  adcchan={'UADC001' 'UADC002' 'UADC003'};
  if ~isempty(setdiff(setdiff(data_out.label,artfct_vissummary.chankeep),adcchan))
    missingchannel=setdiff(setdiff(data_out.label,artfct_vissummary.chankeep),adcchan);
    cfg=[];
    cfg.channel=artfct_vissummary.chankeep;
    data_out=ft_selectdata(cfg,data_out);
    load ctf275_neighb.mat
    cfg=[];
    cfg.neighbours=neighbours;
    cfg.senstype={'MEG'};
    cfg.grad=data_out.grad;
    cfg.missingchannel=missingchannel;
    data_out=ft_channelrepair(cfg,data_out);
  end
end

