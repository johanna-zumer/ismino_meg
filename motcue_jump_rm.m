% relevant for ii and ff

switch jrval
  case 'run'
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
  case 'load'
    % do nothing, load at next step
end
artfct_jumpz=load([adir sub{ii} '_jump_artfct_runff' num2str(ff) '.mat'],'artfct_jumpz');

cfg=[];
cfg.artfctdef.reject='nan';
cfg.artfctdef.jump.artifact=artfct_jumpz.artfct_jumpz.artifact;
megeye_jumprm_nan = ft_rejectartifact(cfg, rawd);
clear rawd

% interpolate missing datapoints
% for-loop hack from Sebastian, to avoid errors in ft_interpolatenan
for tt=1:length(megeye_jumprm_nan.trial)
  orig_nans=isnan(megeye_jumprm_nan.trial{tt}(100,:));
  [bricks, bricknumber]= bwlabeln(~orig_nans); %nans is a logical vector
  [bricksizes] = arrayfun(@(x) numel(find(bricks==x)), [1:bricknumber] );
  minibricks = (find(bricksizes <= 0.01*megeye_jumprm_nan.fsample));%% find bricks of data that are too small
  megeye_jumprm_nan.trial{tt}(:,ismember(bricks, minibricks))=nan;
end
% if ii==3 && ff==2 % trial 64 has large artifact
%   cfg=[];
%   cfg.trials=[1:63 65:numel(megeye_jumprm_nan.trial)];
%   megeye_jumprm_nan=ft_selectdata(cfg,megeye_jumprm_nan);
% end
% if ii==18 && ff==4 % trial 64 has large artifact
%   cfg=[];
%   cfg.trials=[1:106 108:numel(megeye_jumprm_nan.trial)];
%   megeye_jumprm_nan=ft_selectdata(cfg,megeye_jumprm_nan);
% end
% if ii==3 && ff==3 % trial 116 goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{116}(:,end-2:end)=repmat(megeye_jumprm_nan.trial{116}(:,end-3),[1 3]);
% end
% if ii==3 && ff==4 % trial 116 goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{116}(:,end-5:end)=repmat(megeye_jumprm_nan.trial{116}(:,end-6),[1 6]);
% end
% if ii==6 && ff==4 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{34}(:,end-8:end)=repmat(megeye_jumprm_nan.trial{34}(:,end-9),[1 9]);
% end
% if ii==6 && ff==5 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{7}(:,end-6:end)=repmat(megeye_jumprm_nan.trial{7}(:,end-7),[1 7]);
% end
% if ii==12 && ff==3 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{68}(:,end-16:end)=repmat(megeye_jumprm_nan.trial{68}(:,end-17),[1 17]);
% end
% if ii==16 && ff==3 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{35}(:,end-3:end)=repmat(megeye_jumprm_nan.trial{35}(:,end-4),[1 4]);
% end
% if ii==16 && ff==6 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{85}(:,end-12:end)=repmat(megeye_jumprm_nan.trial{85}(:,end-13),[1 13]);
% end
% if ii==20 && ff==2 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{40}(:,end-21:end)=repmat(megeye_jumprm_nan.trial{40}(:,end-22),[1 22]);
%   megeye_jumprm_nan.trial{53}(:,end-9:end)=repmat(megeye_jumprm_nan.trial{53}(:,end-10),[1 10]);
% end
% if ii==20 && ff==5 % trial X goes to edge; can't solve by setting postwindow to 0
%   megeye_jumprm_nan.trial{15}(:,end-17:end)=repmat(megeye_jumprm_nan.trial{15}(:,end-18),[1 18]);
% end
cfg = [];
cfg.method = 'pchip'; % Here you can specify any method that is supported by interp1: 'nearest','linear','spline','pchip','cubic','v5cubic'
cfg.prewindow = 0.005; % Window prior to segment to use data points for interpolation
cfg.postwindow = 0.005; % Window after segment to use data points for interpolation
try
  rawd_j = ft_interpolatenan(cfg, megeye_jumprm_nan); % Clean data
catch ME% sometimes interpolation fails, so then reject whole trial.
  disp('Catch: reject 1 trial that did not interpolate');
  disp(ME.message)
  keyboard
end

clear megeye_jumprm_nan
