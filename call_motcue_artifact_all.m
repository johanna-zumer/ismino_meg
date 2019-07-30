
clear
motcue_init
cd(mdir)
subuse=2:23;

%%
for ii=subuse % not parfor (too much RAM)
% for ii=23:23
  %   clearvars -except ii sub* avcue* *dir *flag
  
  datanames=dir([sub{ii} '/*.ds']);
  
  for ff=1:length(avcuedata{ii}) % parfor on cluster
    visflag=1;
    motcue_load_preproc
    
%     %% Artifact rejection
%     data_out=motcue_artifact_all(megeye_cue,ii,ff,sub,adir,visflag);
  end
  
end