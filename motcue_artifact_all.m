function data_out=motcue_artifact_all(data,ii,ff,sub,adir,visflag)
% function data_out=motcue_artifact_all(data,ii,ff,sub,adir,visflag)

% Blink
% reject completely where a blink occurs during main part of trial
artfct_blinkz=load([adir sub{ii} '_eye_artfct_runff' num2str(ff) '.mat'],'artfct_blinkz');
cfg=[];
cfg.artfctdef.reject='complete'; % 'nan'
cfg.artfctdef.crittoilim = [0 2];
cfg.artfctdef.blink.artifact=artfct_blinkz.artfct_blinkz.artifact;
eyeadc_blinkrm = ft_rejectartifact(cfg, data);
% replace with nan where it occurs elsewhere
cfg=[];
cfg.artfctdef.reject='nan';
cfg.artfctdef.blink.artifact=artfct_blinkz.artfct_blinkz.artifact;
data_out = ft_rejectartifact(cfg, eyeadc_blinkrm);
clear eyeadc_blinkrm

if ~visflag
  artfct_vissummary=load([adir sub{ii} '_rejectvisual_artfct_runff' num2str(ff) '.mat']);
  if ~isempty(artfct_vissummary.artfct_summary.artifact)
    cfg=[];
    cfg.artfctdef.reject='complete'; % 'nan'
    cfg.artfctdef.blink.artifact=artfct_vissummary.artfct_summary.artifact;
    data_out = ft_rejectartifact(cfg, data_out);
  end
  if ~isempty(setdiff(data_out.label,artfct_vissummary.chankeep))
    missingchannel=setdiff(data_out.label,artfct_vissummary.chankeep);
    cfg=[];
    cfg.channel=artfct_vissummary.chankeep;
    data_out=ft_selectdata(cfg,data_out);
    load ctf275_neighb.mat
    cfg=[];
    cfg.neighbours=neighbours;
    cfg.senstype='meg';
    cfg.missingchannel=missingchannel;
    data_out=ft_channelrepair(cfg,data_out);
  end
end

% replace with Nan then interpolate, where there is a 'jump' (it's usually only 1-2 samples long)
artfct_jumpz=load([adir sub{ii} '_jump_artfct_runff' num2str(ff) '.mat'],'artfct_jumpz');
cfg=[];
cfg.artfctdef.reject='nan';
cfg.artfctdef.jump.artifact=artfct_jumpz.artfct_jumpz.artifact;
megeye_jumprm_nan = ft_rejectartifact(cfg, data_out);
% interpolate missing datapoints
cfg = [];
cfg.method = 'pchip'; % Here you can specify any method that is supported by interp1: 'nearest','linear','spline','pchip','cubic','v5cubic'
cfg.prewindow = 0.005; % Window prior to segment to use data points for interpolation
cfg.postwindow = 0.005; % Window after segment to use data points for interpolation
try
  data_out = ft_interpolatenan(cfg, megeye_jumprm_nan); % Clean data
catch ME% sometimes interpolation fails, so then reject whole trial.
  disp('Catch: reject 1 trial that did not interpolate');
  disp(ME.message)
  cfg=[];
  cfg.method='summary';
  cfg.channel={'MEG'};
  megeye_userej=ft_rejectvisual(cfg,megeye_jumprm_nan);
  cfg = [];
  cfg.method = 'pchip'; % Here you can specify any method that is supported by interp1: 'nearest','linear','spline','pchip','cubic','v5cubic'
  cfg.prewindow = 0.001; % Window prior to segment to use data points for interpolation
  cfg.postwindow = 0.001; % Window after segment to use data points for interpolation
  data_out = ft_interpolatenan(cfg, megeye_userej); % Clean data
end

clear megeye_jumprm_nan


%% Manually visually inspect
if visflag
  cfg=[];
  cfg.method='summary';
  cfg.channel={'MEG'};
  megeye_userej=ft_rejectvisual(cfg,data_out);
  %   cfg=[];
  %   cfg.method='channel';
  %   cfg.channel={'MEG'};
  %   megeye_userej=ft_rejectvisual(cfg,data_out);
  %   cfg=[];
  %   cfg.method='trial';
  %   cfg.channel={'MEG'};
  %   megeye_userej=ft_rejectvisual(cfg,data_out);
  %   cfg=[];
  %   ft_databrowser(cfg,data_out);
  
  %   chanrej=setdiff(data_out.label,megeye_userej.label);
  chankeep=megeye_userej.label;
  artfct_summary=megeye_userej.cfg.artfctdef.summary;
  
  save([adir sub{ii} '_rejectvisual_artfct_runff' num2str(ff) '.mat'],'chankeep','artfct_summary');
else
  % see above
end

