function [ eye_adc_shift ] = motcue_loadshift_adc( icfg )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

cfg=[];
cfg.dataset=icfg.dataset;
cfg.channel={'UADC*' };
eyechan=ft_preprocessing(cfg);

cfg=[];
cfg.trl=icfg.trl;
eye_cue_orig=ft_redefinetrial(cfg,eyechan);

cfg=[];
cfg.offset=-8; % 10 ms delay for EyeLink data to reach ADC channel on MEG
eye_adc_shift=ft_redefinetrial(cfg, eye_cue_orig);


end

