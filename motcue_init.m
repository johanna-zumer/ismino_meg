% function [sub,mdir,bdir]=motcue_init
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% clear
% clearvars -except *dir
close all

if ispc
  %   mdir='D:\motion_cued\meg_data\';
  %   bdir='D:\motion_cued\behav_data\';
  mdir='I:\motion_cued\meg_data\'; % RDS
  bdir='I:\motion_cued\behav_data\'; % RDS
  edir='I:\motion_cued\eyelink_data\'; % RDS
  adir='I:\motion_cued\artfct\'; 
  sdir='I:\motion_cued\struct_notts_MRI\'; 
  pdir='I:\motion_cued\polhemus_AVmotion\';
else
  environ='bluebear';
  switch environ
    case 'bluebear'
      mdir='/gpfs/bb/zumerj/nbu/motion_cued/meg_data/';
      bdir='/gpfs/bb/zumerj/nbu/motion_cued/behav_data/';
      edir='/gpfs/bb/zumerj/nbu/motion_cued/eyelink_data/'; 
      adir='/gpfs/bb/zumerj/nbu/motion_cued/artfct/';
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

disp('FT path to remove:')
pathd=which('ft_defaults')
if ~isempty(pathd)
  rmpath(fileparts(pathd));
end
disp('SPM path to remove:')
pathd=which('spm')
if ~isempty(pathd)
  rmpath(fileparts(pathd));
end
if ispc
  warning off
  rmpath(genpath('D:\matlab\spm8\external\fieldtrip\'))
  rmpath(genpath('D:\fieldtrip_svn\'))
  warning on
  addpath('D:\fieldtrip_git\')
  addpath('I:\motion_cued\mfiles\')
else
  environ='bluebear';
  switch environ
    case 'bluebear'
      addpath('/gpfs/bb/zumerj/nbu/fieldtrip_git/')
      addpath('/gpfs/bb/zumerj/nbu/motion_cued/mfiles/')
    otherwise
      rmpath(genpath('/mnt/hgfs/D/matlab/spm8/external/fieldtrip/'))
      %   rmpath(genpath('/mnt/hgfs/D/fieldtrip_svn/'))
      %   addpath('/mnt/hgfs/D/fieldtrip_svn/')
      addpath('/mnt/hgfs/D/fieldtrip_git/')
      addpath('/mnt/hgfs/D/motion_cued/mfiles/')
  end
end

which ft_defaults.m
ft_defaults;

% the number here is the MEG run e.g. *_04.ds
avcuedata{2}=[4 5];
avcuedata{3}=[4:10];
avcuedata{4}=[4:10];
avcuedata{5}=[4:10];
avcuedata{6}=[3:8];
avcuedata{7}=[4:10];
avcuedata{8}=[4:9];
avcuedata{9}=[4:10];
avcuedata{10}=[5:10];
avcuedata{11}=[4:10];
avcuedata{12}=[4:9];
avcuedata{13}=[4:10];
avcuedata{14}=[4:10];
avcuedata{15}=[4:10];
avcuedata{16}=[4:10];
avcuedata{17}=[4:6 8:10];
avcuedata{18}=[4:10];
avcuedata{19}=[4:9];
avcuedata{20}=[4:9];
avcuedata{21}=[4:10];
avcuedata{22}=[4:9];
avcuedata{23}=[4:10];

% structural MRI
% for ii=2:23,
%   if ~exist([sdir sub{ii}],'dir')
%     mkdir([sdir sub{ii}]);
%   end
% end

% % Polhemus
% for ii=2:23,
%   if ~exist([pdir sub{ii}],'dir')
%     mkdir([pdir sub{ii}]);
%   end
% end

% mriname{3}=[sdir '10925\10925.mri'];
% mriname{4}=[sdir '09376\09376.mri'];
% mriname{5}=[sdir '10760\10760.mri'];
% mriname{6}=[sdir ''];



