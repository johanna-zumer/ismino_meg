% function [sub,mdir,bdir]=motcue_init
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

clear
% clearvars -except *dir
close all

if ispc
%   mdir='D:\motion_cued\meg_data\';
%   bdir='D:\motion_cued\behav_data\';
  mdir='I:\motion_cued\meg_data\'; % RDS
  bdir='I:\motion_cued\behav_data\'; % RDS
else
  environ='bluebear';
  switch environ
    case 'bluebear'
      mdir='/home/zumerj/motion_cued/meg_data/';
      bdir='/home/zumerj/motion_cued/behav_data/';
    otherwise
      [~,hostname]=system('hostname');
      if ~isempty(strfind(hostname,'les')) | ~isempty(strfind(hostname,'LES')) % either COLLES-151401 or LES-LINUX_FS3
        mdir='/home/zumerj/motion_cued/meg_data/';
        bdir='/home/zumerj/motion_cued/behav_data/';
      else % assume on VM linux of psychl-132432
        mdir='/mnt/hgfs/D/motion_cued/meg_data/';
        bdir='/mnt/hgfs/D/motion_cued/behav_data/';
      end
  end
end

for ii=1:9
  sub{ii}=['m0' num2str(ii)];
end
for ii=10:23
  sub{ii}=['m' num2str(ii)];
end

% volnum{1}='10859021';
% volnum{2}='09376057';
% volnum{3}='10925013';

if ispc
  rmpath(genpath('D:\matlab\spm8\external\fieldtrip\'))
  rmpath(genpath('D:\fieldtrip_svn\'))
  %   addpath('D:\fieldtrip_svn\')
  addpath('D:\fieldtrip_git\')
  addpath('D:\motion_cued\mfiles\')
else
  rmpath(genpath('/mnt/hgfs/D/matlab/spm8/external/fieldtrip/'))
  rmpath(genpath('/mnt/hgfs/D/fieldtrip_svn/'))
  %   addpath('/mnt/hgfs/D/fieldtrip_svn/')
  addpath('/mnt/hgfs/D/fieldtrip_git/')
  addpath('/mnt/hgfs/D/motion_cued/mfiles/')
end
which ft_defaults.m
ft_defaults;



